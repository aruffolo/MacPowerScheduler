import PowerScheduleIPC
import ServiceManagement

@MainActor public struct MacSchedulingPlatform: SchedulingPlatform {
    public init() {}
    public var signingReady: Bool {
        (try? SigningPolicy.teamIdentifier()) != nil
    }

    public var registration: HelperRegistration {
        switch SMAppService.daemon(plistName: ServiceIdentity.plist).status {
        case .notRegistered: .notRegistered
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .notFound
        @unknown default: .notFound
        }
    }

    public func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    public func register() throws {
        _ = try SigningPolicy.teamIdentifier()
        try SMAppService.daemon(plistName: ServiceIdentity.plist).register()
    }

    public func unregister() async throws {
        try await SMAppService.daemon(plistName: ServiceIdentity.plist).unregister()
    }

    public func authorize() async throws -> AuthorizationLease {
        let authorization = try await AdministratorAuthorization()
        return AuthorizationLease(externalForm: authorization.externalForm, retaining: authorization)
    }
}
