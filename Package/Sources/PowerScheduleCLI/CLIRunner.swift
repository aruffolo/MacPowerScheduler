import Foundation
import PowerScheduleCore
import PowerScheduleIPC
import PowerScheduleSystem

public struct CLIOutput: Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
}

public struct CLIRunner: Sendable {
    private let helper: any HelperCalling
    private let read: @Sendable () async throws -> ScheduleSnapshot
    public init(
        helper: any HelperCalling = HelperClient(),
        read: @escaping @Sendable () async throws -> ScheduleSnapshot = {
            try await SystemSchedule().readAsync()
        },
    ) {
        self.helper = helper
        self.read = read
    }

    public func run(_ arguments: [String]) async -> CLIOutput {
        let json = arguments.contains("--json")
        do {
            let command = try CLICommand(arguments: arguments)
            if case .help = command.action {
                let text =
                    json
                        ? try jsonText(JSONEncoder().encode(["help": CLICommand.help]))
                        : CLICommand.help
                return CLIOutput(stdout: text + "\n", stderr: "", exitCode: 0)
            }
            let response: HelperResponse
            switch command.action {
            case .status: response = HelperResponse(schedule: try await read())
            case .doctor: response = try await helper.call(HelperRequest(action: .status)).checked()
            case .edit:
                let current = try await read()
                let edit = ScheduleEdit(
                    startup: command.startup, shutdown: command.shutdown,
                    replaceExisting: command.replaceExisting,
                    expectedRevision: command.revision ?? current.revision,
                )
                _ = try edit.resolve(against: current)
                response = try await helper.call(HelperRequest(action: .apply, edit: edit)).checked()
            case .help: preconditionFailure("Help was already handled")
            }
            return try render(response, json: json)
        } catch {
            let problem = ScheduleError.wrapping(error)
            return (try? render(HelperResponse(error: problem), json: json))
                ?? CLIOutput(stdout: "", stderr: "Output serialization failed.\n", exitCode: 6)
        }
    }

    private func jsonText(_ data: Data) throws -> String {
        guard let text = String(bytes: data, encoding: .utf8) else {
            throw ScheduleError(.systemFailure, "Output serialization failed.")
        }
        return text
    }

    private func render(_ response: HelperResponse, json: Bool) throws -> CLIOutput {
        let code = response.error?.exitCode ?? 0
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            return CLIOutput(
                stdout: try jsonText(encoder.encode(response)) + "\n", stderr: "",
                exitCode: code,
            )
        }
        if let error = response.error {
            return CLIOutput(stdout: "", stderr: error.message + "\n", exitCode: code)
        }
        var lines: [String] = []
        if let schedule = response.schedule {
            lines += [
                "Startup: \(schedule.startup?.summary ?? "Not scheduled")",
                "Shutdown: \(schedule.shutdown?.summary ?? "Not scheduled")",
                "Revision: \(schedule.revision)",
            ]
        }
        if let enabled = response.automationEnabled {
            lines.append("Automation: \(enabled ? "Enabled" : "Disabled")")
        }
        return CLIOutput(stdout: lines.joined(separator: "\n") + "\n", stderr: "", exitCode: 0)
    }
}
