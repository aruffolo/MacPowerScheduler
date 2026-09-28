import SwiftUI

struct AgendaEventRow: View {
    @Environment(\.timeZone) private var timeZone
    let title: String
    let detail: String
    let isStartup: Bool
    @Binding var enabled: Bool
    @Binding var time: Date

    var body: some View {
        HStack(alignment: .top, spacing: 34) {
            Image(systemName: isStartup ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 29, weight: .regular))
                .foregroundStyle(isStartup ? AgendaPalette.sun : .white)
                .frame(width: 54, height: 54)
                .background(isStartup ? Color(red: 1, green: 0.94, blue: 0.77) : AgendaPalette.moon, in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.system(size: 22, weight: .bold))
                Text(detail).font(.system(size: 15)).foregroundStyle(.secondary).padding(.top, 2)
                AgendaTimePicker(title: title + " time", selection: $time)
                    .padding(.horizontal, 12).frame(height: 38)
                    .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 10))
                    .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.secondary.opacity(0.2)) }
                    .fixedSize().disabled(!enabled)
                    .padding(.top, 10)
                Text("Repeats every day · Local time")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                    .padding(.top, 8).help(timeZone.identifier)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(title, isOn: $enabled)
                .labelsHidden().toggleStyle(.switch).controlSize(.large)
                .padding(.top, 8).accessibilityLabel(title)
        }
        .frame(height: 126, alignment: .top)
    }
}
