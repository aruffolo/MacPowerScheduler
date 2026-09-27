import Foundation
import PowerScheduleCore

enum GrantStoragePolicy {
    static func validateDirectory(mode: mode_t, owner: uid_t, expectedOwner: uid_t) throws {
        guard mode & S_IFMT == S_IFDIR, owner == expectedOwner, mode & 0o077 == 0 else {
            throw unsafeStore()
        }
    }

    static func validateFile(mode: mode_t, owner: uid_t, expectedOwner: uid_t, size: off_t) throws {
        guard mode & S_IFMT == S_IFREG, owner == expectedOwner, mode & 0o077 == 0,
              (0...65536).contains(size) else { throw unsafeStore() }
    }

    static func unsafeStore() -> ScheduleError {
        ScheduleError(
            .systemFailure,
            "Automation permission storage is unavailable or has unsafe ownership/permissions.",
        )
    }
}
