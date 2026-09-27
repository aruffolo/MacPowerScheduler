import Foundation
import PowerScheduleCore
import Security

public enum SigningPolicy {
    public static func teamIdentifier() throws -> String {
        var ownCode: SecCode?
        guard SecCodeCopySelf([], &ownCode) == errSecSuccess, let ownCode else { throw unavailable() }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(ownCode, [], &staticCode) == errSecSuccess, let staticCode else {
            throw unavailable()
        }
        var information: CFDictionary?
        guard
            SecCodeCopySigningInformation(
                staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &information,
            ) == errSecSuccess,
            let dictionary = information as? [String: Any],
            let team = dictionary[kSecCodeInfoTeamIdentifier as String] as? String
        else { throw unavailable() }
        return try SigningRequirement.validatedTeam(team)
    }

    public static func requirement(identifiers: [String]) throws -> String {
        try SigningRequirement.make(team: teamIdentifier(), identifiers: identifiers)
    }

    private static func unavailable() -> ScheduleError {
        SigningRequirement.unavailable()
    }
}
