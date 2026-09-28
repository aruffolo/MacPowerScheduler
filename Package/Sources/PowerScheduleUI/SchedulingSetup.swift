public enum SchedulingSetup: Equatable, Sendable {
    case checking, readOnly, registrationRequired, approvalRequired, ready
    case unavailable(String)

    public var message: String {
        switch self {
        case .checking: "Checking scheduling access…"
        case .readOnly: "Read-only development build. Sign the app to enable scheduling."
        case .registrationRequired: "Enable power scheduling to save your daily routine."
        case .approvalRequired: "Approve Power Scheduling in System Settings → Login Items."
        case .ready: "Power scheduling is enabled."
        case let .unavailable(message): message
        }
    }

    public var actionTitle: String? {
        switch self {
        case .registrationRequired: "Enable Power Scheduling"
        case .approvalRequired: "Open System Settings"
        case .unavailable: "Retry"
        case .checking, .readOnly, .ready: nil
        }
    }
}
