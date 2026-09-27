import Foundation
import PowerScheduleCore
import Security

/// Holds a short-lived system authorization reference; never stores a password.
public final class AdministratorAuthorization {
    private let reference: AuthorizationRef
    public let externalForm: Data
    @MainActor
    public init() async throws {
        var reference: AuthorizationRef?
        guard AuthorizationCreate(nil, nil, [], &reference) == errAuthorizationSuccess, let reference
        else { throw Self.denied() }
        do {
            let result: OSStatus = await withCheckedContinuation { continuation in
                "system.privilege.admin".withCString { name in
                    var item = AuthorizationItem(name: name, valueLength: 0, value: nil, flags: 0)
                    withUnsafeMutablePointer(to: &item) { item in
                        var rights = AuthorizationRights(count: 1, items: item)
                        AuthorizationCopyRightsAsync(
                            reference, &rights, nil,
                            [.interactionAllowed, .extendRights, .preAuthorize],
                        ) { @Sendable result, granted in
                            if let granted {
                                AuthorizationFreeItemSet(granted)
                            }
                            continuation.resume(returning: result)
                        }
                    }
                }
            }
            guard result == errAuthorizationSuccess else { throw Self.denied() }
            var external = AuthorizationExternalForm()
            guard AuthorizationMakeExternalForm(reference, &external) == errAuthorizationSuccess else {
                throw Self.denied()
            }
            self.reference = reference
            externalForm = withUnsafeBytes(of: &external) { Data($0) }
        } catch {
            AuthorizationFree(reference, [])
            throw error
        }
    }

    deinit { AuthorizationFree(reference, []) }
    public static func validate(_ data: Data?) throws {
        guard let data, data.count == MemoryLayout<AuthorizationExternalForm>.size else {
            throw denied()
        }
        var form = AuthorizationExternalForm()
        _ = withUnsafeMutableBytes(of: &form) { data.copyBytes(to: $0) }
        var reference: AuthorizationRef?
        guard AuthorizationCreateFromExternalForm(&form, &reference) == errAuthorizationSuccess,
              let reference
        else { throw denied() }
        defer { AuthorizationFree(reference, []) }
        try check(reference, interaction: false)
    }

    private static func check(_ reference: AuthorizationRef, interaction: Bool) throws {
        let result = "system.privilege.admin".withCString { name in
            var item = AuthorizationItem(name: name, valueLength: 0, value: nil, flags: 0)
            return withUnsafeMutablePointer(to: &item) { item in
                var rights = AuthorizationRights(count: 1, items: item)
                let flags: AuthorizationFlags =
                    interaction ? [.interactionAllowed, .extendRights, .preAuthorize] : [.extendRights]
                return AuthorizationCopyRights(reference, &rights, nil, flags, nil)
            }
        }
        guard result == errAuthorizationSuccess else { throw denied() }
    }

    private static func denied() -> ScheduleError {
        ScheduleError(
            .authorizationRequired,
            "Administrator authorization is required. Open the app to authorize this operation or enable automation for your account.",
        )
    }
}
