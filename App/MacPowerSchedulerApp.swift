import PowerScheduleUI
import SwiftUI

@main
struct MacPowerSchedulerApp: App {
    var body: some Scene {
        Window("MacPowerScheduler", id: "schedule") {
            PowerScheduleView()
        }
        .defaultSize(width: 580, height: 684)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .windowResizability(.contentSize)
    }
}
