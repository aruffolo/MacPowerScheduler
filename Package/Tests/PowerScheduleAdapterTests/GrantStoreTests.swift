import Foundation
import PowerScheduleService
import Testing

struct GrantStoreTests {
    @Test
    func `grants persist and reject unsafe permissions`() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileGrantStore(directory: directory, owner: getuid())
        #expect(try store.contains("A") == false)
        try store.set("A", enabled: true)
        #expect(try FileGrantStore(directory: directory, owner: getuid()).contains("A"))
        try store.clear()
        #expect(try store.contains("A") == false)
        try FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: directory.path)
        #expect(throws: Error.self) { try store.contains("A") }
    }
}
