import Foundation

public struct ScheduleError: Error, Codable, Sendable, Equatable, LocalizedError {
    public enum Code: String, Codable, Sendable {
        case invalidInput, unreadableSchedule, conflict, replacementRequired
        case authorizationRequired, helperUnavailable, signingRequired, systemFailure, uncertainResult
    }

    public let code: Code
    public let message: String
    public init(_ code: Code, _ message: String) {
        self.code = code
        self.message = message
    }

    public var errorDescription: String? {
        message
    }

    public var exitCode: Int32 {
        switch code {
        case .invalidInput: 2
        case .authorizationRequired: 3
        case .helperUnavailable, .signingRequired: 4
        case .conflict, .replacementRequired: 5
        case .unreadableSchedule, .systemFailure: 6
        case .uncertainResult: 7
        }
    }

    public static func wrapping(_ error: Error) -> Self {
        (error as? Self) ?? Self(.systemFailure, error.localizedDescription)
    }
}
