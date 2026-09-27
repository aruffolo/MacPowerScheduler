import Foundation
import PowerScheduleCore

public protocol ScheduleBackend: Sendable {
    func read() throws -> ScheduleSnapshot
    func write(_ schedule: ScheduleSnapshot) throws
}

public struct SystemSchedule: ScheduleBackend {
    private let run: @Sendable ([String]) throws -> ProcessOutput
    private let readMetadata: @Sendable () throws -> Data
    private let isRoot: @Sendable () -> Bool

    init(
        run: @escaping @Sendable ([String]) throws -> ProcessOutput,
        readMetadata: @escaping @Sendable () throws -> Data,
        isRoot: @escaping @Sendable () -> Bool,
    ) {
        self.run = run
        self.readMetadata = readMetadata
        self.isRoot = isRoot
    }

    public func read() throws -> ScheduleSnapshot {
        let result = try run(["-g", "sched"])
        guard result.status == 0 else {
            throw ScheduleError(.systemFailure, "macOS could not read the power schedule.")
        }
        let supplemental =
            PMSetParser.requiresRepeatingMetadata(result.stdout) ? try readMetadata() : nil
        return try PMSetParser.parse(result.stdout, repeatingPreferences: supplemental)
    }

    public func write(_ schedule: ScheduleSnapshot) throws {
        guard isRoot() else {
            throw ScheduleError(
                .authorizationRequired, "Only the authorized helper can change the schedule.",
            )
        }
        let result = try run(ScheduleEdit.arguments(for: schedule))
        guard result.status == 0 else {
            throw ScheduleError(
                .uncertainResult, "macOS did not confirm the schedule change. Refresh before retrying.",
            )
        }
    }

    @concurrent
    public func readAsync() async throws -> ScheduleSnapshot {
        try read()
    }
}
