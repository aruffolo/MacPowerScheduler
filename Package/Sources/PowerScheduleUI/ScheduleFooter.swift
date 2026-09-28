import SwiftUI

struct ScheduleFooter: View {
    @Environment(\.colorScheme) private var colorScheme
    let model: ScheduleModel
    let apply: () -> Void

    private var palette: AgendaPalette {
        AgendaPalette(scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 18) {
            if model.busy {
                ProgressView().controlSize(.small).frame(width: 26).accessibilityLabel("Working")
            } else {
                Image(systemName: statusIcon)
                    .font(.system(size: 23)).foregroundStyle(palette.accent).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(statusTitle).font(.system(size: 15, weight: .semibold)).foregroundStyle(palette.accent)
                Text(statusDetail).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: apply) {
                Text("Apply Schedule").font(.system(size: 15, weight: .semibold))
                    .frame(width: 166, height: 40)
            }
            .buttonStyle(AgendaApplyStyle())
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!model.canApply)
            .accessibilityIdentifier("applySchedule")
        }
        .padding(.horizontal, 30).padding(.vertical, 20)
        .frame(minHeight: 80)
        .background(palette.footer)
        .overlay(alignment: .top) { Divider() }
    }

    private var statusTitle: String {
        if model.busy {
            return "Working…"
        }
        if model.current == nil {
            return "Schedule unavailable"
        }
        if model.hasConflict {
            return "Review system changes"
        }
        if model.needsReplacement {
            return "Existing schedule"
        }
        return model.isDirty ? "Unsaved changes" : "Saved schedule"
    }

    private var statusDetail: String {
        if model.current == nil {
            return "Refresh to try again."
        }
        if model.hasConflict {
            return "Reload before applying."
        }
        if model.needsReplacement {
            return "Apply requires replacement."
        }
        return model.isDirty ? "Apply to update the system schedule." : "Your routine is up to date."
    }

    private var statusIcon: String {
        if model.current == nil || model.hasConflict {
            return "exclamationmark.circle"
        }
        return model.isDirty || model.needsReplacement ? "info.circle" : "checkmark.circle"
    }
}

private struct AgendaApplyStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? .white : .secondary)
            .background(isEnabled ? AgendaPalette.button : Color.secondary.opacity(0.12), in: .rect(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
