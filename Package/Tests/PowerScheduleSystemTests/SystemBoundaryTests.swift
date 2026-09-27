import Foundation
import PowerScheduleCore
@testable import PowerScheduleSystem
import Testing

struct SystemBoundaryTests {
    @Test
    func `reading uses fixed arguments without privilege`() async throws {
        let reader = SystemSchedule(run: { arguments in
            #expect(arguments == ["-g", "sched"])
            return ProcessOutput(stdout: "No scheduled events.", stderr: "", status: 0)
        }, readMetadata: { Issue.record("Unneeded metadata read"); return Data() }, isRoot: { false })
        #expect(try reader.read() == ScheduleSnapshot())
        #expect(try await reader.readAsync() == ScheduleSnapshot())
    }

    @Test
    func `custom metadata loaded only when needed`() throws {
        let data = try plist(kind: "shutdown", time: 1380, days: 21, side: "RepeatingPowerOff")
        let reader = SystemSchedule(run: { _ in
            ProcessOutput(stdout: "Repeating power events:\n shutdown at 23:00 Some days", stderr: "", status: 0)
        }, readMetadata: { data }, isRoot: { false })
        let snapshot = try reader.read()
        #expect(snapshot.shutdown?.days == "MWF")
        #expect(try snapshot.shutdown?.time == ClockTime("23:00"))
    }

    @Test
    func `failed read does not parse or load metadata`() {
        let reader = SystemSchedule(
            run: { _ in ProcessOutput(stdout: "invalid Some days", stderr: "private", status: 1) },
            readMetadata: { Issue.record("Metadata after failure"); return Data() },
            isRoot: { false },
        )
        #expect(throws: ScheduleError(.systemFailure, "macOS could not read the power schedule.")) { try reader.read() }
    }

    @Test
    func `non root never invokes process`() {
        let reader = SystemSchedule(
            run: { _ in Issue.record("Unprivileged write"); return ProcessOutput(stdout: "", stderr: "", status: 0) },
            readMetadata: { Data() },
            isRoot: { false },
        )
        #expect(throws: ScheduleError(.authorizationRequired, "Only the authorized helper can change the schedule.")) {
            try reader.write(ScheduleSnapshot())
        }
    }

    @Test(arguments: [Int32(0), 1])
    func `write reports process result`(_ status: Int32) throws {
        let backend = SystemSchedule(run: { arguments in
            #expect(arguments == ["repeat", "wakeorpoweron", "MTWRFSU", "07:00:00"])
            return ProcessOutput(stdout: "", stderr: "", status: status)
        }, readMetadata: { Data() }, isRoot: { true })
        let snapshot = try ScheduleSnapshot(startup: PowerEvent(kind: .wakeorpoweron, time: ClockTime("07:00")))
        if status == 0 {
            try backend.write(snapshot)
        } else {
            #expect(throws: ScheduleError(.uncertainResult, "macOS did not confirm the schedule change. Refresh before retrying.")) {
                try backend.write(snapshot)
            }
        }
    }

    @Test
    func `invalid schedule never reaches process`() throws {
        let backend = SystemSchedule(
            run: { _ in Issue.record("Invalid write"); return ProcessOutput(stdout: "", stderr: "", status: 0) },
            readMetadata: { Data() },
            isRoot: { true },
        )
        let snapshot = try ScheduleSnapshot(startup: PowerEvent(kind: .wake, time: ClockTime("07:00")))
        #expect(throws: ScheduleError.self) { try backend.write(snapshot) }
    }

    @Test(arguments: [("unknown", 1, 1), ("wake", -1, 1), ("wake", 1440, 1), ("wake", 1, 0), ("wake", 1, 128)])
    func `invalid metadata`(_ kind: String, _ time: Int, _ days: Int) throws {
        let data = try plist(kind: kind, time: time, days: days)
        #expect(throws: ScheduleError.self) { try RepeatingPreferences.decode(data) }
    }

    @Test(arguments: [("shutdown", "RepeatingPowerOn"), ("wake", "RepeatingPowerOff")])
    func `metadata rejects wrong side`(_ kind: String, _ side: String) throws {
        let data = try plist(kind: kind, time: 0, days: 127, side: side)
        #expect(throws: ScheduleError.self) { try RepeatingPreferences.decode(data) }
    }

    @Test
    func `metadata size and empty boundaries`() throws {
        #expect(throws: ScheduleError.self) { try RepeatingPreferences.decode(Data(repeating: 0, count: 1048577)) }
        let empty = try PropertyListSerialization.data(fromPropertyList: [:], format: .binary, options: 0)
        #expect(try RepeatingPreferences.decode(empty) == ScheduleSnapshot())
        let data = try plist(kind: "poweron", time: 1439, days: 127)
        let snapshot = try RepeatingPreferences.decode(data)
        #expect(try snapshot.startup?.time == ClockTime("23:59"))
        #expect(snapshot.startup?.days == "MTWRFSU")
    }

    @Test(arguments: [
        "Repeating power events:\nRepeating power events:",
        "Repeating power events:\nwake at 07:00 every day\npoweron at 08:00 every day",
        "Repeating power events:\nshutdown at 13:00PM every day",
        "Repeating power events:\nshutdown at 23:00 every and on",
    ])
    func `parser rejects ambiguity`(_ text: String) {
        #expect(throws: Error.self) { try PMSetParser.parse(text) }
    }

    @Test
    func `metadata cannot contradict printed schedule`() throws {
        let data = try plist(kind: "wake", time: 450, days: 127)
        #expect(throws: ScheduleError.self) { try PMSetParser.parse("No scheduled events.", repeatingPreferences: data) }
        #expect(throws: ScheduleError.self) {
            try PMSetParser.parse("Repeating power events:\nwake at 08:00 every day", repeatingPreferences: data)
        }
        #expect(throws: ScheduleError.self) { try PMSetParser.parse(String(repeating: " ", count: 1048577)) }
    }

    private func plist(kind: String, time: Int, days: Int, side: String = "RepeatingPowerOn") throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: [side: ["eventtype": kind, "time": time, "weekdays": days]],
            format: .binary,
            options: 0,
        )
    }
}
