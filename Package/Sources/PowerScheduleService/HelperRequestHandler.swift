import Foundation
import PowerScheduleCore
import PowerScheduleIPC

struct HelperRequestHandler: Sendable {
    let service: ScheduleService
    let resolveAccount: @Sendable () throws -> String

    func handle(_ data: Data) -> Data {
        let response: HelperResponse
        do {
            guard data.count < 65536 else {
                throw ScheduleError(.invalidInput, "Request exceeds its size limit.")
            }
            let request: HelperRequest
            do { request = try JSONDecoder().decode(HelperRequest.self, from: data) } catch {
                throw ScheduleError(.invalidInput, "The request is not a valid protocol message.")
            }
            response = service.handle(request, account: try resolveAccount())
        } catch { response = HelperResponse(error: .wrapping(error)) }
        // DTOs contain only finite JSON values. Always reply, even on encoding failure.
        return (try? JSONEncoder().encode(response)) ?? Data()
    }
}
