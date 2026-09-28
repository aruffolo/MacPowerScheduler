import SwiftUI

struct ScheduleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let model: ScheduleModel
    @State private var confirmAutomation = false
    @State private var confirmRemoval = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    feedback
                    access
                    automation
                    limitations
                    removal
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 520, height: 580)
        .background(AgendaPalette(scheme: colorScheme).surface)
        .tint(AgendaPalette(scheme: colorScheme).accent)
        .confirmationDialog("Allow automation for this account?", isPresented: $confirmAutomation, titleVisibility: .visible) {
            Button("Allow Automation") { Task { await model.setAutomation(true) } }
        } message: {
            Text("Any process running as your account will be able to use the CLI to change the daily power schedule without another password prompt. You can revoke this here.")
        }
        .confirmationDialog("Remove the scheduling helper?", isPresented: $confirmRemoval, titleVisibility: .visible) {
            Button("Remove Helper", role: .destructive) { Task { await model.removeHelper() } }
        } message: {
            Text("Automation access for all accounts will be revoked. System schedules remain active. To clear them first, cancel this dialog, disable both times, and apply.")
        }
    }

    private var header: some View {
        HStack {
            Text("Settings").font(.title2.bold())
            Spacer()
            if model.busy {
                ProgressView().controlSize(.small).accessibilityLabel("Working")
            }
            Button("Done") { dismiss() }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("closeSettings")
        }
        .padding(24)
    }

    private var access: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Power scheduling").font(.headline)
            if model.helperReady {
                Label(model.permissionDescription, systemImage: "checkmark.shield")
                    .foregroundStyle(.secondary)
            } else {
                ScheduleSetupBanner(model: model)
            }
            Button("Refresh Status", systemImage: "arrow.clockwise") { Task { await model.refresh() } }
                .disabled(model.busy)
        }
    }

    private var automation: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Automation").font(.headline)
            Text("Allow processes running as your account to change the schedule through the CLI without another password prompt.")
                .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Text(model.helperReady ? (model.automationEnabled ? "Allowed for this account" : "Not allowed") : "Status unavailable")
                    .font(.callout).foregroundStyle(.secondary)
                Spacer()
                Button(model.automationEnabled ? "Revoke Automation" : "Allow Automation…") {
                    if model.automationEnabled {
                        Task { await model.setAutomation(false) }
                    } else {
                        confirmAutomation = true
                    }
                }
                .disabled(!model.helperReady || model.busy)
            }
        }
    }

    private var limitations: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About scheduled power events").font(.headline)
            Text("""
            Scheduled shutdown needs an awake Mac and a logged-in user; unsaved work can prevent it. \
            Power-on requires a power supply. FileVault may require you to unlock the Mac after startup.
            """)
            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var removal: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            Button("Remove Helper…", role: .destructive) { confirmRemoval = true }
                .disabled(!model.helperReady || model.busy)
            Text("Revokes automation for all accounts. Existing system schedules remain active.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var feedback: some View {
        if let error = model.error {
            Label(error, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red).textSelection(.enabled)
                .accessibilityIdentifier("settingsError")
        }
        if let notice = model.notice {
            Text(notice).foregroundStyle(.secondary).textSelection(.enabled)
        }
    }
}
