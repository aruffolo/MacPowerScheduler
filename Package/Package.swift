// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MacPowerScheduler",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HelperIntegrationProbe", targets: ["HelperIntegrationProbe"]),
        .library(name: "PowerScheduleUI", targets: ["PowerScheduleUI"]),
        .library(name: "PowerScheduleService", targets: ["PowerScheduleService"]),
        .library(name: "PowerScheduleCLI", targets: ["PowerScheduleCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.6"),
    ],
    targets: [
        .executableTarget(
            name: "HelperIntegrationProbe", dependencies: ["PowerScheduleIPC", "PowerScheduleCore"],
            path: "Tests/HelperIntegrationProbe",
        ),
        .target(name: "PowerScheduleCore"),
        .target(name: "PowerScheduleSystem", dependencies: ["PowerScheduleCore"]),
        .target(name: "PowerScheduleIPC", dependencies: ["PowerScheduleCore"]),
        .target(
            name: "PowerScheduleService",
            dependencies: ["PowerScheduleCore", "PowerScheduleSystem", "PowerScheduleIPC"],
        ),
        .target(
            name: "PowerScheduleUI",
            dependencies: ["PowerScheduleCore", "PowerScheduleSystem", "PowerScheduleIPC"],
        ),
        .target(
            name: "PowerScheduleCLI",
            dependencies: ["PowerScheduleCore", "PowerScheduleSystem", "PowerScheduleIPC"],
        ),
        .testTarget(
            name: "PowerScheduleSnapshotTests",
            dependencies: [
                "PowerScheduleUI", "PowerScheduleCore", "PowerScheduleIPC",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"],
        ),
        .testTarget(name: "PowerScheduleCoreTests", dependencies: ["PowerScheduleCore"]),
        .testTarget(name: "PowerScheduleSystemTests", dependencies: ["PowerScheduleSystem"]),
        .testTarget(name: "PowerScheduleServiceTests", dependencies: ["PowerScheduleService"]),
        .testTarget(name: "PowerScheduleUITests", dependencies: ["PowerScheduleUI"]),
        .testTarget(name: "PowerScheduleCLITests", dependencies: ["PowerScheduleCLI"]),
        .testTarget(name: "PowerScheduleIPCTests", dependencies: ["PowerScheduleIPC"]),
        .testTarget(name: "PowerScheduleAdapterTests", dependencies: ["PowerScheduleSystem", "PowerScheduleService"]),
    ],
    swiftLanguageModes: [.v6],
)
