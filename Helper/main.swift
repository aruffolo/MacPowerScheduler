import Foundation
import PowerScheduleService

let server = HelperServer()
do {
    let listener = try server.start()
    withExtendedLifetime((server, listener)) { dispatchMain() }
} catch {
    FileHandle.standardError.write(
        Data("Helper could not start: \(error.localizedDescription)\n".utf8),
    )
    exit(1)
}
