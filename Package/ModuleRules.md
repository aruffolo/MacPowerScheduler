# Module boundaries

Core owns values and pure scheduling policy. System owns fixed-path process I/O and parsing. IPC owns typed requests and client authentication. Service owns privileged policy and storage. UI and CLI share core values and injected clients; neither executes privileged commands directly. Executable entry points remain thin. No global service locator or third-party runtime dependencies. Point-Free SnapshotTesting is approved only for the snapshot test target; its NSHostingView harness stays in tests. Production views remain SwiftUI.
