import Foundation
import PowerScheduleCore

protocol HelperTransport: Sendable {
    func exchange(_ payload: Data) async throws -> Data
}

enum HelperTransportError: Error {
    case unavailable, interrupted, timedOut
}

public struct HelperClient: HelperCalling {
    private let transport: any HelperTransport
    public init() {
        transport = XPCTransport()
    }

    init(transport: any HelperTransport) {
        self.transport = transport
    }

    public func call(_ request: HelperRequest) async throws -> HelperResponse {
        try Task.checkCancellation()
        let payload = try JSONEncoder().encode(request)
        guard payload.count < 65536 else {
            throw ScheduleError(.invalidInput, "Request exceeds its size limit.")
        }
        let bytes: Data
        do { bytes = try await transport.exchange(payload) } catch let error as HelperTransportError {
            throw Self.transportError(error, for: request)
        }
        return try Self.receive(bytes, for: request)
    }

    private static func transportError(_ error: HelperTransportError, for request: HelperRequest) -> ScheduleError {
        switch error {
        case .unavailable:
            return request.action == .status
                ? ScheduleError(
                    .helperUnavailable,
                    "The helper is unavailable. Enable Power Scheduling in the app and approve it in System Settings.",
                )
                : ScheduleError(
                    .uncertainResult,
                    "The helper connection failed; the operation may have been applied. Refresh and check setup before retrying.",
                )
        case .interrupted:
            return ScheduleError(.uncertainResult, "The helper connection was interrupted. Refresh before retrying a change.")
        case .timedOut:
            return ScheduleError(.uncertainResult, "The helper did not respond in time. Refresh before retrying.")
        }
    }

    private static func receive(_ bytes: Data, for request: HelperRequest) throws -> HelperResponse {
        let response: HelperResponse
        do {
            guard bytes.count < 65536 else {
                throw ScheduleError(.systemFailure, "The helper response exceeds its size limit.")
            }
            response = try JSONDecoder().decode(HelperResponse.self, from: bytes)
        } catch {
            if request.action != .status {
                throw ScheduleError(.uncertainResult, "The helper returned an unreadable response. Refresh before retrying.")
            }
            throw error
        }
        return try response.checked()
    }
}
