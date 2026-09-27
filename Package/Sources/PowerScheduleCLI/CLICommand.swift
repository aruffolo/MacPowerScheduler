import Foundation
import PowerScheduleCore

public struct CLICommand: Sendable {
    public enum Action: Sendable { case help, status, doctor, edit }
    public let action: Action
    public let json: Bool
    public let startup: SideEdit
    public let shutdown: SideEdit
    public let replaceExisting: Bool
    public let revision: String?

    public init(arguments: [String]) throws {
        var args = arguments
        json = args.contains("--json")
        guard args.filter({ $0 == "--json" }).count <= 1 else {
            throw Self.invalid("Duplicate --json option.")
        }
        args.removeAll { $0 == "--json" }
        var edit = EditOptions()
        if args.isEmpty || args == ["--help"] || args == ["help"] || args == ["-h"] {
            action = .help
        } else if args == ["status"] {
            action = .status
        } else if args == ["doctor"] {
            action = .doctor
        } else {
            let command = args.removeFirst()
            guard command == "set" || command == "disable" else {
                throw Self.invalid("Unknown command. Use --help.")
            }
            action = .edit
            try edit.parse(command: command, arguments: args)
        }
        self.startup = edit.startup
        self.shutdown = edit.shutdown
        replaceExisting = edit.replace
        self.revision = edit.revision
    }

    private struct EditOptions {
        var startup: SideEdit = .preserve
        var shutdown: SideEdit = .preserve
        var replace = false
        var revision: String?
        mutating func parse(command: String, arguments: [String]) throws {
            var args = arguments
            if command == "disable" {
                try disableSide(args: &args)
            }
            var seen = Set<String>()
            while !args.isEmpty {
                let option = args.removeFirst()
                guard seen.insert(option).inserted else {
                    throw CLICommand.invalid("Duplicate option: \(option)")
                }
                try parseOption(option, command: command, args: &args)
            }
            guard startup != .preserve || shutdown != .preserve else {
                throw CLICommand.invalid("Specify at least one schedule change.")
            }
            if replace, startup == .preserve || shutdown == .preserve {
                throw CLICommand.invalid("Replacement requires both sides to be specified.")
            }
        }

        mutating func disableSide(args: inout [String]) throws {
            guard !args.isEmpty else { throw CLICommand.invalid("Specify startup, shutdown, or all.") }
            switch args.removeFirst() {
            case "startup": startup = .disable
            case "shutdown": shutdown = .disable
            case "all":
                startup = .disable
                shutdown = .disable
            default: throw CLICommand.invalid("Specify startup, shutdown, or all.")
            }
        }

        mutating func parseOption(_ option: String, command: String, args: inout [String]) throws {
            switch option {
            case "--startup", "--shutdown":
                try parseTime(option, command: command, args: &args)
            case "--no-startup" where command == "set":
                guard startup == .preserve else { throw CLICommand.invalid("Conflicting startup options.") }
                startup = .disable
            case "--no-shutdown" where command == "set":
                guard shutdown == .preserve else { throw CLICommand.invalid("Conflicting shutdown options.") }
                shutdown = .disable
            case "--replace-existing" where command == "set": replace = true
            case "--if-current":
                guard !args.isEmpty else { throw CLICommand.invalid("A revision is required.") }
                revision = args.removeFirst()
                guard revision?.count == 64, revision?.allSatisfy({ $0.isHexDigit && $0.isASCII }) == true
                else { throw CLICommand.invalid("Revision must be the SHA-256 value returned by status.") }
            default: throw CLICommand.invalid("Unknown option: \(option)")
            }
        }

        mutating func parseTime(_ option: String, command: String, args: inout [String]) throws {
            guard command == "set" else { throw CLICommand.invalid("Times are only accepted by set.") }
            guard !args.isEmpty else { throw CLICommand.invalid("A time is required after \(option).") }
            let time = try ClockTime(args.removeFirst())
            if option == "--startup" {
                guard startup == .preserve else { throw CLICommand.invalid("Conflicting startup options.") }
                startup = .set(time)
            } else {
                guard shutdown == .preserve else { throw CLICommand.invalid("Conflicting shutdown options.") }
                shutdown = .set(time)
            }
        }
    }

    private static func invalid(_ text: String) -> ScheduleError {
        ScheduleError(.invalidInput, text)
    }

    public static let help = """
    MacPowerScheduler — daily startup and shutdown
    
    powerschedulectl status [--json]
    powerschedulectl doctor [--json]
    powerschedulectl set [--startup HH:mm | --no-startup]
                         [--shutdown HH:mm | --no-shutdown]
                         [--replace-existing] [--if-current REVISION] [--json]
    powerschedulectl disable startup|shutdown|all [--if-current REVISION] [--json]
    
    Omitted sides are preserved. Explicit replacement requires both sides.
    Enable automation for your account in the app before noninteractive writes.
    Times use the Mac's local timezone. Status never changes settings.
    """
}
