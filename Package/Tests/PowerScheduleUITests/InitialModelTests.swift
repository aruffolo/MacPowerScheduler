import Foundation
import PowerScheduleCore
import PowerScheduleIPC
@testable import PowerScheduleUI
import Testing

private struct NoGrantHelper: HelperCalling {
    func call(_ request: HelperRequest) -> HelperResponse {
        HelperResponse()
    }
}

@MainActor private struct NoGrantPlatform: SchedulingPlatform {
    var signingReady: Bool {
        true
    }

    var registration: HelperRegistration {
        .enabled
    }

    func openSystemSettings() {}

    func register() {}
    func unregister() async {}
    func authorize() async -> AuthorizationLease {
        AuthorizationLease(externalForm: Data([1]))
    }
}

@MainActor struct InitialModelTests {
    @Test
    func `initial state cannot apply and does not invent conflict`() {
        let model = ScheduleModel(helper: NoGrantHelper(), platform: NoGrantPlatform(), read: { ScheduleSnapshot() })
        #expect(model.current == nil)
        #expect(model.editRevision == nil)
        #expect(!model.canApply)
        #expect(!model.hasConflict)
        #expect(!model.needsReplacement)
        #expect(!model.isDirty)
    }

    @Test
    func `absent automation field never means permission granted`() async {
        let model = ScheduleModel(helper: NoGrantHelper(), platform: NoGrantPlatform(), read: { ScheduleSnapshot() })
        await model.refresh()
        #expect(!model.automationEnabled)
        await model.setAutomation(true)
        #expect(!model.automationEnabled)
    }
}
