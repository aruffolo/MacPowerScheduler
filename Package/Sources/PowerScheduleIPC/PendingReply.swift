import Foundation

/// A lock guards the one-shot continuation shared by XPC error/reply/timeout callbacks.
final class PendingReply: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data, Error>?
    init(_ continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    func finish(_ result: Result<Data, Error>) {
        lock.lock()
        let saved = continuation
        continuation = nil
        lock.unlock()
        saved?.resume(with: result)
    }
}
