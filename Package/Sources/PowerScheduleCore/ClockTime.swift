import Foundation

public struct ClockTime: Codable, Equatable, Sendable {
    public let hour: Int
    public let minute: Int
    public let second: Int
    public init(hour: Int, minute: Int, second: Int = 0) throws {
        guard (0...23).contains(hour), (0...59).contains(minute), (0...59).contains(second) else {
            throw ScheduleError(.invalidInput, "Time must be between 00:00 and 23:59.")
        }
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    public init(_ text: String) throws {
        let pieces = text.split(separator: ":", omittingEmptySubsequences: false)
        guard pieces.count == 2,
              pieces.allSatisfy({ $0.count == 2 && $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let hour = Int(pieces[0]), let minute = Int(pieces[1])
        else {
            throw ScheduleError(.invalidInput, "Use a 24-hour time in HH:mm format.")
        }
        try self.init(hour: hour, minute: minute)
    }

    public var text: String {
        String(format: "%02d:%02d", hour, minute)
    }

    public var argument: String {
        String(format: "%02d:%02d:%02d", hour, minute, second)
    }

    public func validated() throws -> Self {
        try Self(hour: hour, minute: minute, second: second)
    }
}
