import Foundation
@testable import PowerScheduleCLI
import PowerScheduleCore
import PowerScheduleIPC
import Testing

struct CommandMatrixTests {
    @Test(arguments: [[], ["help"], ["--help"], ["-h"], ["--json", "help"]])
    func `help aliases`(_ arguments: [String]) throws {
        let command = try CLICommand(arguments: arguments)
        if case .help = command.action {} else {
            Issue.record("Expected help")
        }
        #expect(command.startup == .preserve)
        #expect(command.shutdown == .preserve)
    }

    @Test(arguments: [
        ["status", "--json", "--json"], ["set", "--no-startup", "--no-startup"], ["disable"],
        ["set", "--startup"], ["set", "--shutdown"], ["disable", "all", "--startup", "07:00"],
        ["set", "--no-startup", "--startup", "07:00"], ["set", "--shutdown", "23:00", "--no-shutdown"],
        ["set", "--no-shutdown", "--shutdown", "23:00"], ["disable", "all", "--no-startup"],
        ["disable", "all", "--if-current"], ["disable", "all", "--if-current", "bad"],
        ["set", "--no-startup", "--if-current", String(repeating: "z", count: 64)],
    ])
    func `invalid options`(_ arguments: [String]) {
        do {
            _ = try CLICommand(arguments: arguments)
            Issue.record("Invalid input accepted: \(arguments)")
        } catch let error as ScheduleError { #expect(error.code == .invalidInput) } catch { Issue.record(error) }
    }

    @Test(arguments: [("startup", SideEdit.disable, SideEdit.preserve), ("shutdown", .preserve, .disable), ("all", .disable, .disable)])
    func `disable sides`(_ side: String, _ startup: SideEdit, _ shutdown: SideEdit) throws {
        let revision = String(repeating: "a", count: 64)
        let command = try CLICommand(arguments: ["disable", side, "--if-current", revision])
        #expect(command.startup == startup)
        #expect(command.shutdown == shutdown)
        #expect(command.revision == revision)
    }

    @Test
    func `complete replacement`() throws {
        let command = try CLICommand(arguments: ["set", "--no-startup", "--shutdown", "23:00", "--replace-existing"])
        #expect(command.startup == .disable)
        #expect(try command.shutdown == .set(ClockTime("23:00")))
        #expect(command.replaceExisting)
        let disabled = try CLICommand(arguments: ["set", "--no-startup", "--no-shutdown"])
        #expect(disabled.shutdown == .disable)
    }
}

private actor RecordingHelper: HelperCalling {
    var requests: [HelperRequest] = []
    let response: HelperResponse
    init(_ response: HelperResponse) {
        self.response = response
    }

    func call(_ request: HelperRequest) -> HelperResponse {
        requests.append(request)
        return response
    }
}

struct RunnerMatrixTests {
    @Test(arguments: [false, true])
    func `help does no IO`(_ json: Bool) async throws {
        let helper = RecordingHelper(HelperResponse())
        let runner = CLIRunner(helper: helper, read: { Issue.record("Help read system state"); return ScheduleSnapshot() })
        let output = await runner.run(json ? ["--help", "--json"] : ["--help"])
        #expect(output.exitCode == 0)
        #expect(output.stderr.isEmpty)
        #expect(await helper.requests.isEmpty)
        if json {
            #expect(try JSONDecoder().decode([String: String].self, from: Data(output.stdout.utf8))["help"] == CLICommand.help)
        } else {
            #expect(output.stdout == CLICommand.help + "\n")
        }
    }

    @Test(arguments: [false, true])
    func `doctor reports grant`(_ enabled: Bool) async {
        let helper = RecordingHelper(HelperResponse(automationEnabled: enabled))
        let runner = CLIRunner(helper: helper, read: { Issue.record("Doctor used direct reader"); return ScheduleSnapshot() })
        let output = await runner.run(["doctor"])
        #expect(output.stdout == "Automation: \(enabled ? "Enabled" : "Disabled")\n")
        #expect(output.exitCode == 0)
        #expect(await helper.requests.first?.action == .status)
    }

    @Test
    func `status human output`() async throws {
        let snapshot = try ScheduleSnapshot(startup: PowerEvent(kind: .wakeorpoweron, time: ClockTime("07:00")))
        let helper = RecordingHelper(HelperResponse())
        let output = await CLIRunner(helper: helper, read: { snapshot }).run(["status"])
        #expect(output.stdout == "Startup: Wake or power on · Every day at 07:00\nShutdown: Not scheduled\nRevision: \(snapshot.revision)\n")
        #expect(await helper.requests.isEmpty)
    }

    @Test
    func `edit carries revision and partial intent`() async throws {
        let snapshot = try ScheduleSnapshot(shutdown: PowerEvent(kind: .shutdown, time: ClockTime("23:00")))
        let helper = RecordingHelper(HelperResponse(schedule: snapshot))
        let runner = CLIRunner(helper: helper, read: { snapshot })
        let output = await runner.run(["set", "--startup", "07:00", "--if-current", snapshot.revision, "--json"])
        let request = try #require(await helper.requests.first)
        #expect(request.action == .apply)
        #expect(request.edit?.expectedRevision == snapshot.revision)
        #expect(request.edit?.shutdown == .preserve)
        #expect(request.authorization == nil)
        #expect(output.exitCode == 0)
        #expect(try JSONDecoder().decode(HelperResponse.self, from: Data(output.stdout.utf8)).schedule == snapshot)
    }

    @Test
    func `stale revision never reaches helper`() async {
        let helper = RecordingHelper(HelperResponse())
        let output = await CLIRunner(helper: helper, read: { ScheduleSnapshot() }).run([
            "disable", "all", "--if-current", String(repeating: "0", count: 64),
        ])
        #expect(output.exitCode == 5)
        #expect(output.stdout.isEmpty)
        #expect(output.stderr.contains("changed"))
        #expect(await helper.requests.isEmpty)
    }

    @Test(arguments: [false, true])
    func `returned errors are checked`(_ json: Bool) async throws {
        let helper = RecordingHelper(HelperResponse(error: ScheduleError(.authorizationRequired, "denied")))
        let output = await CLIRunner(helper: helper, read: { ScheduleSnapshot() }).run(json ? ["doctor", "--json"] : ["doctor"])
        #expect(output.exitCode == 3)
        if json {
            #expect(output.stderr.isEmpty)
            #expect(try JSONDecoder().decode(HelperResponse.self, from: Data(output.stdout.utf8)).error?.message == "denied")
        } else {
            #expect(output.stdout.isEmpty); #expect(output.stderr == "denied\n")
        }
    }

    @Test
    func `read failure stops mutation`() async {
        let helper = RecordingHelper(HelperResponse())
        let output = await CLIRunner(helper: helper, read: { throw ScheduleError(.unreadableSchedule, "unknown") }).run(["disable", "all"])
        #expect(output.exitCode == 6)
        #expect(output.stderr == "unknown\n")
        #expect(await helper.requests.isEmpty)
    }
}
