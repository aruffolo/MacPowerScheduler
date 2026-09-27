import Foundation

/// Keeps the system authorization alive until the helper has consumed its external form.
@MainActor public struct AuthorizationLease {
    public let externalForm: Data
    private let retained: AnyObject?
    public init(externalForm: Data, retaining object: AnyObject? = nil) {
        self.externalForm = externalForm
        retained = object
    }
}

@MainActor public protocol SchedulingPlatform {
    var signingReady: Bool { get }
    var requiresApproval: Bool { get }
    func register() throws
    func unregister() async throws
    func authorize() async throws -> AuthorizationLease
}
