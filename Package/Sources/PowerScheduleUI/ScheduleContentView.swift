import ServiceManagement
import SwiftUI

struct ScheduleContentView: View {
    @Bindable var model: ScheduleModel
    @State private var confirmReplacement = false
    @State private var confirmAutomation = false
    @State private var confirmRemoval = false
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 14) {
                    Image(systemName: "power.circle.fill").font(.largeTitle).foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Power Schedule").font(.title2.bold())
                        Text("A simple daily routine for your Mac.").foregroundStyle(.secondary)
                    }
                    Spacer()
                    if model.busy {
                        ProgressView().controlSize(.small).accessibilityLabel("Working")
                    }
                }

                GroupBox {
                    VStack(spacing: 18) {
                        ScheduleTimeRow(
                            title: "Start up automatically", detail: "Wake from sleep or power on",
                            symbol: "sunrise", enabled: $model.startupEnabled, time: $model.startupTime,
                        )
                        Divider()
                        ScheduleTimeRow(
                            title: "Shut down automatically", detail: "Normal macOS shutdown", symbol: "moon",
                            enabled: $model.shutdownEnabled, time: $model.shutdownTime,
                        )
                    }.padding(10)
                }.disabled(model.busy || model.current == nil)

                HStack {
                    Text("Every day · \(timeZone.identifier)").font(.caption).foregroundStyle(
                        .secondary,
                    )
                    Spacer()
                    Button("Apply Schedule") {
                        if model.needsReplacement {
                            confirmReplacement = true
                        } else {
                            Task { await model.apply() }
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(.teal)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(!model.canApply)
                    .accessibilityIdentifier("applySchedule")
                }

                currentSchedule
                permissionControls

                if model.hasConflict {
                    Label(
                        "The schedule changed elsewhere. Reload to review the current settings.",
                        systemImage: "arrow.triangle.2.circlepath",
                    )
                    .foregroundStyle(.orange)
                    Button("Reload Editor") { Task { await model.refresh(discardDraft: true) } }
                }
                if let error = model.error {
                    Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red).textSelection(
                        .enabled,
                    )
                    .accessibilityIdentifier("scheduleError")
                }
                if let notice = model.notice {
                    Label(notice, systemImage: "info.circle").foregroundStyle(.secondary).textSelection(
                        .enabled,
                    )
                }
                Text(
                    """
                    Scheduled shutdown needs an awake Mac and a logged-in user; unsaved work can prevent it. \
                    Power-on requires a power supply. FileVault may require you to unlock the Mac after startup.
                    """,
                )
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }.padding(24)
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 640)
        .confirmationDialog(
            "Replace the existing repeating schedule?", isPresented: $confirmReplacement,
            titleVisibility: .visible,
        ) {
            Button("Replace with Daily Schedule", role: .destructive) {
                Task { await model.apply(replaceExisting: true) }
            }
        } message: {
            Text(
                "The existing event types, days, or seconds cannot be represented by this daily editor. Only the repeating pair will be replaced; one-time events are preserved.",
            )
        }
        .confirmationDialog(
            "Allow automation for this account?", isPresented: $confirmAutomation,
            titleVisibility: .visible,
        ) {
            Button("Allow Automation") { Task { await model.setAutomation(true) } }
        } message: {
            Text(
                "Any process running as your account will be able to use the CLI to change the daily power schedule without another password prompt. You can revoke this here.",
            )
        }
        .confirmationDialog(
            "Remove the scheduling helper?", isPresented: $confirmRemoval, titleVisibility: .visible,
        ) {
            Button("Remove Helper", role: .destructive) { Task { await model.removeHelper() } }
        } message: {
            Text(
                "Automation access for all accounts will be revoked. System schedules remain active. To clear them first, cancel this dialog, disable both times, and apply.",
            )
        }
    }

    private var currentSchedule: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Current System Schedule").font(.headline)
                    Spacer()
                    Button("Refresh", systemImage: "arrow.clockwise") { Task { await model.refresh() } }
                        .labelStyle(.iconOnly).disabled(model.busy)
                }
                if let schedule = model.current {
                    LabeledContent("Startup", value: schedule.startup?.summary ?? "Not scheduled")
                    LabeledContent("Shutdown", value: schedule.shutdown?.summary ?? "Not scheduled")
                    if model.needsReplacement {
                        Text("Existing schedule requires explicit replacement to edit as a daily routine.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Text("Schedule unavailable").foregroundStyle(.secondary)
                }
            }.padding(10)
        }
    }

    private var permissionControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                model.permissionDescription,
                systemImage: model.helperReady ? "checkmark.shield" : "lock.shield",
            )
            .font(.callout).foregroundStyle(.secondary)
            HStack {
                if !model.helperReady {
                    Button("Enable Power Scheduling") { Task { await model.enableHelper() } }
                        .disabled(model.busy || !model.signingReady)
                    Button("Open System Settings") { SMAppService.openSystemSettingsLoginItems() }
                } else {
                    Button(model.automationEnabled ? "Revoke Automation" : "Allow Automation…") {
                        if model.automationEnabled {
                            Task { await model.setAutomation(false) }
                        } else {
                            confirmAutomation = true
                        }
                    }
                    Spacer()
                    Button("Remove Helper…", role: .destructive) { confirmRemoval = true }
                }
            }.disabled(model.busy)
        }
    }
}

private struct ScheduleTimeRow: View {
    let title: String
    let detail: String
    let symbol: String
    @Binding var enabled: Bool
    @Binding var time: Date
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.teal).frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Toggle(title, isOn: $enabled).toggleStyle(.checkbox)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            DatePicker(title + " time", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden().datePickerStyle(.field).disabled(!enabled)
                .accessibilityLabel(title + " time")
        }
    }
}
