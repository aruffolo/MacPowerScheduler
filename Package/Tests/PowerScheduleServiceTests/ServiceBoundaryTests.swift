import Foundation
import PowerScheduleCore
import PowerScheduleIPC
@testable import PowerScheduleService
import PowerScheduleSystem
import Testing

private struct ScenarioBackend: ScheduleBackend {
    var readValue: @Sendable () throws -> ScheduleSnapshot = { ScheduleSnapshot() }
    var writeValue: @Sendable (ScheduleSnapshot) throws -> Void = { _ in }
    func read() throws -> ScheduleSnapshot {
        try readValue()
    }

    func write(_ value: ScheduleSnapshot) throws {
        try writeValue(value)
    }
}

private struct BrokenGrants: GrantStoring {
    let operation: String
    func contains(_ account: String) throws -> Bool {
        if operation == "contains" {
            throw ScheduleError(.systemFailure, "grant read failed")
        }
        return false
    }

    func set(_ account: String, enabled: Bool) throws {
        throw ScheduleError(.systemFailure, "grant save failed")
    }

    func clear() throws {
        throw ScheduleError(.systemFailure, "grant clear failed")
    }
}

struct ServiceBoundaryTests {
    @Test
    func `status does not authorize or write`() throws {
        let snapshot = try ScheduleSnapshot(shutdown: PowerEvent(kind: .shutdown, time: ClockTime("23:00")))
        let backend = ScenarioBackend(readValue: { snapshot }, writeValue: { _ in Issue.record("Status wrote") })
        let grants = MemoryGrants()
        grants.set("A", enabled: true)
        let service = ScheduleService(backend: backend, grants: grants, authorize: { _ in Issue.record("Status authorized") })
        let response = service.handle(HelperRequest(action: .status), account: "A")
        #expect(response.schedule == snapshot)
        #expect(response.automationEnabled == true)
        #expect(response.revision == snapshot.revision)
    }

    @Test
    func `protocol mismatch stops before dependencies`() throws {
        let request = try JSONDecoder().decode(HelperRequest.self, from: Data(#"{"version":2,"action":"status"}"#.utf8))
        let backend = ScenarioBackend(readValue: { Issue.record("Read after mismatch"); return ScheduleSnapshot() })
        let service = ScheduleService(backend: backend, grants: BrokenGrants(operation: "contains"))
        #expect(service.handle(request, account: "A").error?.code == .helperUnavailable)
    }

    @Test
    func `missing edit rejected after authorization`() {
        let backend = ScenarioBackend(readValue: { Issue.record("Read without edit"); return ScheduleSnapshot() })
        let service = ScheduleService(backend: backend, grants: MemoryGrants(), authorize: { token in #expect(token == Data([7])) })
        let response = service.handle(HelperRequest(action: .apply, authorization: Data([7])), account: "A")
        #expect(response.error?.code == .invalidInput)
    }

    @Test
    func `clear revokes all accounts`() {
        let grants = MemoryGrants()
        grants.set("A", enabled: true)
        grants.set("B", enabled: true)
        let service = ScheduleService(backend: MemoryBackend(), grants: grants, authorize: { token in #expect(token == Data([7])) })
        let response = service.handle(HelperRequest(action: .clearAutomation, authorization: Data([7])), account: "A")
        #expect(response.error == nil)
        #expect(response.automationEnabled == false)
        #expect(!grants.contains("A"))
        #expect(!grants.contains("B"))
    }

    @Test(arguments: [HelperRequest.Action.enableAutomation, .disableAutomation, .clearAutomation])
    func `existing grant does not authorize grant management`(_ action: HelperRequest.Action) {
        let grants = MemoryGrants()
        grants.set("A", enabled: true)
        let service = ScheduleService(backend: MemoryBackend(), grants: grants) { _ in throw ScheduleError(.authorizationRequired, "denied") }
        #expect(service.handle(HelperRequest(action: action), account: "A").error?.code == .authorizationRequired)
        #expect(grants.contains("A"))
    }

    @Test(arguments: [("contains", HelperRequest.Action.status), ("set", .enableAutomation), ("clear", .clearAutomation)])
    func `grant failures remain failures`(_ operation: String, _ action: HelperRequest.Action) {
        let service = ScheduleService(backend: MemoryBackend(), grants: BrokenGrants(operation: operation), authorize: { _ in })
        #expect(service.handle(HelperRequest(action: action), account: "A").error?.code == .systemFailure)
    }

    @Test
    func `initial read failure never writes`() throws {
        let backend = ScenarioBackend(
            readValue: { throw ScheduleError(.unreadableSchedule, "bad read") },
            writeValue: { _ in Issue.record("Wrote after failed initial read") },
        )
        let response = try apply(to: backend)
        #expect(response.error == ScheduleError(.unreadableSchedule, "bad read"))
    }

    @Test
    func `write failure is uncertain`() throws {
        let backend = ScenarioBackend(writeValue: { _ in throw ScheduleError(.systemFailure, "write failed") })
        #expect(try apply(to: backend).error?.code == .uncertainResult)
    }

    @Test
    func `mismatched readback never claims success`() throws {
        #expect(try apply(to: ScenarioBackend()).error?.code == .uncertainResult)
    }

    @Test(arguments: [Data("bad".utf8), Data(repeating: 0, count: 65536)])
    func `malformed requests never resolve account`(_ bytes: Data) throws {
        let handler = HelperRequestHandler(
            service: ScheduleService(backend: MemoryBackend(), grants: MemoryGrants()),
            resolveAccount: { Issue.record("Resolved invalid caller payload"); return "A" },
        )
        let response = try JSONDecoder().decode(HelperResponse.self, from: handler.handle(bytes))
        #expect(response.error?.code == .invalidInput)
    }

    @Test
    func `account resolution failure cannot become success`() throws {
        let handler = HelperRequestHandler(
            service: ScheduleService(backend: MemoryBackend(), grants: MemoryGrants()),
            resolveAccount: { throw ScheduleError(.authorizationRequired, "no account") },
        )
        let bytes = try JSONEncoder().encode(HelperRequest(action: .status))
        let response = try JSONDecoder().decode(HelperResponse.self, from: handler.handle(bytes))
        #expect(response.error == ScheduleError(.authorizationRequired, "no account"))
    }

    @Test
    func `payload cannot choose authorized account`() throws {
        let grants = MemoryGrants()
        grants.set("attacker-supplied", enabled: true)
        let handler = HelperRequestHandler(service: ScheduleService(backend: MemoryBackend(), grants: grants), resolveAccount: { "actual-peer" })
        let bytes = Data(#"{"version":1,"action":"status","account":"attacker-supplied","uid":0}"#.utf8)
        let response = try JSONDecoder().decode(HelperResponse.self, from: handler.handle(bytes))
        #expect(response.error == nil)
        #expect(response.automationEnabled == false)
    }

    private func apply(to backend: some ScheduleBackend) throws -> HelperResponse {
        let service = ScheduleService(backend: backend, grants: MemoryGrants(), authorize: { _ in })
        let edit = try ScheduleEdit(startup: .set(ClockTime("07:00")), expectedRevision: ScheduleSnapshot().revision)
        return service.handle(HelperRequest(action: .apply, edit: edit), account: "A")
    }
}
