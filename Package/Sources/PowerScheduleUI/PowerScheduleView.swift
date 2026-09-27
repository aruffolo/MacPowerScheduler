import SwiftUI

public struct PowerScheduleView: View {
    @State private var model = ScheduleModel()
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ScheduleContentView(model: model)
            .task { await model.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await model.refresh() }
                }
            }
    }
}
