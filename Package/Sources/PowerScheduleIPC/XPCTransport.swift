import Foundation

struct XPCTransport: HelperTransport {
    func exchange(_ payload: Data) async throws -> Data {
        let requirement = try SigningPolicy.requirement(identifiers: [ServiceIdentity.helper])
        let connection = NSXPCConnection(machServiceName: ServiceIdentity.helper, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.setCodeSigningRequirement(requirement)
        defer { connection.invalidate() }
        return try await withCheckedThrowingContinuation { continuation in
            Self.send(payload, connection: connection, pending: PendingReply(continuation))
        }
    }

    private static func send(_ payload: Data, connection: NSXPCConnection, pending: PendingReply) {
        connection.invalidationHandler = { pending.finish(.failure(HelperTransportError.unavailable)) }
        connection.interruptionHandler = { pending.finish(.failure(HelperTransportError.interrupted)) }
        connection.activate()
        let proxy = connection.remoteObjectProxyWithErrorHandler { _ in
            pending.finish(.failure(HelperTransportError.unavailable))
        }
        guard let helper = proxy as? HelperProtocol else {
            pending.finish(.failure(HelperTransportError.unavailable))
            return
        }
        helper.perform(payload) { pending.finish(.success($0)) }
        DispatchQueue.global().asyncAfter(deadline: .now() + 20) {
            pending.finish(.failure(HelperTransportError.timedOut))
        }
    }
}
