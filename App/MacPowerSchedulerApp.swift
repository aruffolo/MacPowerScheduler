import PowerScheduleUI
import SwiftUI

@main
struct MacPowerSchedulerApp: App {
    var body: some Scene {
        Window("MacPowerScheduler", id: "schedule") {
            PowerScheduleView()
        }
        .defaultSize(width: 560, height: 710)
        .windowResizability(.contentMinSize)
    }
}
