import SwiftUI

struct ScheduleContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var model: ScheduleModel
    @State private var confirmReplacement = false
    @State private var settingsPresented = false

    private var palette: AgendaPalette {
        AgendaPalette(scheme: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                introduction
                if !model.helperReady {
                    ScheduleSetupBanner(model: model).padding(.bottom, 24)
                }
                if model.hasConflict || model.error != nil || model.notice != nil {
                    feedback.padding(.bottom, 24)
                }
                agenda
                Text("Shutdown may be delayed by unsaved work.")
                    .font(.system(size: 14)).italic().foregroundStyle(.secondary)
                    .padding(.leading, 88).padding(.top, 10).padding(.bottom, 22)
                Divider()
                SavedScheduleView(model: model)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 46).padding(.top, 28).padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { ScheduleFooter(model: model, apply: apply) }
        .background(palette.surface)
        .frame(minWidth: 520)
        .contentFittingWindow()
        .tint(palette.accent)
        .toolbar { settingsToolbar }
        .sheet(isPresented: $settingsPresented) { ScheduleSettingsView(model: model) }
        .confirmationDialog("Replace the existing repeating schedule?", isPresented: $confirmReplacement, titleVisibility: .visible) {
            Button("Replace with Daily Schedule", role: .destructive) {
                Task { await model.apply(replaceExisting: true) }
            }
        } message: {
            Text("""
            The existing event types, days, or seconds cannot be represented by this daily editor. \
            Only the repeating pair will be replaced; one-time events are preserved.
            """)
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("A daily routine").font(.system(size: 34, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("Set a time to start up and a time to shut down your Mac.")
                .font(.system(size: 16)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 24)
    }

    private var agenda: some View {
        VStack(spacing: 38) {
            AgendaEventRow(
                title: "Start up",
                detail: "Wake or power on your Mac.",
                isStartup: true,
                enabled: $model.startupEnabled,
                time: $model.startupTime,
            )
            AgendaEventRow(
                title: "Shut down",
                detail: "Shut down your Mac.",
                isStartup: false,
                enabled: $model.shutdownEnabled,
                time: $model.shutdownTime,
            )
        }
        .background(alignment: .topLeading) {
            Rectangle().fill(.secondary.opacity(0.35)).frame(width: 2, height: 164)
                .offset(x: 26, y: 27).accessibilityHidden(true)
        }
        .disabled(model.busy || model.current == nil)
    }

    @ViewBuilder private var feedback: some View {
        if model.hasConflict {
            Label("The schedule changed elsewhere. Reload to review the current settings.", systemImage: "arrow.triangle.2.circlepath")
                .foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
            Button("Reload Editor") { Task { await model.refresh(discardDraft: true) } }
                .disabled(model.busy).padding(.top, 8)
        }
        if let error = model.error {
            Label(error, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("scheduleError")
        }
        if let notice = model.notice {
            Text(notice).foregroundStyle(.secondary).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ToolbarContentBuilder private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("MacPowerScheduler").font(.body)
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Settings", systemImage: "gearshape.fill") { settingsPresented = true }
                .help("Settings").keyboardShortcut(",", modifiers: .command)
                .accessibilityIdentifier("openSettings")
        }
    }

    private func apply() {
        if model.needsReplacement {
            confirmReplacement = true
        } else {
            Task { await model.apply() }
        }
    }
}
