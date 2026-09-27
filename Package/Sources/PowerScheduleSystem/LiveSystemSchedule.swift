import Foundation
import PowerScheduleCore

extension SystemSchedule {
    public init() {
        self.init(
            run: { try BoundedProcess().run(executable: "/usr/bin/pmset", arguments: $0) },
            readMetadata: Self.readRepeatingMetadata,
            isRoot: { geteuid() == 0 },
        )
    }

    private static func readRepeatingMetadata() throws -> Data {
        let file = try FileHandle(
            forReadingFrom: URL(fileURLWithPath: "/Library/Preferences/SystemConfiguration/com.apple.AutoWake.plist"),
        )
        defer { try? file.close() }
        let data = try file.read(upToCount: 1048577) ?? Data()
        guard data.count <= 1048576 else {
            throw ScheduleError(.unreadableSchedule, "Schedule metadata exceeds its size limit.")
        }
        return data
    }
}
