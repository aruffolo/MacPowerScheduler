import Foundation
import PowerScheduleCore

public enum PMSetParser {
    public static func requiresRepeatingMetadata(_ text: String) -> Bool {
        let repeating = text.components(separatedBy: "Scheduled power events:").first ?? ""
        return repeating.components(separatedBy: .newlines).contains {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(" Some days")
        }
    }

    public static func parse(_ text: String, repeatingPreferences: Data? = nil) throws
        -> ScheduleSnapshot {
        if text.trimmingCharacters(in: .whitespacesAndNewlines) == "No scheduled events." {
            guard repeatingPreferences == nil else { throw unreadable() }
            return ScheduleSnapshot()
        }
        let supplemental = try repeatingPreferences.map(RepeatingPreferences.decode)
        guard text.utf8.count <= 1048576 else { throw unreadable() }
        var section = RepeatingSection()
        for raw in text.components(separatedBy: .newlines) {
            try section.consume(raw, supplemental: supplemental)
        }
        // An empty successful pmset output means no events; unexpected prose does not.
        guard section.sawHeader || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw unreadable()
        }
        let result = ScheduleSnapshot(startup: section.startup, shutdown: section.shutdown)
        if let supplemental, supplemental != result {
            throw unreadable()
        }
        return result
    }

    private struct RepeatingSection {
        var inRepeating = false
        var sawHeader = false
        var startup: PowerEvent?
        var shutdown: PowerEvent?
        mutating func consume(_ raw: String, supplemental: ScheduleSnapshot?) throws {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                return
            }
            if line == "Repeating power events:" {
                guard !sawHeader else { throw unreadable() }
                sawHeader = true
                inRepeating = true
                return
            }
            if line == "Scheduled power events:" {
                sawHeader = true
                inRepeating = false
                return
            }
            if !inRepeating {
                // pmset can omit the repeating header when there is no repeating pair.
                guard sawHeader else { throw unreadable() }
                return
            }
            let event = try parseEvent(line, supplemental: supplemental)
            if event.kind.isStartup {
                guard startup == nil else { throw unreadable() }
                startup = event
            } else {
                guard shutdown == nil else { throw unreadable() }
                shutdown = event
            }
        }
    }

    private static func parseEvent(_ line: String, supplemental: ScheduleSnapshot?) throws -> PowerEvent {
        let expression = try NSRegularExpression(
            pattern:
            #"^(wakepoweron|wakeorpoweron|poweron|wake|shutdown|sleep|restart) at (\d{1,2}:\d{2}(?::\d{2})?(?:AM|PM)?) (.+)$"#,
        )
        guard
            let match = expression.firstMatch(in: line, range: NSRange(line.startIndex..., in: line))
        else { throw unreadable() }
        func capture(_ index: Int) -> String {
            (line as NSString).substring(with: match.range(at: index))
        }
        let name = capture(1) == "wakepoweron" ? "wakeorpoweron" : capture(1)
        guard let kind = PowerEvent.Kind(rawValue: name) else { throw unreadable() }
        let parsedTime = try parseTime(capture(2))
        let days: String
        if capture(3) == "Some days" {
            guard let source = kind.isStartup ? supplemental?.startup : supplemental?.shutdown,
                  source.kind == kind, source.time == parsedTime
            else { throw unreadable() }
            days = source.days
        } else {
            days = try parseDays(capture(3))
        }
        return PowerEvent(
            kind: kind, days: days, time: parsedTime,
        )
    }

    private static func parseTime(_ value: String) throws -> ClockTime {
        let meridiem = value.hasSuffix("AM") ? "AM" : value.hasSuffix("PM") ? "PM" : nil
        let numbers = (meridiem == nil ? value : String(value.dropLast(2))).split(separator: ":")
        guard (2...3).contains(numbers.count), var hour = Int(numbers[0]), let minute = Int(numbers[1])
        else { throw unreadable() }
        let second = numbers.count == 3 ? Int(numbers[2]) : 0
        guard let second else { throw unreadable() }
        if let meridiem {
            guard (0...12).contains(hour), hour != 0 || meridiem == "AM" else { throw unreadable() }
            hour = hour % 12 + (meridiem == "PM" ? 12 : 0)
        }
        return try ClockTime(hour: hour, minute: minute, second: second)
    }

    private static func parseDays(_ value: String) throws -> String {
        let text = value.lowercased()
        if text == "every day" || text == "everyday" {
            return "MTWRFSU"
        }
        if text == "weekdays" || text == "weekdays only" {
            return "MTWRF"
        }
        if text == "weekends" || text == "weekends only" {
            return "SU"
        }
        let names = [
            "monday": "M", "tuesday": "T", "wednesday": "W", "thursday": "R", "friday": "F",
            "saturday": "S", "sunday": "U",
        ]
        let parts = text.replacingOccurrences(of: ",", with: " ").split(separator: " ").filter {
            $0 != "on" && $0 != "every" && $0 != "and"
        }
        var days = Set<String>()
        for part in parts {
            guard let day = names[String(part)] else { throw unreadable() }
            days.insert(day)
        }
        guard !days.isEmpty else { throw unreadable() }
        return "MTWRFSU".filter { days.contains(String($0)) }
    }

    private static func unreadable() -> ScheduleError {
        ScheduleError(
            .unreadableSchedule,
            "The system schedule could not be understood. No changes were made. Use pmset -g sched to inspect it.",
        )
    }
}
