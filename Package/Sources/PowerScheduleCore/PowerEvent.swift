import Foundation

public struct PowerEvent: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case wake, poweron, wakeorpoweron, shutdown, sleep, restart
        public var isStartup: Bool {
            self == .wake || self == .poweron || self == .wakeorpoweron
        }
    }

    public let kind: Kind
    public let days: String
    public let time: ClockTime
    public init(kind: Kind, days: String = "MTWRFSU", time: ClockTime) {
        self.kind = kind
        self.days = days
        self.time = time
    }

    public var summary: String {
        let repetition =
            days == "MTWRFSU"
                ? "Every day" : (days == "MTWRF" ? "Weekdays" : (days == "SU" ? "Weekends" : days))
        let displayTime = time.second == 0 ? time.text : time.argument
        let eventName = kind == .wakeorpoweron ? "Wake or power on" : kind.rawValue.capitalized
        return "\(eventName) · \(repetition) at \(displayTime)"
    }
}
