import CryptoKit
import Foundation

public struct ScheduleSnapshot: Codable, Equatable, Sendable {
    public let startup: PowerEvent?
    public let shutdown: PowerEvent?
    public init(startup: PowerEvent? = nil, shutdown: PowerEvent? = nil) {
        self.startup = startup
        self.shutdown = shutdown
    }

    public var isDailyEditable: Bool {
        (startup.map { $0.kind == .wakeorpoweron && $0.days == "MTWRFSU" && $0.time.second == 0 }
            ?? true)
            && (shutdown.map { $0.kind == .shutdown && $0.days == "MTWRFSU" && $0.time.second == 0 }
                ?? true)
    }

    public var revision: String {
        let parts = [startup, shutdown].map { event in
            event.map { "\($0.kind.rawValue)|\($0.days)|\($0.time.argument)" } ?? "none"
        }
        return SHA256.hash(data: Data(parts.joined(separator: ";").utf8)).map {
            String(format: "%02x", $0)
        }.joined()
    }
}
