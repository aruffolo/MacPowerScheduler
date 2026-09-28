import Foundation
import PowerScheduleCore
import PowerScheduleIPC
@testable import PowerScheduleUI
import Testing

private struct UnavailableHelper: HelperCalling {
    func call(_ request: HelperRequest) async throws -> HelperResponse {
        throw ScheduleError(.helperUnavailable, "missing")
    }
}

private actor ChangingReader {
    var snapshot = ScheduleSnapshot()
    var failure: ScheduleError?
    func read() throws -> ScheduleSnapshot {
        if let failure {
            throw failure
        }
        return snapshot
    }

    func update(_ new: ScheduleSnapshot) {
        snapshot = new
        failure = nil
    }

    func fail() {
        failure = ScheduleError(.unreadableSchedule, "Temporary read failure")
    }
}

@MainActor private final class TestPlatform: SchedulingPlatform {
    var signingReady = true
    var registration: HelperRegistration = .enabled
    func openSystemSettings() {}
    var authorized = 0
    var registered = false
    var removed = false
    func register() {
        registered = true
    }

    func unregister() async {
        removed = true
    }

    func authorize() async -> AuthorizationLease {
        authorized += 1
        return AuthorizationLease(externalForm: Data([1]))
    }
}

private actor WorkingHelper: HelperCalling {
    var snapshot = ScheduleSnapshot()
    var automation = false
    func update(_ value: ScheduleSnapshot) {
        snapshot = value
    }

    func call(_ request: HelperRequest) throws -> HelperResponse {
        switch request.action {
        case .status: break
        case .apply:
            guard automation || request.authorization == Data([1]) else {
                throw ScheduleError(.authorizationRequired, "denied")
            }
            snapshot = try #require(request.edit).resolve(against: snapshot)
        case .enableAutomation: automation = true
        case .disableAutomation, .clearAutomation: automation = false
        }
        return HelperResponse(schedule: snapshot, automationEnabled: automation)
    }
}

@MainActor struct ModelTests {
    @Test
    func `applies with authorization and supports grant lifecycle`() async {
        let helper = WorkingHelper()
        let platform = TestPlatform()
        let model = ScheduleModel(helper: helper, platform: platform, read: { await helper.snapshot })
        await model.enableHelper()
        #expect(platform.registered)
        await model.refresh()
        #expect(model.canApply)
        model.startupEnabled = true
        await model.apply()
        #expect(model.error == nil)
        #expect(model.current?.startup?.kind == .wakeorpoweron)
        #expect(platform.authorized == 1)
        await model.setAutomation(true)
        #expect(model.automationEnabled)
        #expect(platform.authorized == 2)
        model.shutdownEnabled = true
        await model.apply()
        #expect(model.error == nil)
        #expect(platform.authorized == 2)
        await model.setAutomation(false)
        #expect(!model.automationEnabled)
        await model.removeHelper()
        #expect(platform.removed)
        #expect(!model.helperReady)
        #expect(model.current?.startup != nil)
    }

    @Test
    func `replacement requires acknowledgment before authorization`() async throws {
        let helper = WorkingHelper()
        await helper.update(
            try ScheduleSnapshot(startup: PowerEvent(kind: .wake, days: "MWF", time: ClockTime("07:30"))),
        )
        let platform = TestPlatform()
        let model = ScheduleModel(helper: helper, platform: platform, read: { await helper.snapshot })
        await model.refresh()
        #expect(model.needsReplacement)
        await model.apply()
        #expect(model.error != nil)
        #expect(platform.authorized == 0)
        await model.apply(replaceExisting: true)
        #expect(model.error == nil)
        #expect(model.current?.startup?.days == "MTWRFSU")
        #expect(model.current?.startup?.kind == .wakeorpoweron)
        #expect(platform.authorized == 1)
    }

    @Test
    func `read failure is not an empty schedule`() async {
        let model = ScheduleModel(
            helper: UnavailableHelper(), platform: TestPlatform(), read: { throw ScheduleError(.unreadableSchedule, "bad format") },
        )
        await model.refresh()
        #expect(model.current == nil)
        #expect(model.error == "bad format")
        #expect(model.canApply == false)
    }

    @Test
    func `current values load and dirty edits survive external change`() async throws {
        let reader = ChangingReader()
        let model = ScheduleModel(helper: UnavailableHelper(), platform: TestPlatform(), read: { try await reader.read() })
        await model.refresh()
        model.startupEnabled = true
        let external = try ScheduleSnapshot(
            shutdown: PowerEvent(kind: .shutdown, time: ClockTime("23:00")),
        )
        await reader.update(external)
        await model.refresh()
        #expect(model.startupEnabled)
        #expect(model.current == external)
        #expect(model.hasConflict)
        await model.refresh(discardDraft: true)
        #expect(model.hasConflict == false)
        #expect(model.notice == nil)
        #expect(model.startupEnabled == false)
        #expect(model.shutdownEnabled)
    }

    @Test(arguments: [false, true])
    func `unsaved time survives failed refresh and recovery`(_ externalChange: Bool) async throws {
        let reader = ChangingReader()
        let initial = try ScheduleSnapshot(startup: PowerEvent(kind: .wakeorpoweron, time: ClockTime("07:30")))
        await reader.update(initial)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let model = ScheduleModel(helper: WorkingHelper(), platform: TestPlatform(), read: { try await reader.read() }, calendar: calendar)
        await model.refresh()
        let draftTime = try #require(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: model.startupTime))
        model.startupTime = draftTime
        try #require(model.isDirty)

        await reader.fail()
        await model.refresh()
        #expect(model.current == nil)
        #expect(model.canApply == false)
        #expect(model.error == "Temporary read failure")
        #expect(model.startupTime == draftTime)
        #expect(model.isDirty)
        #expect(model.editRevision == initial.revision)

        let recovered = externalChange ? ScheduleSnapshot() : initial
        await reader.update(recovered)
        await model.refresh()
        #expect(model.current == recovered)
        #expect(model.error == nil)
        #expect(model.startupEnabled)
        #expect(model.startupTime == draftTime)
        #expect(model.isDirty)
        #expect(model.editRevision == initial.revision)
        #expect(model.hasConflict == externalChange)
        #expect(model.canApply == !externalChange)
    }

    @Test(arguments: [false, true])
    func `recovery reloads clean or explicitly discarded edits`(_ discardDraft: Bool) async throws {
        let reader = ChangingReader()
        let model = ScheduleModel(helper: WorkingHelper(), platform: TestPlatform(), read: { try await reader.read() })
        await model.refresh()
        model.startupEnabled = discardDraft
        await reader.fail()
        await model.refresh(discardDraft: discardDraft)
        let recovered = try ScheduleSnapshot(shutdown: PowerEvent(kind: .shutdown, time: ClockTime("23:00")))
        await reader.update(recovered)
        await model.refresh(discardDraft: discardDraft)
        #expect(model.current == recovered)
        #expect(model.startupEnabled == false)
        #expect(model.shutdownEnabled)
        #expect(model.isDirty == false)
        #expect(model.hasConflict == false)
        #expect(model.editRevision == recovered.revision)
        #expect(model.canApply)
    }
}
