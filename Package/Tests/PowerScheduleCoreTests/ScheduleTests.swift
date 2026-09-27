import Foundation
@testable import PowerScheduleCore
import Testing

struct ScheduleTests {
    @Test(arguments: ["7:30", "24:00", "12:60", "-1:00", "07:30:00", "１２:００", "07:00;whoami"])
    func `invalid times`(_ value: String) {
        #expect(throws: ScheduleError.self) { try ClockTime(value) }
    }

    @Test(arguments: [false, true], [false, true])
    func `complete pair`(on: Bool, off: Bool) throws {
        let empty = ScheduleSnapshot()
        let edit = ScheduleEdit(
            startup: on ? .set(try ClockTime("07:30")) : .disable,
            shutdown: off ? .set(try ClockTime("23:00")) : .disable, expectedRevision: empty.revision,
        )
        let result = try edit.resolve(against: empty)
        let argv = try ScheduleEdit.arguments(for: result)
        #expect((result.startup != nil) == on)
        #expect((result.shutdown != nil) == off)
        #expect(
            argv
                == (on || off
                    ? ["repeat"] + (on ? ["wakeorpoweron", "MTWRFSU", "07:30:00"] : [])
                    + (off ? ["shutdown", "MTWRFSU", "23:00:00"] : []) : ["repeat", "cancel"]),
        )
    }

    @Test
    func `partial edit preserves other side`() throws {
        let current = ScheduleSnapshot(
            shutdown: PowerEvent(kind: .shutdown, time: try ClockTime("23:00")),
        )
        let result = try ScheduleEdit(
            startup: .set(ClockTime("07:00")), expectedRevision: current.revision,
        ).resolve(against: current)
        #expect(result.shutdown == current.shutdown)
    }

    @Test
    func `conflict and replacement`() throws {
        let current = ScheduleSnapshot(
            startup: PowerEvent(kind: .wake, days: "MTWRF", time: try ClockTime("07:30")),
        )
        #expect(throws: ScheduleError.self) {
            try ScheduleEdit(startup: .disable, expectedRevision: "stale").resolve(against: current)
        }
        #expect(throws: ScheduleError.self) {
            try ScheduleEdit(startup: .disable, expectedRevision: current.revision).resolve(
                against: current,
            )
        }
        let replacement = try ScheduleEdit(
            startup: .disable, shutdown: .disable, replaceExisting: true,
            expectedRevision: current.revision,
        ).resolve(against: current)
        #expect(replacement == ScheduleSnapshot())
    }

    @Test
    func `equal times rejected and overnight accepted`() throws {
        let current = ScheduleSnapshot()
        #expect(throws: ScheduleError.self) {
            try ScheduleEdit(
                startup: .set(ClockTime("07:00")), shutdown: .set(ClockTime("07:00")),
                expectedRevision: current.revision,
            ).resolve(against: current)
        }
        let result = try ScheduleEdit(
            startup: .set(ClockTime("22:00")), shutdown: .set(ClockTime("06:00")),
            expectedRevision: current.revision,
        ).resolve(against: current)
        #expect(result.startup?.time.hour == 22)
    }

    @Test
    func `decoded times are revalidated at boundary`() throws {
        let bad = try JSONDecoder().decode(
            ClockTime.self, from: Data(#"{"hour":99,"minute":0,"second":0}"#.utf8),
        )
        #expect(throws: ScheduleError.self) {
            try ScheduleEdit(startup: .set(bad), expectedRevision: ScheduleSnapshot().revision).resolve(
                against: ScheduleSnapshot(),
            )
        }
    }
}
