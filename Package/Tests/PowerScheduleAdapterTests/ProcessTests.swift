import Foundation
import PowerScheduleCore
import PowerScheduleSystem
import Testing

struct ProcessTests {
    @Test
    func `process captures output and status`() throws {
        let output = try BoundedProcess().run(executable: "/usr/bin/printf", arguments: ["hello"])
        #expect(output.stdout == "hello")
        #expect(output.status == 0)
        let failed = try BoundedProcess().run(executable: "/usr/bin/false", arguments: [])
        #expect(failed.status != 0)
    }

    @Test
    func `process retains stderr and rejects oversized output`() throws {
        let output = try BoundedProcess().run(
            executable: "/usr/bin/awk", arguments: [#"BEGIN { print "failure" > "/dev/stderr"; exit 9 }"#],
        )
        #expect(output.stderr == "failure\n")
        #expect(output.status == 9)
        do {
            _ = try BoundedProcess().run(
                executable: "/usr/bin/awk", arguments: [#"BEGIN { for (i=0; i<1100000; i++) printf "x" }"#],
            )
            Issue.record("Oversized output unexpectedly succeeded")
        } catch let error as ScheduleError { #expect(error.code == .systemFailure) }
    }

    @Test
    func `process timeout is bounded`() {
        #expect(throws: ScheduleError.self) {
            try BoundedProcess().run(executable: "/bin/sleep", arguments: ["5"], timeout: 0.02)
        }
    }
}
