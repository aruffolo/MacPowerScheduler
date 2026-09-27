import Foundation
@testable import PowerScheduleCore
import Testing

struct CoreBoundaryTests {
    @Test(arguments: [(0, 0, 0, "00:00", "00:00:00"), (23, 59, 59, "23:59", "23:59:59")])
    func `clock boundaries`(_ hour: Int, _ minute: Int, _ second: Int, _ text: String, _ argument: String) throws {
        let time = try ClockTime(hour: hour, minute: minute, second: second)
        #expect(time.text == text)
        #expect(time.argument == argument)
        #expect(try time.validated() == time)
        #expect(try JSONDecoder().decode(ClockTime.self, from: JSONEncoder().encode(time)) == time)
    }

    @Test(arguments: [(-1, 0, 0), (24, 0, 0), (0, -1, 0), (0, 60, 0), (0, 0, -1), (0, 0, 60)])
    func `invalid components`(_ hour: Int, _ minute: Int, _ second: Int) {
        #expect(throws: ScheduleError(.invalidInput, "Time must be between 00:00 and 23:59.")) {
            try ClockTime(hour: hour, minute: minute, second: second)
        }
    }

    @Test(arguments: [
        (PowerEvent.Kind.wakeorpoweron, "MTWRFSU", "Wake or power on · Every day at 07:30"),
        (.shutdown, "MTWRF", "Shutdown · Weekdays at 07:30"),
        (.sleep, "SU", "Sleep · Weekends at 07:30"),
        (.restart, "MWF", "Restart · MWF at 07:30"),
    ])
    func summaries(_ kind: PowerEvent.Kind, _ days: String, _ expected: String) throws {
        #expect(try PowerEvent(kind: kind, days: days, time: ClockTime("07:30")).summary == expected)
    }

    @Test
    func `seconds remain visible`() throws {
        let event = try PowerEvent(kind: .wake, time: ClockTime(hour: 7, minute: 30, second: 15))
        #expect(event.summary == "Wake · Every day at 07:30:15")
        #expect(!ScheduleSnapshot(startup: event).isDailyEditable)
    }

    @Test(arguments: [
        (PowerEvent.Kind.wake, true), (.poweron, true), (.wakeorpoweron, true),
        (.shutdown, false), (.sleep, false), (.restart, false),
    ])
    func `startup classification`(_ kind: PowerEvent.Kind, _ expected: Bool) {
        #expect(kind.isStartup == expected)
    }

    @Test
    func `invalid edits cannot produce commands`() throws {
        let empty = ScheduleSnapshot()
        #expect(throws: ScheduleError(.invalidInput, "Specify at least one schedule change.")) {
            try ScheduleEdit(expectedRevision: empty.revision).resolve(against: empty)
        }
        let seconds = try ClockTime(hour: 7, minute: 0, second: 1)
        #expect(throws: ScheduleError(.invalidInput, "New times use minute precision.")) {
            try ScheduleEdit(startup: .set(seconds), expectedRevision: empty.revision).resolve(against: empty)
        }
        let alternate = ScheduleSnapshot(shutdown: PowerEvent(kind: .sleep, time: seconds))
        #expect(throws: ScheduleError.self) { try ScheduleEdit.arguments(for: alternate) }
        let invalid = try JSONDecoder().decode(ClockTime.self, from: Data(#"{"hour":24,"minute":0,"second":0}"#.utf8))
        #expect(throws: ScheduleError.self) {
            try ScheduleEdit.arguments(for: ScheduleSnapshot(startup: PowerEvent(kind: .wakeorpoweron, time: invalid)))
        }
    }

    @Test
    func `revision tracks every persisted field`() throws {
        let time = try ClockTime("07:00")
        let baseline = ScheduleSnapshot(startup: PowerEvent(kind: .wakeorpoweron, time: time))
        let variants = [
            ScheduleSnapshot(),
            ScheduleSnapshot(startup: PowerEvent(kind: .wake, time: time)),
            ScheduleSnapshot(startup: PowerEvent(kind: .wakeorpoweron, days: "MTWRF", time: time)),
            try ScheduleSnapshot(startup: PowerEvent(kind: .wakeorpoweron, time: ClockTime("07:01"))),
            ScheduleSnapshot(shutdown: PowerEvent(kind: .shutdown, time: time)),
        ]
        #expect(baseline.revision.count == 64)
        for variant in variants {
            #expect(variant.revision != baseline.revision)
        }
        let roundTrip = try JSONDecoder().decode(ScheduleSnapshot.self, from: JSONEncoder().encode(baseline))
        #expect(roundTrip.revision == baseline.revision)
    }

    @Test(arguments: [
        (ScheduleError.Code.invalidInput, Int32(2)), (.authorizationRequired, 3), (.helperUnavailable, 4),
        (.signingRequired, 4), (.conflict, 5), (.replacementRequired, 5), (.unreadableSchedule, 6),
        (.systemFailure, 6), (.uncertainResult, 7),
    ])
    func `error contract`(_ code: ScheduleError.Code, _ expected: Int32) throws {
        let error = ScheduleError(code, "fixture")
        #expect(error.exitCode == expected)
        #expect(error.errorDescription == "fixture")
        #expect(ScheduleError.wrapping(error) == error)
        #expect(try JSONDecoder().decode(ScheduleError.self, from: JSONEncoder().encode(error)) == error)
    }

    @Test
    func `unknown errors retain their message`() {
        let wrapped = ScheduleError.wrapping(NSError(domain: "fixture", code: 1, userInfo: [NSLocalizedDescriptionKey: "failed"]))
        #expect(wrapped == ScheduleError(.systemFailure, "failed"))
    }
}
