import Foundation
import PowerScheduleCLI

let output = await CLIRunner().run(Array(CommandLine.arguments.dropFirst()))
FileHandle.standardOutput.write(Data(output.stdout.utf8))
FileHandle.standardError.write(Data(output.stderr.utf8))
exit(output.exitCode)
