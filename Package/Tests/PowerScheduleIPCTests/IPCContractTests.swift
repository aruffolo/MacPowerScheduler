import Foundation
import PowerScheduleCore
@testable import PowerScheduleIPC
import Testing

private struct StubTransport: HelperTransport {
    let send: @Sendable (Data) throws -> Data
    func exchange(_ payload: Data) throws -> Data {
        try send(payload)
    }
}

struct IPCContractTests {
    @Test
    func `request and reply round trip`() async throws {
        let snapshot = ScheduleSnapshot()
        let client = HelperClient(transport: StubTransport { data in
            let request = try JSONDecoder().decode(HelperRequest.self, from: data)
            #expect(request.version == 1)
            #expect(request.action == .apply)
            #expect(request.authorization == Data([1, 2]))
            #expect(request.edit?.expectedRevision == snapshot.revision)
            return try JSONEncoder().encode(HelperResponse(schedule: snapshot, automationEnabled: true))
        })
        let response = try await client.call(HelperRequest(
            action: .apply,
            edit: ScheduleEdit(startup: .disable, expectedRevision: snapshot.revision),
            authorization: Data([1, 2]),
        ))
        #expect(response.schedule == snapshot)
        #expect(response.revision == snapshot.revision)
        #expect(response.automationEnabled == true)
    }

    @Test(arguments: [HelperRequest.Action.status, .apply, .enableAutomation, .disableAutomation, .clearAutomation])
    func `unavailable is uncertain for mutations`(_ action: HelperRequest.Action) async {
        let client = HelperClient(transport: StubTransport { _ in throw HelperTransportError.unavailable })
        do { _ = try await client.call(HelperRequest(action: action)); Issue.record("Expected failure") }
        catch let error as ScheduleError { #expect(error.code == (action == .status ? .helperUnavailable : .uncertainResult)) }
        catch { Issue.record(error) }
    }

    @Test(arguments: [HelperTransportError.interrupted, .timedOut])
    func `interrupted and timed out are uncertain`(_ failure: HelperTransportError) async {
        let client = HelperClient(transport: StubTransport { _ in throw failure })
        do { _ = try await client.call(HelperRequest(action: .apply)); Issue.record("Expected failure") }
        catch let error as ScheduleError { #expect(error.code == .uncertainResult) }
        catch { Issue.record(error) }
    }

    @Test(arguments: [HelperRequest.Action.status, .apply], [Data("invalid".utf8), Data(repeating: 0, count: 65536)])
    func `unreadable responses`(_ action: HelperRequest.Action, _ data: Data) async {
        let client = HelperClient(transport: StubTransport { _ in data })
        do { _ = try await client.call(HelperRequest(action: action)); Issue.record("Expected failure") }
        catch {
            if action == .apply {
                #expect((error as? ScheduleError)?.code == .uncertainResult)
            } else if data.count == 65536 {
                #expect((error as? ScheduleError)?.code == .systemFailure)
            } else {
                #expect(error is DecodingError)
            }
        }
    }

    @Test
    func `typed errors and protocol mismatch`() async throws {
        let denied = ScheduleError(.authorizationRequired, "denied")
        let client = HelperClient(transport: StubTransport { _ in try JSONEncoder().encode(HelperResponse(error: denied)) })
        await #expect(throws: denied) { try await client.call(HelperRequest(action: .apply)) }
        let mismatch = HelperClient(transport: StubTransport { _ in Data(#"{"schemaVersion":2}"#.utf8) })
        await #expect(throws: ScheduleError(.helperUnavailable, "The app and helper versions do not match. Re-enable the helper.")) {
            try await mismatch.call(HelperRequest(action: .status))
        }
    }

    @Test
    func `oversized requests never reach transport`() async {
        let client = HelperClient(transport: StubTransport { _ in Issue.record("Oversized request sent"); return Data() })
        await #expect(throws: ScheduleError(.invalidInput, "Request exceeds its size limit.")) {
            try await client.call(HelperRequest(action: .apply, authorization: Data(repeating: 0, count: 65536)))
        }
    }

    @Test
    func `cancellation before call never reaches transport`() async {
        let client = HelperClient(transport: StubTransport { _ in Issue.record("Cancelled request sent"); return Data() })
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await client.call(HelperRequest(action: .status))
        }
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test
    func `first completion wins`() async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            let pending = PendingReply(continuation)
            pending.finish(.success(Data([42])))
            pending.finish(.failure(HelperTransportError.timedOut))
            pending.finish(.success(Data([99])))
        }
        #expect(result == Data([42]))
    }

    @Test
    func `concurrent completions resume once`() async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            let pending = PendingReply(continuation)
            DispatchQueue.concurrentPerform(iterations: 32) { value in pending.finish(.success(Data([UInt8(value)]))) }
        }
        #expect(result.count == 1)
        #expect(try #require(result.first) < 32)
    }

    @Test
    func `requirement has anchor team and exact identifiers`() throws {
        let value = try SigningRequirement.make(team: "ABCDE12345", identifiers: [ServiceIdentity.app, ServiceIdentity.cli])
        #expect(value ==
            "anchor apple generic and certificate leaf[subject.OU] = \"ABCDE12345\" and (identifier \"com.antonioruffolo.MacPowerScheduler\" or identifier \"com.antonioruffolo.MacPowerScheduler.cli\")")
        #expect(try SigningRequirement.make(team: "ABCDE12345", identifiers: [ServiceIdentity.helper]).contains("identifier \"\(ServiceIdentity.helper)\""))
    }

    @Test(arguments: ["", "short", "abcde12345", "ABCDE1234\"", "ＡBCDE12345"])
    func `invalid team cannot enter requirement`(_ team: String) {
        #expect(throws: SigningRequirement.unavailable()) { try SigningRequirement.make(team: team, identifiers: [ServiceIdentity.app]) }
    }

    @Test(arguments: [[], ["foreign.app"], [ServiceIdentity.app, "\" or true"]])
    func `identifiers are allowlisted`(_ identifiers: [String]) {
        #expect(throws: SigningRequirement.unavailable()) { try SigningRequirement.make(team: "ABCDE12345", identifiers: identifiers) }
    }
}
