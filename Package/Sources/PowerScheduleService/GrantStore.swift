import Foundation
import OpenDirectory
import PowerScheduleCore

public protocol GrantStoring: Sendable {
    func contains(_ account: String) throws -> Bool
    func set(_ account: String, enabled: Bool) throws
    func clear() throws
}

public struct AccountResolver: Sendable {
    public init() {}
    public func identifier(for uid: uid_t) throws -> String {
        let node = try ODNode(session: ODSession.default(), type: ODNodeType(kODNodeTypeAuthentication))
        let query = try ODQuery(
            node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeUniqueID,
            matchType: ODMatchType(kODMatchEqualTo), queryValues: String(uid),
            returnAttributes: kODAttributeTypeGUID, maximumResults: 1,
        )
        guard let records = try query.resultsAllowingPartial(false) as? [ODRecord],
              let record = records.first,
              let identifiers = try record.values(forAttribute: kODAttributeTypeGUID) as? [String],
              let identifier = identifiers.first, UUID(uuidString: identifier) != nil
        else {
            throw ScheduleError(.authorizationRequired, "The calling account could not be identified.")
        }
        return identifier
    }
}

/// Accessed only within the service's serial transaction queue.
public struct FileGrantStore: GrantStoring {
    private let directory: URL
    private let owner: uid_t
    public init(
        directory: URL = URL(fileURLWithPath: "/Library/Application Support/MacPowerScheduler"),
        owner: uid_t = 0,
    ) {
        self.directory = directory
        self.owner = owner
    }

    public func contains(_ account: String) throws -> Bool {
        try load().contains(account)
    }

    public func set(_ account: String, enabled: Bool) throws {
        var grants = try load()
        if enabled {
            grants.insert(account)
        } else {
            grants.remove(account)
        }
        try save(grants)
    }

    public func clear() throws {
        try save([])
    }

    private func validateDirectory(create: Bool) throws -> Bool {
        var info = stat()
        if lstat(directory.path, &info) != 0 {
            guard errno == ENOENT else { throw unsafeStore() }
            if !create {
                return false
            }
            guard mkdir(directory.path, 0o700) == 0 || errno == EEXIST else { throw unsafeStore() }
            guard lstat(directory.path, &info) == 0 else { throw unsafeStore() }
        }
        try GrantStoragePolicy.validateDirectory(mode: info.st_mode, owner: info.st_uid, expectedOwner: owner)
        return true
    }

    private func load() throws -> Set<String> {
        guard try validateDirectory(create: false) else { return [] }
        let path = directory.appendingPathComponent("automation.json").path
        let fd = open(path, O_RDONLY | O_NOFOLLOW)
        if fd < 0 {
            if errno == ENOENT {
                return []
            }
            throw unsafeStore()
        }
        defer { close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0 else { throw unsafeStore() }
        try GrantStoragePolicy.validateFile(mode: info.st_mode, owner: info.st_uid, expectedOwner: owner, size: info.st_size)
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
        let data = try handle.readToEnd() ?? Data()
        return try JSONDecoder().decode(Set<String>.self, from: data)
    }

    private func save(_ grants: Set<String>) throws {
        _ = try validateDirectory(create: true)
        let temporary = directory.appendingPathComponent(UUID().uuidString).path
        let fd = open(temporary, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw unsafeStore() }
        defer {
            close(fd)
            unlink(temporary)
        }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
        try handle.write(contentsOf: JSONEncoder().encode(grants.sorted()))
        try handle.synchronize()
        guard rename(temporary, directory.appendingPathComponent("automation.json").path) == 0 else {
            throw unsafeStore()
        }
    }

    private func unsafeStore() -> ScheduleError {
        GrantStoragePolicy.unsafeStore()
    }
}
