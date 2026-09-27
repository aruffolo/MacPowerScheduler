import Foundation
import PowerScheduleCore

/// Read-only supplemental metadata for pmset's lossy "Some days" label.
/// The storage path is documented in pmset(1); the schema is validated fail-closed.
enum RepeatingPreferences {
    private struct StoredEvent: Decodable {
        let eventtype: String
        let time: Int
        let weekdays: Int
        func event() throws -> PowerEvent {
            let name = eventtype == "wakepoweron" ? "wakeorpoweron" : eventtype
            guard let kind = PowerEvent.Kind(rawValue: name), (0..<1440).contains(time),
                  (1...127).contains(weekdays)
            else {
                throw ScheduleError(.unreadableSchedule, "Repeating schedule metadata is not recognized.")
            }
            let days = "MTWRFSU".enumerated().filter { weekdays & (1 << $0.offset) != 0 }.map {
                String($0.element)
            }.joined()
            return try PowerEvent(
                kind: kind, days: days, time: ClockTime(hour: time / 60, minute: time % 60),
            )
        }
    }

    private struct StoredPair: Decodable {
        enum CodingKeys: String, CodingKey {
            case repeatingPowerOn = "RepeatingPowerOn"
            case repeatingPowerOff = "RepeatingPowerOff"
        }

        let repeatingPowerOn: StoredEvent?
        let repeatingPowerOff: StoredEvent?
    }

    static func decode(_ data: Data) throws -> ScheduleSnapshot {
        guard data.count <= 1048576 else {
            throw ScheduleError(.unreadableSchedule, "Schedule metadata exceeds its size limit.")
        }
        let pair = try PropertyListDecoder().decode(StoredPair.self, from: data)
        let snapshot = try ScheduleSnapshot(
            startup: pair.repeatingPowerOn?.event(), shutdown: pair.repeatingPowerOff?.event(),
        )
        guard snapshot.startup?.kind.isStartup != false, snapshot.shutdown?.kind.isStartup != true
        else {
            throw ScheduleError(.unreadableSchedule, "Schedule metadata has inconsistent event types.")
        }
        return snapshot
    }
}
