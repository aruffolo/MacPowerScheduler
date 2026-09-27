import Foundation
@testable import PowerScheduleService
import Testing

struct GrantStoragePolicyTests {
    @Test(arguments: [mode_t(0o700), 0o500])
    func `private owned directory accepted`(_ permissions: mode_t) throws {
        try GrantStoragePolicy.validateDirectory(mode: S_IFDIR | permissions, owner: 42, expectedOwner: 42)
    }

    @Test(arguments: [mode_t(S_IFREG | 0o600), S_IFLNK | 0o700, S_IFDIR | 0o710, S_IFDIR | 0o701])
    func `invalid directory types and permissions rejected`(_ mode: mode_t) {
        #expect(throws: GrantStoragePolicy.unsafeStore()) {
            try GrantStoragePolicy.validateDirectory(mode: mode, owner: 42, expectedOwner: 42)
        }
    }

    @Test
    func `owners must match`() {
        #expect(throws: GrantStoragePolicy.unsafeStore()) {
            try GrantStoragePolicy.validateDirectory(mode: S_IFDIR | 0o700, owner: 41, expectedOwner: 42)
        }
        #expect(throws: GrantStoragePolicy.unsafeStore()) {
            try GrantStoragePolicy.validateFile(mode: S_IFREG | 0o600, owner: 41, expectedOwner: 42, size: 1)
        }
    }

    @Test(arguments: [off_t(0), 65536])
    func `file size boundaries`(_ size: off_t) throws {
        try GrantStoragePolicy.validateFile(mode: S_IFREG | 0o600, owner: 42, expectedOwner: 42, size: size)
    }

    @Test(arguments: [off_t(-1), 65537])
    func `invalid file sizes rejected`(_ size: off_t) {
        #expect(throws: GrantStoragePolicy.unsafeStore()) {
            try GrantStoragePolicy.validateFile(mode: S_IFREG | 0o600, owner: 42, expectedOwner: 42, size: size)
        }
    }

    @Test(arguments: [mode_t(S_IFDIR | 0o700), S_IFLNK | 0o600, S_IFIFO | 0o600, S_IFREG | 0o640, S_IFREG | 0o604])
    func `invalid file types and permissions rejected`(_ mode: mode_t) {
        #expect(throws: GrantStoragePolicy.unsafeStore()) {
            try GrantStoragePolicy.validateFile(mode: mode, owner: 42, expectedOwner: 42, size: 1)
        }
    }
}
