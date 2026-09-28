import SwiftUI

struct AgendaTimePicker: NSViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) private var timeZone
    let title: String
    @Binding var selection: Date

    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = .textFieldAndStepper
        picker.datePickerElements = .hourMinute
        picker.font = .systemFont(ofSize: 22)
        picker.isBezeled = false
        picker.isBordered = false
        picker.drawsBackground = false
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.changed(_:))
        picker.setContentHuggingPriority(.required, for: .horizontal)
        return picker
    }

    func updateNSView(_ picker: NSDatePicker, context: Context) {
        context.coordinator.selection = $selection
        picker.locale = locale
        picker.calendar = calendar
        picker.timeZone = timeZone
        picker.isEnabled = isEnabled
        picker.setAccessibilityLabel(title)
        if picker.dateValue != selection {
            picker.dateValue = selection
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSDatePicker, context: Context) -> CGSize? {
        CGSize(width: max(118, nsView.fittingSize.width), height: nsView.fittingSize.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    @MainActor final class Coordinator: NSObject {
        var selection: Binding<Date>
        init(selection: Binding<Date>) {
            self.selection = selection
        }

        @objc
        func changed(_ sender: NSDatePicker) {
            selection.wrappedValue = sender.dateValue
        }
    }
}
