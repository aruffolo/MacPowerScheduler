import PowerScheduleCore

enum SigningRequirement {
    static func validatedTeam(_ team: String) throws -> String {
        guard team.count == 10, team.allSatisfy({ $0.isASCII && ($0.isUppercase || $0.isNumber) }) else {
            throw unavailable()
        }
        return team
    }

    static func make(team: String, identifiers: [String]) throws -> String {
        let team = try validatedTeam(team)
        let allowed = Set([ServiceIdentity.app, ServiceIdentity.cli, ServiceIdentity.helper])
        guard !identifiers.isEmpty, identifiers.allSatisfy({ allowed.contains($0) }) else {
            throw unavailable()
        }
        let names = identifiers.map { "identifier \"\($0)\"" }.joined(separator: " or ")
        return "anchor apple generic and certificate leaf[subject.OU] = \"\(team)\" and (\(names))"
    }

    static func unavailable() -> ScheduleError {
        ScheduleError(
            .signingRequired,
            "Privileged operations require the app, helper, and CLI to use Apple-issued signing certificates from the same development team. This build supports read-only use.",
        )
    }
}
