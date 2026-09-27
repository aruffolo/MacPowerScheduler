import Foundation
@testable import PowerScheduleCLI
import PowerScheduleCore
import PowerScheduleIPC
import Testing

private struct DeniedHelper: HelperCalling {
    func call(_ request: HelperRequest) async throws -> HelperResponse {
        throw ScheduleError(.authorizationRequired, "Enable automation in the app.")
    }
}

struct CLITests {
    @Test(arguments: [
        ["set"], ["set", "--startup", "7:00"], ["set", "--startup", "07:00", "--no-startup"],
        ["set", "--startup", "07:00", "--replace-existing"], ["status", "--unknown"],
        ["disable", "nope"],
    ])
    func `rejects ambiguous inputs`(_ args: [String]) {
        #expect(throws: Error.self) { try CLICommand(arguments: args) }
    }

    @Test
    func `partial semantics`() throws {
        let command = try CLICommand(arguments: ["set", "--startup", "07:00", "--json"])
        #expect(command.shutdown == .preserve)
        #expect(command.json)
    }

    @Test
    func `status does not need helper and JSON errors stay on stdout`() async throws {
        let runner = CLIRunner(helper: DeniedHelper(), read: { ScheduleSnapshot() })
        let status = await runner.run(["status", "--json"])
        #expect(status.exitCode == 0)
        #expect(
            try JSONDecoder().decode(HelperResponse.self, from: Data(status.stdout.utf8)).schedule != nil,
        )
        let denied = await runner.run(["set", "--startup", "07:00", "--json"])
        #expect(denied.exitCode == 3)
        #expect(denied.stderr.isEmpty)
        #expect(
            try JSONDecoder().decode(HelperResponse.self, from: Data(denied.stdout.utf8)).error?.code
                == .authorizationRequired,
        )
    }
}
