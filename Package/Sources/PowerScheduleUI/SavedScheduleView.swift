import PowerScheduleCore
import SwiftUI

struct SavedScheduleView: View {
    @Environment(\.timeZone) private var timeZone
    let model: ScheduleModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Saved on this Mac").font(.system(size: 17, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise") { Task { await model.refresh() } }
                    .labelStyle(.iconOnly).buttonStyle(.borderless).foregroundStyle(.secondary)
                    .help("Refresh the system schedule").disabled(model.busy)
            }
            Text("These are the times currently scheduled in macOS.")
                .font(.system(size: 14)).foregroundStyle(.secondary)
            if let schedule = model.current {
                VStack(spacing: 14) {
                    eventRow("Startup", event: schedule.startup, isStartup: true, editable: schedule.isDailyEditable)
                    eventRow("Shutdown", event: schedule.shutdown, isStartup: false, editable: schedule.isDailyEditable)
                }.padding(.top, 14)
                if model.needsReplacement {
                    Text("Existing schedule requires explicit replacement to edit as a daily routine.")
                        .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
                }
            } else {
                Text("Schedule unavailable").foregroundStyle(.secondary).padding(.top, 14)
            }
        }
    }

    private func eventRow(_ title: String, event: PowerEvent?, isStartup: Bool, editable: Bool) -> some View {
        HStack(spacing: 20) {
            Image(systemName: isStartup ? "sun.max" : "moon.fill")
                .font(.system(size: 21)).foregroundStyle(isStartup ? AgendaPalette.sun : AgendaPalette.moon)
                .frame(width: 38).accessibilityHidden(true)
            Text(title).font(.system(size: 14, weight: .semibold)).frame(width: 88, alignment: .leading)
            if let event {
                if editable {
                    Text(model.date(event.time), style: .time).font(.system(size: 17)).monospacedDigit()
                        .frame(minWidth: 84, alignment: .leading)
                    Text("Every day · Local time").font(.system(size: 13)).foregroundStyle(.secondary)
                        .help(timeZone.identifier)
                } else {
                    Text(event.summary).font(.callout).fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Not scheduled").font(.callout).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
