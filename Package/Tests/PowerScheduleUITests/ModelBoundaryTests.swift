import Foundation
import PowerScheduleCore
import PowerScheduleIPC
@testable import PowerScheduleUI
import Testing

@MainActor private final class ModelPlatform: SchedulingPlatform {
    var signingReady = true
    var requiresApproval = false
    var failure: String?
    var registrations = 0
    var removals = 0
    var authorizations = 0
    func register() throws {
        registrations += 1
        if failure == "register" {
            throw ScheduleError(.systemFailure, "register failed")
        }
    }

    func unregister() async throws {
        removals += 1
        if failure == "unregister" {
            throw ScheduleError(.systemFailure, "unregister failed")
        }
    }

    func authorize() async throws -> AuthorizationLease {
        authorizations += 1
        if failure == "authorize" {
            throw ScheduleError(.authorizationRequired, "denied")
        }
        return AuthorizationLease(externalForm: Data([7]))
    }
}

private actor ModelHelper: HelperCalling {
    var response = HelperResponse(schedule: ScheduleSnapshot(), automationEnabled: false)
    var requests: [HelperRequest] = []
    func update(_ response: HelperResponse) {
        self.response = response
    }

    func call(_ request: HelperRequest) -> HelperResponse {
        requests.append(request)
        return response
    }
}

@MainActor struct ModelBoundaryTests {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return value
    }

    @Test
    func `unsigned state does not call helper`() async {
        let helper = ModelHelper()
        let platform = ModelPlatform()
        platform.signingReady = false
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() }, calendar: calendar)
        await model.refresh()
        #expect(!model.signingReady)
        #expect(!model.helperReady)
        #expect(!model.canApply)
        #expect(!model.automationEnabled)
        #expect(model.permissionDescription.contains("Read-only"))
        #expect(await helper.requests.isEmpty)
    }

    @Test(arguments: [false, true])
    func `unavailable helper shows approval or error`(_ pendingApproval: Bool) async {
        let helper = ModelHelper()
        await helper.update(HelperResponse(error: ScheduleError(.helperUnavailable, "offline")))
        let platform = ModelPlatform()
        platform.requiresApproval = pendingApproval
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() }, calendar: calendar)
        await model.refresh()
        #expect(!model.helperReady)
        #expect(!model.automationEnabled)
        #expect(!model.canApply)
        #expect(model.permissionDescription == (pendingApproval ? "Approve Power Scheduling in System Settings → Login Items." : "offline"))
    }

    @Test
    func `registration failure preserves error`() async {
        let platform = ModelPlatform()
        platform.failure = "register"
        let model = ScheduleModel(helper: ModelHelper(), platform: platform, read: { ScheduleSnapshot() }, calendar: calendar)
        await model.enableHelper()
        #expect(model.error == "register failed")
        #expect(!model.busy)
        #expect(platform.registrations == 1)
    }

    @Test
    func `absent verified schedule is not success`() async {
        let helper = ModelHelper()
        let platform = ModelPlatform()
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() }, calendar: calendar)
        await model.refresh()
        await helper.update(HelperResponse())
        model.startupEnabled = true
        await model.apply()
        #expect(model.error?.contains("verified schedule") == true)
        #expect(model.notice == nil)
        #expect(model.current == ScheduleSnapshot())
        #expect(model.isDirty)
        #expect(!model.busy)
    }

    @Test(arguments: ["apply", "automation", "remove"])
    func `authorization failure never mutates`(_ operation: String) async {
        let helper = ModelHelper()
        let platform = ModelPlatform()
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() }, calendar: calendar)
        await model.refresh()
        platform.failure = "authorize"
        if operation == "apply" {
            model.startupEnabled = true; await model.apply()
        }
        if operation == "automation" {
            await model.setAutomation(true)
        }
        if operation == "remove" {
            await model.removeHelper()
        }
        #expect(model.error == "denied")
        #expect(await helper.requests.count == 1)
        #expect(platform.removals == 0)
        #expect(!model.busy)
        #expect(model.current == ScheduleSnapshot())
    }

    @Test
    func `helper error during removal does not unregister`() async {
        let helper = ModelHelper()
        let platform = ModelPlatform()
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() }, calendar: calendar)
        await model.refresh()
        await helper.update(HelperResponse(error: ScheduleError(.authorizationRequired, "denied")))
        await model.removeHelper()
        #expect(platform.removals == 0)
        #expect(model.helperReady)
        #expect(model.error == "denied")
    }

    @Test
    func `failed unregister reflects already cleared grant`() async {
        let helper = ModelHelper()
        await helper.update(HelperResponse(automationEnabled: true))
        let platform = ModelPlatform()
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() }, calendar: calendar)
        await model.refresh()
        #expect(model.automationEnabled)
        platform.failure = "unregister"
        await helper.update(HelperResponse(automationEnabled: false))
        await model.removeHelper()
        #expect(!model.automationEnabled)
        #expect(model.helperReady)
        #expect(model.error == "unregister failed")
        #expect(!model.busy)
    }

    @Test
    func `losing signing readiness clears grant display`() async {
        let helper = ModelHelper()
        await helper.update(HelperResponse(automationEnabled: true))
        let platform = ModelPlatform()
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() }, calendar: calendar)
        await model.refresh()
        #expect(model.automationEnabled)
        platform.signingReady = false
        await model.refresh()
        #expect(!model.automationEnabled)
        #expect(!model.helperReady)
    }

    @Test
    func `injected calendar controls displayed times and edits`() async throws {
        let snapshot = try ScheduleSnapshot(
            startup: PowerEvent(kind: .wakeorpoweron, time: ClockTime("07:30")),
            shutdown: PowerEvent(kind: .shutdown, time: ClockTime("23:00")),
        )
        let helper = ModelHelper()
        let model = ScheduleModel(helper: helper, platform: ModelPlatform(), read: { snapshot }, calendar: calendar)
        await model.refresh()
        #expect(calendar.component(.hour, from: model.startupTime) == 7)
        #expect(calendar.component(.minute, from: model.startupTime) == 30)
        #expect(!model.isDirty)
        model.shutdownTime = try #require(calendar.date(bySettingHour: 22, minute: 15, second: 0, of: model.shutdownTime))
        #expect(model.isDirty)
        await model.apply()
        let request = try #require(await helper.requests.last)
        #expect(try request.edit?.shutdown == .set(ClockTime("22:15")))
        #expect(request.authorization == Data([7]))
    }

    @Test
    func `busy actions do not overlap`() async {
        let (entered, entering) = AsyncStream<Void>.makeStream()
        let (released, release) = AsyncStream<Void>.makeStream()
        let helper = ModelHelper()
        let platform = ModelPlatform()
        let model = ScheduleModel(helper: helper, platform: platform, read: {
            entering.yield(())
            for await _ in released {
                break
            }
            return ScheduleSnapshot()
        }, calendar: calendar)
        let refresh = Task { await model.refresh() }
        for await _ in entered {
            break
        }
        #expect(model.busy)
        await model.refresh()
        await model.enableHelper()
        await model.apply()
        await model.setAutomation(true)
        await model.removeHelper()
        #expect(platform.registrations == 0)
        #expect(platform.authorizations == 0)
        #expect(await helper.requests.isEmpty)
        release.yield(())
        release.finish()
        entering.finish()
        await refresh.value
        #expect(!model.busy)
        #expect(model.canApply)
    }

    @Test
    func `authorization lease retains only for its lifetime`() {
        final class Token {}
        weak var weakToken: Token?
        var lease: AuthorizationLease?
        do {
            let token = Token()
            weakToken = token
            lease = AuthorizationLease(externalForm: Data([7]), retaining: token)
        }
        #expect(weakToken != nil)
        #expect(lease?.externalForm == Data([7]))
        lease = nil
        #expect(weakToken == nil)
    }
}
