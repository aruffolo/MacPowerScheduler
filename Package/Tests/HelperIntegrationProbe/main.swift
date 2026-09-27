import Foundation
import PowerScheduleCore
import PowerScheduleIPC

/// Test-only executable. Never embedded in the app. Its raw XPC path deliberately
/// reaches the listener even when this probe has an invalid client signature.
private final class Reply: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data, Error>?
    init(_ continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    func finish(_ result: Result<Data, Error>) {
        lock.lock()
        let saved = continuation
        continuation = nil
        lock.unlock()
        saved?.resume(with: result)
    }
}

@main struct HelperIntegrationProbe {
    static func main() async {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            guard args.count == 2, args[0].range(of: "^[A-Z0-9]{10}$", options: .regularExpression) != nil
            else {
                throw ScheduleError(
                    .invalidInput,
                    "Usage: HelperIntegrationProbe SERVER_TEAM status|malformed|version|grant-denied|oversized",
                )
            }
            let payload: Data
            switch args[1] {
            case "status": payload = try JSONEncoder().encode(HelperRequest(action: .status))
            case "malformed": payload = Data("not JSON".utf8)
            case "version": payload = Data(#"{"version":999,"action":"status"}"#.utf8)
            case "grant-denied":
                payload = try JSONEncoder().encode(HelperRequest(action: .enableAutomation))
            case "oversized": payload = Data(repeating: 32, count: 65536)
            default: throw ScheduleError(.invalidInput, "Unknown probe mode")
            }
            let connection = NSXPCConnection(
                machServiceName: ServiceIdentity.helper, options: .privileged,
            )
            connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
            connection.setCodeSigningRequirement(
                "anchor apple generic and certificate leaf[subject.OU] = \"\(args[0])\" and identifier \"\(ServiceIdentity.helper)\"",
            )
            defer { connection.invalidate() }
            let bytes: Data = try await withCheckedThrowingContinuation { continuation in
                let reply = Reply(continuation)
                let denied = ScheduleError(.helperUnavailable, "Probe connection rejected or unavailable")
                connection.invalidationHandler = { reply.finish(.failure(denied)) }
                connection.interruptionHandler = { reply.finish(.failure(denied)) }
                connection.activate()
                guard
                    let proxy = connection.remoteObjectProxyWithErrorHandler({ @Sendable _ in
                        reply.finish(.failure(denied))
                    }) as? HelperProtocol
                else {
                    reply.finish(.failure(denied))
                    return
                }
                proxy.perform(payload) { reply.finish(.success($0)) }
                DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                    reply.finish(
                        .failure(
                            ScheduleError(
                                .uncertainResult, "Probe timed out; this is not proof of peer rejection",
                            ),
                        ),
                    )
                }
            }
            let response = try JSONDecoder().decode(HelperResponse.self, from: bytes)
            guard response.schemaVersion == 1 else {
                throw ScheduleError(.systemFailure, "Unexpected probe response schema")
            }
            if args[1] == "status", response.error == nil {
                guard let schedule = response.schedule, response.revision == schedule.revision,
                      response.automationEnabled != nil
                else {
                    throw ScheduleError(.systemFailure, "Incomplete status response")
                }
            }
            FileHandle.standardOutput.write(bytes + Data("\n".utf8))
            exit(response.error?.exitCode ?? 0)
        } catch {
            let failure = ScheduleError.wrapping(error)
            FileHandle.standardError.write(Data((failure.message + "\n").utf8))
            exit(failure.exitCode)
        }
    }
}
