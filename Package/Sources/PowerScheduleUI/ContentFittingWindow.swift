import AppKit
import SwiftUI

extension EnvironmentValues {
    @Entry var windowContentHeightLimit: CGFloat?
}

extension View {
    func contentFittingWindow() -> some View {
        modifier(ContentFittingWindow())
    }
}

private struct ContentFittingWindow: ViewModifier {
    @Environment(\.windowContentHeightLimit) private var heightOverride
    @State private var screenHeight = WindowHeightReader.initialHeight

    func body(content: Content) -> some View {
        content
            .frame(maxHeight: heightOverride ?? screenHeight)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                if heightOverride == nil {
                    WindowHeightReader { screenHeight = $0 }
                }
            }
    }
}

private struct WindowHeightReader: NSViewRepresentable {
    let updateHeight: (CGFloat) -> Void

    static var initialHeight: CGFloat {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1024, height: 768)
        return NSWindow.contentRect(forFrameRect: screenFrame, styleMask: .titled).height - 16
    }

    func makeNSView(context _: Context) -> HeightView {
        let view = HeightView()
        view.updateHeight = updateHeight
        return view
    }

    func updateNSView(_ view: HeightView, context _: Context) {
        view.updateHeight = updateHeight
        view.updateLimit()
    }

    final class HeightView: NSView {
        var updateHeight: (CGFloat) -> Void = { _ in }
        private var lastHeight: CGFloat?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // Observations belong to the attached window, which can change before this view is destroyed.
            // swiftlint:disable:next notification_center_detachment
            NotificationCenter.default.removeObserver(self)
            guard let window else { return }
            for name in [NSWindow.didChangeScreenNotification, NSWindow.didResizeNotification, NSWindow.didMoveNotification] {
                NotificationCenter.default.addObserver(self, selector: #selector(updateLimit), name: name, object: window)
            }
            NotificationCenter.default.addObserver(
                self, selector: #selector(updateLimit), name: NSApplication.didChangeScreenParametersNotification, object: nil,
            )
            updateLimit()
        }

        override func layout() {
            super.layout()
            updateLimit()
        }

        @objc
        func updateLimit() {
            guard let window, let screen = window.screen, bounds.height > 0 else { return }
            let top = window.sheetParent.map { $0.convertToScreen($0.contentLayoutRect).maxY } ?? screen.visibleFrame.maxY
            let chrome = max(0, window.frame.height - bounds.height)
            let height = max(1, floor(min(top, screen.visibleFrame.maxY) - screen.visibleFrame.minY - chrome - 16))
            guard height != lastHeight else { return }
            lastHeight = height
            // Publish after AppKit's layout pass; changing SwiftUI state inside it is undefined.
            Task { @MainActor [weak self] in
                guard let self, self.window != nil, self.lastHeight == height else { return }
                self.updateHeight(height)
            }
        }
    }
}
