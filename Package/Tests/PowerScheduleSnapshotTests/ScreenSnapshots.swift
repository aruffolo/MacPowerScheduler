import AppKit
import PowerScheduleCore
import PowerScheduleIPC
@testable import PowerScheduleUI
import SnapshotTesting
import SwiftUI
import Testing

@Suite(.serialized) @MainActor
struct ScreenSnapshots {
    enum Scene: String, CaseIterable, Sendable {
        case empty, startupOnly, shutdownOnly, daily, automation, readOnly, approval, readError, replacement, conflict
        case setup, unavailable, dirty
    }

    enum Appearance: String, CaseIterable, Sendable {
        case light, dark
    }

    @Test(arguments: Scene.allCases, Appearance.allCases)
    func screen(scene: Scene, appearance: Appearance) async throws {
        _ = NSApplication.shared
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let model = try await makeModel(scene: scene, calendar: calendar)
        snapshot(
            ScheduleContentView(model: model),
            size: CGSize(width: 580, height: 1000),
            calendar: calendar,
            appearance: appearance,
            name: scene.rawValue,
            testName: "screen",
        )
    }

    @Test(arguments: [Scene.daily, .automation, .approval, .readOnly, .readError, .setup, .unavailable], Appearance.allCases)
    func settings(scene: Scene, appearance: Appearance) async throws {
        _ = NSApplication.shared
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let model = try await makeModel(scene: scene, calendar: calendar)
        snapshot(
            ScheduleSettingsView(model: model),
            size: CGSize(width: 520, height: 1000),
            calendar: calendar,
            appearance: appearance,
            name: scene.rawValue,
            testName: "settings",
        )
    }

    enum Layout: String, CaseIterable, Sendable {
        case reference, minimum, minimumExpanded, resized, longError
        var size: CGSize {
            switch self {
            case .reference: CGSize(width: 580, height: 684)
            case .minimum, .longError: CGSize(width: 520, height: 620)
            case .minimumExpanded: CGSize(width: 520, height: 800)
            case .resized: CGSize(width: 760, height: 800)
            }
        }
    }

    @Test(arguments: Scene.allCases, [CGFloat(520), CGFloat(580)])
    func `content fits window`(scene: Scene, width: CGFloat) async throws {
        _ = NSApplication.shared
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let model = try await makeModel(scene: scene, calendar: calendar)
        let host = NSHostingView(rootView: ScheduleContentView(model: model)
            .toolbar(.hidden, for: .windowToolbar)
            .environment(\.windowContentHeightLimit, 1400)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
            .frame(width: width))
        let window = try renderLayout(host)
        defer { window.close() }
        let scrolls = scrollViews(in: host)
        #expect(scrolls.isEmpty == false)
        for scroll in scrolls {
            scroll.scrollerStyle = .legacy
            scroll.tile()
            let document = try #require(scroll.documentView)
            #expect(document.bounds.height > 0)
            #expect(document.bounds.height <= scroll.contentSize.height + 1)
            #expect(scroll.verticalScroller?.isHidden != false)
        }
    }

    private func renderLayout(_ host: NSView) throws -> NSWindow {
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        host.layoutSubtreeIfNeeded()
        return window
    }

    private func scrollViews(in view: NSView) -> [NSScrollView] {
        (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap { scrollViews(in: $0) }
    }

    @Test(arguments: Scene.allCases)
    func `settings fit window`(scene: Scene) async throws {
        _ = NSApplication.shared
        let model = try await makeModel(scene: scene, calendar: Calendar(identifier: .gregorian))
        let host = NSHostingView(rootView: ScheduleSettingsView(model: model)
            .environment(\.windowContentHeightLimit, 1400))
        let window = try renderLayout(host)
        defer { window.close() }
        let scrolls = scrollViews(in: host)
        #expect(scrolls.isEmpty == false)
        for scroll in scrolls {
            scroll.scrollerStyle = .legacy
            scroll.tile()
            let document = try #require(scroll.documentView)
            #expect(document.bounds.height > 0)
            #expect(document.bounds.height <= scroll.contentSize.height + 1)
            #expect(scroll.verticalScroller?.isHidden != false)
        }
    }

    @Test
    func `short display retains scrolling in both screens`() async throws {
        _ = NSApplication.shared
        let model = try await makeModel(scene: .readError, calendar: Calendar(identifier: .gregorian))
        let main = NSHostingView(rootView: ScheduleContentView(model: model)
            .toolbar(.hidden, for: .windowToolbar)
            .environment(\.windowContentHeightLimit, 420).frame(width: 580))
        let settings = NSHostingView(rootView: ScheduleSettingsView(model: model)
            .environment(\.windowContentHeightLimit, 420))
        for host in [main as NSView, settings as NSView] {
            #expect(host.fittingSize.height <= 420)
            let window = try renderLayout(host)
            defer { window.close() }
            let scroll = try #require(scrollViews(in: host).first)
            let document = try #require(scroll.documentView)
            #expect(document.bounds.height > scroll.contentSize.height)
            document.scroll(NSPoint(x: 0, y: document.bounds.maxY))
            #expect(scroll.documentVisibleRect.maxY >= document.bounds.maxY - 1)
        }
    }

    @Test
    func `feedback changes the required height of both windows`() async throws {
        _ = NSApplication.shared
        let reader = SnapshotReader(snapshot: ScheduleSnapshot())
        let model = ScheduleModel(
            helper: SnapshotHelper(available: true, automation: false),
            platform: SnapshotPlatform(signingReady: true, registration: .enabled),
            read: { try await reader.read() },
        )
        await model.refresh()
        let main = NSHostingView(rootView: ScheduleContentView(model: model)
            .toolbar(.hidden, for: .windowToolbar)
            .environment(\.windowContentHeightLimit, 1400).frame(width: 580))
        let settings = NSHostingView(rootView: ScheduleSettingsView(model: model)
            .environment(\.windowContentHeightLimit, 1400))
        let hosts: [NSView] = [main, settings]
        let windows = try hosts.map(renderLayout)
        defer { windows.forEach { $0.close() } }
        let initialHeights = hosts.map(\.fittingSize.height)

        await reader.setReadFailure(true)
        await model.refresh()
        for (host, initialHeight) in zip(hosts, initialHeights) {
            host.needsLayout = true
            host.layoutSubtreeIfNeeded()
            #expect(host.fittingSize.height > initialHeight)
        }

        await reader.setReadFailure(false)
        await model.refresh()
        for (host, initialHeight) in zip(hosts, initialHeights) {
            host.needsLayout = true
            host.layoutSubtreeIfNeeded()
            #expect(host.fittingSize.height == initialHeight)
        }
    }

    @Test(arguments: Layout.allCases, Appearance.allCases)
    func layout(layout: Layout, appearance: Appearance) async throws {
        _ = NSApplication.shared
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.locale = Locale(identifier: "en_GB")
        let model = try await makeModel(
            scene: layout == .longError ? .readError : .dirty,
            calendar: calendar,
            readError: "The system schedule could not be read because the scheduling service is temporarily unavailable. Your existing power schedule has not been changed. Refresh to try again.",
        )
        snapshot(
            ScheduleContentView(model: model),
            size: layout.size,
            calendar: calendar,
            appearance: appearance,
            name: layout.rawValue,
            testName: "layout",
        )
    }

    private func snapshot(
        _ content: some View,
        size: CGSize,
        calendar: Calendar,
        appearance: Appearance,
        name: String,
        testName: String,
    ) {
        let view = content
            .environment(\.windowContentHeightLimit, size.height)
            .environment(\.locale, calendar.locale ?? Locale(identifier: "en_US_POSIX"))
            .environment(\.calendar, calendar)
            .environment(\.timeZone, calendar.timeZone)
            .environment(\.colorScheme, appearance == .light ? .light : .dark)
            .transaction { $0.animation = nil }
            .frame(width: size.width)
        let host = NSHostingView(rootView: view)
        host.appearance = NSAppearance(named: appearance == .light ? .aqua : .darkAqua)
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        host.layoutSubtreeIfNeeded()
        assertSnapshot(
            of: host as NSView,
            as: .image,
            named: "\(name)-\(appearance.rawValue)",
            record: ProcessInfo.processInfo.environment["MPS_RECORD_SNAPSHOTS"] == "1" ? .all : .never,
            testName: testName,
        )
    }

    private func makeModel(
        scene: Scene,
        calendar: Calendar,
        readError: String = "The system schedule could not be read. Refresh to try again.",
    ) async throws -> ScheduleModel {
        let startup = try PowerEvent(kind: .wakeorpoweron, time: ClockTime("07:30"))
        let shutdown = try PowerEvent(kind: .shutdown, time: ClockTime("23:00"))
        let snapshot: ScheduleSnapshot = switch scene {
        case .empty, .readOnly, .approval, .readError, .conflict, .setup, .unavailable: ScheduleSnapshot()
        case .startupOnly: ScheduleSnapshot(startup: startup)
        case .shutdownOnly: ScheduleSnapshot(shutdown: shutdown)
        case .daily, .automation: ScheduleSnapshot(startup: startup, shutdown: shutdown)
        case .dirty:
            try ScheduleSnapshot(startup: PowerEvent(kind: .wakeorpoweron, time: ClockTime("08:00")), shutdown: shutdown)
        case .replacement:
            try ScheduleSnapshot(startup: PowerEvent(kind: .wake, days: "MTWRF", time: ClockTime("06:45")))
        }
        let reader = SnapshotReader(snapshot: snapshot)
        let model = ScheduleModel(
            helper: SnapshotHelper(available: ![.approval, .setup, .unavailable].contains(scene), automation: scene == .automation),
            platform: SnapshotPlatform(signingReady: scene != .readOnly, registration: scene == .approval ? .requiresApproval : (scene == .setup ? .notRegistered : .enabled)),
            read: {
                if scene == .readError {
                    throw ScheduleError(.unreadableSchedule, readError)
                }
                return await reader.snapshot
            },
            calendar: calendar,
        )
        await model.refresh()
        if scene == .conflict {
            model.startupEnabled = true
            await reader.update(ScheduleSnapshot(shutdown: shutdown))
            await model.refresh()
            #expect(model.hasConflict)
        }
        if scene == .dirty {
            model.startupTime = try #require(calendar.date(bySettingHour: 7, minute: 30, second: 0, of: model.startupTime))
            #expect(model.isDirty)
        }
        return model
    }
}

private actor SnapshotReader {
    var snapshot: ScheduleSnapshot
    private var readFailure = false
    init(snapshot: ScheduleSnapshot) {
        self.snapshot = snapshot
    }

    func update(_ snapshot: ScheduleSnapshot) {
        self.snapshot = snapshot
    }

    func setReadFailure(_ value: Bool) {
        readFailure = value
    }

    func read() throws -> ScheduleSnapshot {
        if readFailure {
            throw ScheduleError(
                .unreadableSchedule,
                "The system schedule could not be read because the scheduling service is temporarily unavailable. Your existing power schedule has not been changed. Refresh to try again.",
            )
        }
        return snapshot
    }
}

private struct SnapshotHelper: HelperCalling {
    let available: Bool
    let automation: Bool
    func call(_ request: HelperRequest) throws -> HelperResponse {
        try #require(request.action == .status, "Snapshots must never request helper mutations.")
        guard available else { throw ScheduleError(.helperUnavailable, "The scheduling helper is unavailable. Try refreshing its status.") }
        return HelperResponse(automationEnabled: automation)
    }
}

@MainActor private struct SnapshotPlatform: SchedulingPlatform {
    let signingReady: Bool
    let registration: HelperRegistration
    func openSystemSettings() {
        Issue.record("Snapshots must not open System Settings.")
    }

    func register() throws {
        throw unexpectedMutation()
    }

    func unregister() async throws {
        throw unexpectedMutation()
    }

    func authorize() async throws -> AuthorizationLease {
        throw unexpectedMutation()
    }

    private func unexpectedMutation() -> ScheduleError {
        Issue.record("Snapshots must never register, remove, or authorize a helper.")
        return ScheduleError(.authorizationRequired, "Snapshot fixtures are read-only.")
    }
}
