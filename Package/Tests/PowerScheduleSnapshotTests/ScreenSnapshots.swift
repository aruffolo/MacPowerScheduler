import AppKit
import PowerScheduleCore
import PowerScheduleIPC
@testable import PowerScheduleUI
import SnapshotTesting
import SwiftUI
import Testing

@Suite(.serialized) @MainActor
struct ScreenSnapshots {
    enum Scene: String, CaseIterable, Sendable {
        case empty, startupOnly, shutdownOnly, daily, automation, readOnly, approval, readError, replacement, conflict
    }

    enum Appearance: String, CaseIterable, Sendable {
        case light, dark
    }

    @Test(arguments: Scene.allCases, Appearance.allCases)
    func screen(scene: Scene, appearance: Appearance) async throws {
        _ = NSApplication.shared
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let model = try await makeModel(scene: scene, calendar: calendar)
        let view = ScheduleContentView(model: model)
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
            .environment(\.calendar, calendar)
            .environment(\.timeZone, calendar.timeZone)
            .environment(\.colorScheme, appearance == .light ? .light : .dark)
            .transaction { $0.animation = nil }
            .frame(width: 560, height: 800)
            .background(Color(nsColor: .windowBackgroundColor))
        let host = NSHostingView(rootView: view)
        host.appearance = NSAppearance(named: appearance == .light ? .aqua : .darkAqua)
        host.frame = NSRect(x: 0, y: 0, width: 560, height: 800)
        host.layoutSubtreeIfNeeded()
        assertSnapshot(
            of: host as NSView, as: .image,
            named: "\(scene.rawValue)-\(appearance.rawValue)",
            record: ProcessInfo.processInfo.environment["MPS_RECORD_SNAPSHOTS"] == "1" ? .all : .never,
            testName: "screen",
        )
    }

    private func makeModel(scene: Scene, calendar: Calendar) async throws -> ScheduleModel {
        let startup = try PowerEvent(kind: .wakeorpoweron, time: ClockTime("07:30"))
        let shutdown = try PowerEvent(kind: .shutdown, time: ClockTime("23:00"))
        let snapshot: ScheduleSnapshot = switch scene {
        case .empty, .readOnly, .approval, .readError, .conflict: ScheduleSnapshot()
        case .startupOnly: ScheduleSnapshot(startup: startup)
        case .shutdownOnly: ScheduleSnapshot(shutdown: shutdown)
        case .daily, .automation: ScheduleSnapshot(startup: startup, shutdown: shutdown)
        case .replacement:
            try ScheduleSnapshot(startup: PowerEvent(kind: .wake, days: "MTWRF", time: ClockTime("06:45")))
        }
        let reader = SnapshotReader(snapshot: snapshot)
        let model = ScheduleModel(
            helper: SnapshotHelper(available: scene != .approval, automation: scene == .automation),
            platform: SnapshotPlatform(signingReady: scene != .readOnly, requiresApproval: scene == .approval),
            read: {
                if scene == .readError {
                    throw ScheduleError(.unreadableSchedule, "The system schedule could not be read. Refresh to try again.")
                }
                return await reader.snapshot
            },
            calendar: calendar,
        )
        await model.refresh()
        if scene == .conflict {
            model.startupEnabled = true
            await reader.update(ScheduleSnapshot(shutdown: shutdown))
            await model.refresh()
            #expect(model.hasConflict)
        }
        return model
    }
}

private actor SnapshotReader {
    var snapshot: ScheduleSnapshot
    init(snapshot: ScheduleSnapshot) {
        self.snapshot = snapshot
    }

    func update(_ snapshot: ScheduleSnapshot) {
        self.snapshot = snapshot
    }
}

private struct SnapshotHelper: HelperCalling {
    let available: Bool
    let automation: Bool
    func call(_ request: HelperRequest) throws -> HelperResponse {
        try #require(request.action == .status, "Snapshots must never request helper mutations.")
        guard available else { throw ScheduleError(.helperUnavailable, "Helper approval required.") }
        return HelperResponse(automationEnabled: automation)
    }
}

@MainActor private struct SnapshotPlatform: SchedulingPlatform {
    let signingReady: Bool
    let requiresApproval: Bool
    func register() throws {
        throw unexpectedMutation()
    }

    func unregister() async throws {
        throw unexpectedMutation()
    }

    func authorize() async throws -> AuthorizationLease {
        throw unexpectedMutation()
    }

    private func unexpectedMutation() -> ScheduleError {
        Issue.record("Snapshots must never register, remove, or authorize a helper.")
        return ScheduleError(.authorizationRequired, "Snapshot fixtures are read-only.")
    }
}
