import Foundation

public enum SideEdit: Codable, Equatable, Sendable {
    case preserve, disable
    case set(ClockTime)
}

public struct ScheduleEdit: Codable, Equatable, Sendable {
    public var startup: SideEdit
    public var shutdown: SideEdit
    public var replaceExisting: Bool
    public let expectedRevision: String
    public init(
        startup: SideEdit = .preserve, shutdown: SideEdit = .preserve, replaceExisting: Bool = false,
        expectedRevision: String,
    ) {
        self.startup = startup
        self.shutdown = shutdown
        self.replaceExisting = replaceExisting
        self.expectedRevision = expectedRevision
    }

    public func resolve(against current: ScheduleSnapshot) throws -> ScheduleSnapshot {
        guard expectedRevision == current.revision else {
            throw ScheduleError(
                .conflict, "The system schedule changed. Refresh and review before applying again.",
            )
        }
        guard startup != .preserve || shutdown != .preserve else {
            throw ScheduleError(.invalidInput, "Specify at least one schedule change.")
        }
        if !current.isDailyEditable,
           !(replaceExisting && startup != .preserve && shutdown != .preserve) {
            throw ScheduleError(
                .replacementRequired,
                "This schedule cannot be edited as a daily pair. Specify both sides and explicitly replace the existing schedule.",
            )
        }
        func event(_ edit: SideEdit, old: PowerEvent?, kind: PowerEvent.Kind) throws -> PowerEvent? {
            switch edit {
            case .preserve: return old
            case .disable: return nil
            case .set(let time):
                guard try time.validated().second == 0 else {
                    throw ScheduleError(.invalidInput, "New times use minute precision.")
                }
                return PowerEvent(kind: kind, time: time)
            }
        }
        let result = try ScheduleSnapshot(
            startup: event(startup, old: current.startup, kind: .wakeorpoweron),
            shutdown: event(shutdown, old: current.shutdown, kind: .shutdown),
        )
        if let on = result.startup, let off = result.shutdown, on.time == off.time {
            throw ScheduleError(.invalidInput, "Startup and shutdown must use different times.")
        }
        return result
    }

    public static func arguments(for schedule: ScheduleSnapshot) throws -> [String] {
        guard schedule.isDailyEditable else {
            throw ScheduleError(
                .invalidInput, "Only daily wake-or-power-on and shutdown schedules can be written.",
            )
        }
        var result = ["repeat"]
        for event in [schedule.startup, schedule.shutdown].compactMap(\.self) {
            _ = try event.time.validated()
            result += [event.kind.rawValue, event.days, event.time.argument]
        }
        return result.count == 1 ? ["repeat", "cancel"] : result
    }
}
