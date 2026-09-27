import Foundation
import PowerScheduleCore
@testable import PowerScheduleSystem
import Testing

struct SystemTests {
    @Test
    func `parses real style output and ignores one time events`() throws {
        let text = """
        Repeating power events:
          wakepoweron at 7:30AM every day
          shutdown at 11:00PM every day
        Scheduled power events:
        [0] wake at 09/27/26 08:00:00 by 'unrelated.owner'
        """
        let schedule = try PMSetParser.parse(text)
        #expect(try schedule.startup?.time == ClockTime("07:30"))
        #expect(try schedule.shutdown?.time == ClockTime("23:00"))
        #expect(schedule.isDailyEditable)
    }

    @Test(arguments: [
        "", "No scheduled events.\n", "Scheduled power events:\n[0] wake at later by somebody",
        "Repeating power events:\nScheduled power events:\n",
    ])
    func `empty repeating`(_ text: String) throws {
        #expect(try PMSetParser.parse(text) == ScheduleSnapshot())
    }

    @Test
    func `uncommon schedules are preserved`() throws {
        let result = try PMSetParser.parse(
            "Repeating power events:\n wake at 12:00AM weekdays\n sleep at 21:30:15 on Monday Wednesday Friday",
        )
        #expect(result.startup?.time.hour == 0)
        #expect(result.shutdown?.time.second == 15)
        #expect(result.shutdown?.days == "MWF")
        #expect(result.isDailyEditable == false)
    }

    @Test(arguments: [
        "oops", "Repeating power events:\n unexpected",
        "Repeating power events:\n shutdown at 23:00 tomorrow",
        "Repeating power events:\n shutdown at 11:00PM every day\n sleep at 10:00PM every day",
    ])
    func `unknown is not empty`(_ text: String) {
        #expect(throws: Error.self) { try PMSetParser.parse(text) }
    }

    @Test
    func `parses apple midnight and day labels`() throws {
        let schedule = try PMSetParser.parse(
            "Repeating power events:\n wakepoweron at 0:00AM weekdays only\n shutdown at 11:00PM weekends only",
        )
        #expect(try schedule.startup?.time == ClockTime("00:00"))
        #expect(schedule.startup?.days == "MTWRF")
        #expect(schedule.shutdown?.days == "SU")
        #expect(throws: Error.self) {
            try PMSetParser.parse("Repeating power events:\n wakepoweron at 0:00PM every day")
        }
    }

    @Test
    func `custom day metadata must match`() throws {
        let text = "Repeating power events:\n wakepoweron at 7:30AM Some days"
        #expect(PMSetParser.requiresRepeatingMetadata(text))
        #expect(
            !PMSetParser.requiresRepeatingMetadata(
                "Scheduled power events:\n[0] wake at later by Some days",
            ),
        )
        let metadata: [String: Any] = [
            "RepeatingPowerOn": ["eventtype": "wakepoweron", "time": 450, "weekdays": 21],
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: metadata, format: .xml, options: 0,
        )
        let result = try PMSetParser.parse(text, repeatingPreferences: data)
        #expect(result.startup?.days == "MWF")
        #expect(!result.isDailyEditable)
        #expect(throws: Error.self) { try PMSetParser.parse(text) }
        #expect(throws: Error.self) {
            try PMSetParser.parse(
                text.replacingOccurrences(of: "7:30", with: "8:30"), repeatingPreferences: data,
            )
        }
        #expect(throws: Error.self) {
            try PMSetParser.parse(text, repeatingPreferences: Data("bad".utf8))
        }
    }
}
