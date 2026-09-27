import Foundation
import PowerScheduleCore
import PowerScheduleIPC
@testable import PowerScheduleService
import PowerScheduleSystem
import Testing

/// Tests use isolated, lock-protected in-memory state. No test touches pmset writes.
final class MemoryBackend: ScheduleBackend, @unchecked Sendable {
    private let lock = NSLock()
    private var value = ScheduleSnapshot()
    func read() -> ScheduleSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func write(_ value: ScheduleSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        self.value = value
    }
}

final class MemoryGrants: GrantStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var values = Set<String>()
    func contains(_ account: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return values.contains(account)
    }

    func set(_ account: String, enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        if enabled {
            values.insert(account)
        } else {
            values.remove(account)
        }
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        values.removeAll()
    }
}

private final class FailedReadbackBackend: ScheduleBackend, @unchecked Sendable {
    private let lock = NSLock()
    private var written = false
    func read() throws -> ScheduleSnapshot {
        lock.lock()
        defer { lock.unlock() }
        if written {
            throw ScheduleError(.unreadableSchedule, "No changes were made")
        }
        return ScheduleSnapshot()
    }

    func write(_ value: ScheduleSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        written = true
    }
}

struct ServiceTests {
    @Test
    func `failed readback is explicitly uncertain`() throws {
        let service = ScheduleService(
            backend: FailedReadbackBackend(), grants: MemoryGrants(), authorize: { _ in },
        )
        let edit = try ScheduleEdit(
            startup: .set(ClockTime("07:00")), expectedRevision: ScheduleSnapshot().revision,
        )
        let result = service.handle(HelperRequest(action: .apply, edit: edit), account: "A")
        #expect(result.error?.code == .uncertainResult)
        #expect(result.error?.message.contains("may have changed") == true)
    }

    @Test
    func `permission is per account and revocation is immediate`() throws {
        let backend = MemoryBackend()
        let grants = MemoryGrants()
        let service = ScheduleService(backend: backend, grants: grants) { token in
            guard token == Data([1]) else { throw ScheduleError(.authorizationRequired, "denied") }
        }
        let edit = try ScheduleEdit(
            startup: .set(ClockTime("07:00")), expectedRevision: backend.read().revision,
        )
        #expect(
            service.handle(HelperRequest(action: .apply, edit: edit), account: "A").error?.code
                == .authorizationRequired,
        )
        #expect(
            service.handle(
                HelperRequest(action: .enableAutomation, authorization: Data([1])), account: "A",
            ).error == nil,
        )
        #expect(
            service.handle(HelperRequest(action: .apply, edit: edit), account: "B").error?.code
                == .authorizationRequired,
        )
        #expect(service.handle(HelperRequest(action: .apply, edit: edit), account: "A").error == nil)
        #expect(
            service.handle(
                HelperRequest(action: .disableAutomation, authorization: Data([1])), account: "A",
            ).error == nil,
        )
        #expect(
            service.handle(HelperRequest(action: .apply, edit: edit), account: "A").error?.code
                == .authorizationRequired,
        )
    }

    @Test
    func `concurrent stale edits cannot both succeed`() async throws {
        let backend = MemoryBackend()
        let grants = MemoryGrants()
        grants.set("A", enabled: true)
        let service = ScheduleService(backend: backend, grants: grants)
        let initial = backend.read().revision
        let results = try await withThrowingTaskGroup(of: HelperResponse.self) { group in
            for hour in [7, 8] {
                let edit = try ScheduleEdit(
                    startup: .set(ClockTime(hour: hour, minute: 0)), expectedRevision: initial,
                )
                group.addTask { service.handle(HelperRequest(action: .apply, edit: edit), account: "A") }
            }
            var result: [HelperResponse] = []
            for try await value in group {
                result.append(value)
            }
            return result
        }
        #expect(results.filter { $0.error == nil }.count == 1)
        #expect(results.filter { $0.error?.code == .conflict }.count == 1)
    }
}
