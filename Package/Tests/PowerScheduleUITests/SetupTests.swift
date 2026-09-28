import Foundation
import PowerScheduleCore
import PowerScheduleIPC
@testable import PowerScheduleUI
import Testing

@MainActor private final class SetupPlatform: SchedulingPlatform {
    var signingReady = true
    var registration: HelperRegistration = .notRegistered
    var registrations = 0
    var settingsOpened = 0
    func register() {
        registrations += 1; registration = .requiresApproval
    }

    func unregister() {
        registration = .notRegistered
    }

    func openSystemSettings() {
        settingsOpened += 1
    }

    func authorize() throws -> AuthorizationLease {
        throw ScheduleError(.authorizationRequired, "No authorization in setup tests")
    }
}

private actor SetupHelper: HelperCalling {
    var available = false
    var requests = 0
    func setAvailable() {
        available = true
    }

    func call(_ request: HelperRequest) throws -> HelperResponse {
        #expect(request.action == .status)
        requests += 1
        guard available else { throw ScheduleError(.helperUnavailable, "Connection unavailable") }
        return HelperResponse(automationEnabled: false)
    }
}

@MainActor struct SetupTests {
    @Test(arguments: [HelperRegistration.notRegistered, .requiresApproval, .enabled, .notFound])
    func `setup action follows registration status without granting automation`(_ registration: HelperRegistration) async {
        let platform = SetupPlatform()
        platform.registration = registration
        let helper = SetupHelper()
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() })
        #expect(model.setup == .checking)
        #expect(model.setup.actionTitle == nil)
        #expect(model.permissionDescription == "Checking scheduling access…")
        await model.performSetupAction()
        #expect(await helper.requests == 0)
        await model.refresh()
        #expect(model.helperReady == false)
        #expect(model.automationEnabled == false)
        #expect(platform.registrations == 0)
        switch registration {
        case .notRegistered:
            #expect(model.setup == .registrationRequired)
            #expect(model.setup.actionTitle == "Enable Power Scheduling")
            #expect(model.permissionDescription.contains("Enable power scheduling"))
        case .requiresApproval:
            #expect(model.setup == .approvalRequired)
            #expect(model.setup.actionTitle == "Open System Settings")
            #expect(model.permissionDescription.contains("System Settings"))
        case .enabled:
            #expect(model.setup == .unavailable("Connection unavailable"))
            #expect(model.permissionDescription == "Connection unavailable")
            #expect(model.setup.actionTitle == "Retry")
        case .notFound:
            #expect(model.permissionDescription.contains("could not be found"))
            #expect(model.setup.actionTitle == "Retry")
        }
        model.startupEnabled = true
        await model.performSetupAction()
        #expect(model.startupEnabled)
        #expect(model.isDirty)
        #expect(platform.registrations == (registration == .notRegistered ? 1 : 0))
        #expect(platform.settingsOpened == (registration == .requiresApproval ? 1 : 0))
        #expect(model.automationEnabled == false)
    }

    @Test
    func `approval to ready to read only never leaves a stale setup action`() async {
        let platform = SetupPlatform()
        let helper = SetupHelper()
        let model = ScheduleModel(helper: helper, platform: platform, read: { ScheduleSnapshot() })
        await model.refresh()
        await model.performSetupAction()
        #expect(model.setup == .approvalRequired)
        await model.performSetupAction()
        #expect(platform.settingsOpened == 1)
        await helper.setAvailable()
        await model.refresh()
        #expect(model.setup == .ready)
        #expect(model.setup.actionTitle == nil)
        #expect(model.permissionDescription == "Power scheduling is enabled.")
        await model.performSetupAction()
        #expect(platform.registrations == 1)
        platform.signingReady = false
        await model.refresh()
        #expect(model.setup == .readOnly)
        #expect(model.setup.actionTitle == nil)
        #expect(model.permissionDescription.contains("Read-only"))
        let requests = await helper.requests
        await model.performSetupAction()
        #expect(await helper.requests == requests)
        #expect(model.canApply == false)
    }
}
