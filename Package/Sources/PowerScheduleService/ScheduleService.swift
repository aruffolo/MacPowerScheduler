import Foundation
import PowerScheduleCore
import PowerScheduleIPC
import PowerScheduleSystem

public final class ScheduleService: Sendable {
    private let queue = DispatchQueue(label: "MacPowerScheduler.transactions")
    private let backend: any ScheduleBackend
    private let grants: any GrantStoring
    private let authorize: @Sendable (Data?) throws -> Void
    public init(
        backend: any ScheduleBackend = SystemSchedule(), grants: any GrantStoring = FileGrantStore(),
        authorize: @escaping @Sendable (Data?) throws -> Void = AdministratorAuthorization.validate,
    ) {
        self.backend = backend
        self.grants = grants
        self.authorize = authorize
    }

    /// The entire read/check/write/readback transaction is synchronous on a private queue;
    /// grant revocation cannot interleave with a mutation already being authorized.
    public func handle(_ request: HelperRequest, account: String) -> HelperResponse {
        queue.sync {
            do {
                guard request.version == 1 else {
                    throw ScheduleError(
                        .helperUnavailable, "Protocol version mismatch. Update the app and helper together.",
                    )
                }
                let enabled = try grants.contains(account)
                switch request.action {
                case .status:
                    return HelperResponse(schedule: try backend.read(), automationEnabled: enabled)
                case .apply:
                    if !enabled {
                        try authorize(request.authorization)
                    }
                    guard let edit = request.edit else {
                        throw ScheduleError(.invalidInput, "The schedule change is missing.")
                    }
                    return try apply(edit, automationEnabled: enabled)
                case .enableAutomation, .disableAutomation:
                    try authorize(request.authorization)
                    let enable = request.action == .enableAutomation
                    try grants.set(account, enabled: enable)
                    return HelperResponse(automationEnabled: enable)
                case .clearAutomation:
                    try authorize(request.authorization)
                    try grants.clear()
                    return HelperResponse(automationEnabled: false)
                }
            } catch { return HelperResponse(error: .wrapping(error)) }
        }
    }

    private func apply(_ edit: ScheduleEdit, automationEnabled: Bool) throws -> HelperResponse {
        let current = try backend.read()
        let desired = try edit.resolve(against: current)
        let verified: ScheduleSnapshot
        do {
            try backend.write(desired)
            verified = try backend.read()
        } catch {
            throw ScheduleError(
                .uncertainResult,
                "The schedule may have changed but could not be verified. Refresh before retrying.",
            )
        }
        guard verified == desired else {
            throw ScheduleError(
                .uncertainResult,
                "The system schedule does not match the requested change. Refresh and review it.",
            )
        }
        return HelperResponse(schedule: verified, automationEnabled: automationEnabled)
    }
}
