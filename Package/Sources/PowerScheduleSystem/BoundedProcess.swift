import Foundation
import PowerScheduleCore

/// Lock protects buffer/EOF state written by Foundation's pipe callbacks.
private final class CaptureBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    private var overflow = false
    let ended = DispatchSemaphore(value: 0)
    func append(_ bytes: Data) {
        lock.lock()
        defer { lock.unlock() }
        let remaining = max(0, 1048576 - data.count)
        data.append(bytes.prefix(remaining))
        if bytes.count > remaining {
            overflow = true
        }
    }

    func result() -> (Data, Bool) {
        lock.lock()
        defer { lock.unlock() }
        return (data, overflow)
    }
}

public struct ProcessOutput: Sendable {
    public let stdout: String
    public let stderr: String
    public let status: Int32
}

public struct BoundedProcess: Sendable {
    public init() {}
    public func run(executable: String, arguments: [String], timeout: TimeInterval = 10) throws
        -> ProcessOutput {
        let process = Process()
        let output = Pipe()
        let errors = Pipe()
        let captured = CaptureBuffer()
        let capturedErrors = CaptureBuffer()
        Self.capture(output, into: captured)
        Self.capture(errors, into: capturedErrors)
        defer {
            output.fileHandleForReading.readabilityHandler = nil
            errors.fileHandleForReading.readabilityHandler = nil
            try? output.fileHandleForReading.close()
            try? errors.fileHandleForReading.close()
        }
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL": "C", "LANG": "C"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = output
        process.standardError = errors
        let ended = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in ended.signal() }
        try process.run()
        try Self.wait(for: process, ended: ended, timeout: timeout)
        return try Self.output(captured, errors: capturedErrors, status: process.terminationStatus)
    }

    private static func capture(_ pipe: Pipe, into capture: CaptureBuffer) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let bytes = handle.availableData
            if bytes.isEmpty {
                handle.readabilityHandler = nil
                capture.ended.signal()
            } else {
                capture.append(bytes)
            }
        }
    }

    private static func wait(for process: Process, ended: DispatchSemaphore, timeout: TimeInterval) throws {
        if ended.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            if ended.wait(timeout: .now() + 1) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = ended.wait(timeout: .now() + 1)
            }
            throw ScheduleError(
                .uncertainResult, "The system operation timed out. Refresh the schedule before retrying.",
            )
        }
    }

    private static func output(_ captured: CaptureBuffer, errors capturedErrors: CaptureBuffer, status: Int32) throws -> ProcessOutput {
        guard captured.ended.wait(timeout: .now() + 2) == .success,
              capturedErrors.ended.wait(timeout: .now() + 2) == .success
        else {
            throw ScheduleError(.systemFailure, "System output did not finish.")
        }
        let (bytes, overflow) = captured.result()
        let (errorBytes, errorOverflow) = capturedErrors.result()
        guard !overflow, !errorOverflow, let stdout = String(data: bytes, encoding: .utf8),
              let stderr = String(data: errorBytes, encoding: .utf8)
        else {
            throw ScheduleError(.systemFailure, "System output exceeded its limit or was not UTF-8.")
        }
        return ProcessOutput(stdout: stdout, stderr: stderr, status: status)
    }
}
