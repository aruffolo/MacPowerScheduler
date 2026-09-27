import Foundation
import Observation
import PowerScheduleCore
import PowerScheduleIPC
import PowerScheduleSystem

@Observable @MainActor
public final class ScheduleModel {
    public var startupEnabled = false
    public var shutdownEnabled = false
    public var startupTime: Date
    public var shutdownTime: Date
    public private(set) var current: ScheduleSnapshot?
    public private(set) var error: String?
    public private(set) var notice: String?
    public private(set) var busy = false
    public private(set) var automationEnabled = false
    public private(set) var helperReady = false
    public private(set) var signingReady = false
    public private(set) var permissionDescription = "Power scheduling needs setup."
    private var draftBaseline: ScheduleSnapshot?
    private let platform: any SchedulingPlatform
    private let helper: any HelperCalling
    private let read: @Sendable () async throws -> ScheduleSnapshot
    private let calendar: Calendar

    public init(
        helper: any HelperCalling = HelperClient(),
        platform: any SchedulingPlatform = MacSchedulingPlatform(),
        read: @escaping @Sendable () async throws -> ScheduleSnapshot = {
            try await SystemSchedule().readAsync()
        },
        calendar: Calendar = .autoupdatingCurrent,
    ) {
        self.platform = platform
        self.helper = helper
        self.read = read
        self.calendar = calendar
        startupTime = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: 7, minute: 30)) ?? .now
        shutdownTime = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: 23)) ?? .now
    }

    public var editRevision: String? {
        draftBaseline?.revision
    }

    public var needsReplacement: Bool {
        current.map { !$0.isDailyEditable } ?? false
    }

    public var hasConflict: Bool {
        current.map { editRevision != nil && $0.revision != editRevision } ?? false
    }

    public var canApply: Bool {
        current != nil && editRevision != nil && helperReady && !busy && !hasConflict
    }

    public var isDirty: Bool {
        guard let draftBaseline else { return false }
        return startupEnabled != (draftBaseline.startup != nil)
            || shutdownEnabled != (draftBaseline.shutdown != nil)
            || (startupEnabled && clock(startupTime) != draftBaseline.startup?.time)
            || (shutdownEnabled && clock(shutdownTime) != draftBaseline.shutdown?.time)
    }

    private func clock(_ date: Date) -> ClockTime? {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return try? ClockTime(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    private func loadDraft(_ snapshot: ScheduleSnapshot) {
        startupEnabled = snapshot.startup != nil
        shutdownEnabled = snapshot.shutdown != nil
        if let time = snapshot.startup?.time {
            startupTime = date(time)
        }
        if let time = snapshot.shutdown?.time {
            shutdownTime = date(time)
        }
        draftBaseline = snapshot
    }

    private func date(_ time: ClockTime) -> Date {
        calendar.date(
            from: DateComponents(year: 2001, month: 1, day: 1, hour: time.hour, minute: time.minute),
        )
            ?? .now
    }

    public func refresh(discardDraft: Bool = false) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        let preserve = isDirty && !discardDraft
        do {
            let snapshot = try await read()
            if !preserve {
                loadDraft(snapshot)
            }
            current = snapshot
            error = nil
            if hasConflict {
                notice = "The system schedule changed. Reload the editor before applying."
            } else {
                notice = nil
            }
        } catch {
            self.error = error.localizedDescription
            current = nil
        }
        await refreshPermission()
    }

    private func refreshPermission() async {
        signingReady = platform.signingReady
        guard signingReady else {
            helperReady = false
            automationEnabled = false
            permissionDescription = "Read-only development build. Sign the app to enable scheduling."
            return
        }
        do {
            let response = try await helper.call(HelperRequest(action: .status)).checked()
            helperReady = true
            automationEnabled = response.automationEnabled ?? false
            permissionDescription = "Power scheduling is enabled."
        } catch {
            helperReady = false
            automationEnabled = false
            let needsApproval = platform.requiresApproval
            permissionDescription =
                needsApproval
                    ? "Approve Power Scheduling in System Settings → Login Items." : error.localizedDescription
        }
    }

    public func enableHelper() async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try platform.register()
        } catch { self.error = error.localizedDescription }
        await refreshPermission()
    }

    public func apply(replaceExisting: Bool = false) async {
        guard canApply, let editRevision else { return }
        busy = true
        error = nil
        notice = nil
        defer { busy = false }
        do {
            guard let startup = clock(startupTime), let shutdown = clock(shutdownTime), let current else {
                throw ScheduleError(.invalidInput, "Choose valid times and refresh the schedule.")
            }
            let edit = ScheduleEdit(
                startup: startupEnabled ? .set(startup) : .disable,
                shutdown: shutdownEnabled ? .set(shutdown) : .disable, replaceExisting: replaceExisting,
                expectedRevision: editRevision,
            )
            _ = try edit.resolve(against: current)
            let authorization = automationEnabled ? nil : try await platform.authorize()
            defer { withExtendedLifetime(authorization) {} }
            let response = try await helper.call(
                HelperRequest(action: .apply, edit: edit, authorization: authorization?.externalForm),
            ).checked()
            guard let verified = response.schedule else {
                throw ScheduleError(
                    .uncertainResult,
                    "The helper did not return a verified schedule. Refresh before retrying.",
                )
            }
            self.current = verified
            loadDraft(verified)
            notice = "Schedule applied and verified."
        } catch { self.error = error.localizedDescription }
    }

    public func setAutomation(_ enabled: Bool) async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            let authorization = try await platform.authorize()
            defer { withExtendedLifetime(authorization) {} }
            let response = try await helper.call(
                HelperRequest(
                    action: enabled ? .enableAutomation : .disableAutomation,
                    authorization: authorization.externalForm,
                ),
            ).checked()
            automationEnabled = response.automationEnabled ?? false
        } catch { self.error = error.localizedDescription }
    }

    public func removeHelper() async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            let authorization = try await platform.authorize()
            defer { withExtendedLifetime(authorization) {} }
            _ = try await helper.call(
                HelperRequest(action: .clearAutomation, authorization: authorization.externalForm),
            ).checked()
            automationEnabled = false
            try await platform.unregister()
            helperReady = false
            permissionDescription = "Power scheduling helper removed."
            notice =
                "Existing system schedules are unchanged. Disable both times and Apply before removal if you want them cleared."
        } catch { self.error = error.localizedDescription }
    }
}
