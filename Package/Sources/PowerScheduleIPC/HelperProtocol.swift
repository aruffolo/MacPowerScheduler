import Foundation
import PowerScheduleCore

@objc public protocol HelperProtocol {
    func perform(_ request: Data, reply: @escaping @Sendable (Data) -> Void)
}

public struct HelperRequest: Codable, Sendable {
    public enum Action: String, Codable, Sendable {
        case status, apply, enableAutomation, disableAutomation, clearAutomation
    }

    public let version: Int
    public let action: Action
    public let edit: ScheduleEdit?
    public let authorization: Data?
    public init(action: Action, edit: ScheduleEdit? = nil, authorization: Data? = nil) {
        version = 1
        self.action = action
        self.edit = edit
        self.authorization = authorization
    }
}

public struct HelperResponse: Codable, Sendable {
    public let schemaVersion: Int
    public let revision: String?
    public let schedule: ScheduleSnapshot?
    public let automationEnabled: Bool?
    public let error: ScheduleError?
    public init(
        schedule: ScheduleSnapshot? = nil, automationEnabled: Bool? = nil, error: ScheduleError? = nil,
    ) {
        schemaVersion = 1
        revision = schedule?.revision
        self.schedule = schedule
        self.automationEnabled = automationEnabled
        self.error = error
    }

    public func checked() throws -> Self {
        guard schemaVersion == 1 else {
            throw ScheduleError(
                .helperUnavailable, "The app and helper versions do not match. Re-enable the helper.",
            )
        }
        if let error {
            throw error
        }
        return self
    }
}

public enum ServiceIdentity {
    public static let app = "com.antonioruffolo.MacPowerScheduler"
    public static let cli = "com.antonioruffolo.MacPowerScheduler.cli"
    public static let helper = "com.antonioruffolo.MacPowerScheduler.helper"
    public static let plist = helper + ".plist"
}

public protocol HelperCalling: Sendable {
    func call(_ request: HelperRequest) async throws -> HelperResponse
}
