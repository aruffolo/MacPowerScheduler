# SwiftUI testing in open-source projects

Inspected on 2026-09-27. These are findings from actual source and CI configuration, not claims that the referenced suites were run here. The user subsequently approved Point-Free snapshots and explicitly requested removal of app UI automation.

## What the projects test

| Project | Observed approach | What it proves |
|---|---|---|
| CodeEdit, native macOS | Wraps SwiftUI controls in `NSHostingView`, assigns fixed frames and Aqua/Dark Aqua appearances, and compares images using Point-Free's SnapshotTesting. Examples include help buttons, segmented controls and the branch picker. | Component appearance and layout against reviewed reference images. [Tests](https://github.com/CodeEditApp/CodeEdit/blob/main/CodeEditTests/Features/CodeEditUI/CodeEditUITests.swift) |
| CodeEdit, app interactions | Separate XCTest UI tests launch the application and query/click/type through `XCUIApplication`; terminal tests verify input and retained content. | Actual app wiring and user interactions beyond pixels. [Tests](https://github.com/CodeEditApp/CodeEdit/blob/main/CodeEditUITests/Features/UtilityArea/TerminalUtility/TerminalUtilityUITests.swift) |
| Kingfisher, iOS/tvOS SwiftUI | `KFImageRendererTests` hosts SwiftUI in a `UIHostingController` and window, measures layout through a geometry probe, and checks loading/error/animation behavior. Tests are guarded for UIKit and iOS/tvOS. | Real hosted component behavior, rather than only an image-loading model. This is an iOS pattern to adapt, not evidence of its macOS execution. [Tests](https://github.com/onevcat/Kingfisher/blob/master/Tests/KingfisherTests/KFImageRendererTests.swift) |
| Kingfisher, state/lifetime | `ImageBinderTests` directly tests binder state, callbacks, release while a request is in flight, priorities and stale results. | Logic and lifecycle behind the SwiftUI image. [Tests](https://github.com/onevcat/Kingfisher/blob/master/Tests/KingfisherTests/ImageBinderTests.swift) |
| Hwp-Swift, macOS | Tests pure coordination rules and binding changes, then mounts `HwpDocumentView` in `NSHostingView`, lays it out and checks the embedded native document view. | SwiftUI-to-AppKit binding propagation and document replacement behavior. [Tests](https://github.com/sboh1214/hwp-swift/blob/main/Tests/HwpKitTests/HwpDocumentViewTests.swift) |

The Sentry iOS coverage example is not a SwiftUI testing template: its inspected `CartViewControllerTests` exercises a UIKit controller with an injected session, and the displayed purchase test contains no active outcome assertions. Useful coverage tooling does not establish test quality. [Test source](https://github.com/sentry-demos/ios/blob/HEAD/EmpowerPlantTests/CartViewControllerTests.swift)

Point-Free's SnapshotTesting supports native `NSView` image comparisons on macOS and works with Swift Testing as well as XCTest. For our platform, use an `NSHostingView` with its AppKit image strategy; the inspected direct SwiftUI `UIImage` strategy is guarded for iOS/tvOS. Its macOS strategy explicitly requires comparison on the same OS as the reference capture. [NSView strategy](https://github.com/pointfreeco/swift-snapshot-testing/blob/main/Sources/SnapshotTesting/Snapshotting/NSView.swift), [SwiftUI strategy](https://github.com/pointfreeco/swift-snapshot-testing/blob/main/Sources/SnapshotTesting/Snapshotting/SwiftUIView.swift), [framework integration](https://github.com/pointfreeco/swift-snapshot-testing#usage).

## Adopted approach for MacPowerScheduler

The user authorized replacing the shallow app launch/control/screenshot test with Point-Free SnapshotTesting. Version 1.19.6 is pinned and linked only to `PowerScheduleSnapshotTests`; the upstream release was published on 2026-09-21 and supports Swift Testing and native macOS images. The maintained upstream package and CodeEdit's adoption support this choice. [Release](https://github.com/pointfreeco/swift-snapshot-testing/releases/tag/1.19.6), [package manifest](https://github.com/pointfreeco/swift-snapshot-testing/blob/1.19.6/Package.swift).

The shared SwiftUI content accepts an injected model; the app wrapper retains live refresh/foreground handling. Only the test harness uses `NSHostingView`. Fixed fixtures cover twenty light/dark images; calendar, time zone, locale, size and appearance are controlled. See [snapshot workflow and environment](README.md#swiftui-snapshots). Missing and mismatched references fail without rewriting them.

Fast Swift Testing unit coverage remains responsible for model actions, conflicts and scheduling policy. Snapshots protect rendered appearance; they do not prove Apply dispatch, packaged-app launch, authorization, keyboard navigation or accessibility. Those interactions remain in the manual release and attended signed-helper validation contracts. There is no remaining XCTest app automation target. Animated busy state and system confirmation dialogs are not claimed as snapshot coverage.
