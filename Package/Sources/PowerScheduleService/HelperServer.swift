import Foundation
import PowerScheduleCore
import PowerScheduleIPC

private final class ConnectionSession: NSObject, HelperProtocol, Sendable {
    private let handler: HelperRequestHandler
    init(uid: uid_t, service: ScheduleService) {
        handler = HelperRequestHandler(service: service, resolveAccount: { try AccountResolver().identifier(for: uid) })
    }

    func perform(_ data: Data, reply: @escaping @Sendable (Data) -> Void) {
        reply(handler.handle(data))
    }
}

public final class HelperServer: NSObject, NSXPCListenerDelegate {
    private let service = ScheduleService()
    override public init() {
        super.init()
    }

    public func start() throws -> NSXPCListener {
        guard geteuid() == 0 else {
            throw ScheduleError(
                .authorizationRequired, "The helper must be launched by ServiceManagement as root.",
            )
        }
        let requirement = try SigningPolicy.requirement(identifiers: [
            ServiceIdentity.app, ServiceIdentity.cli,
        ])
        let listener = NSXPCListener(machServiceName: ServiceIdentity.helper)
        listener.setConnectionCodeSigningRequirement(requirement)
        listener.delegate = self
        listener.activate()
        return listener
    }

    public func listener(
        _ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection,
    ) -> Bool {
        // Signing requirement is checked by the listener before this delegate runs.
        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedObject = ConnectionSession(
            uid: connection.effectiveUserIdentifier, service: service,
        )
        connection.activate()
        return true
    }
}
