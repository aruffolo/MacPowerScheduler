import SwiftUI

struct ScheduleSetupBanner: View {
    let model: ScheduleModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(model.permissionDescription, systemImage: "lock.shield")
                .fixedSize(horizontal: false, vertical: true)
            if let action = model.setup.actionTitle {
                Button(action) { Task { await model.performSetupAction() } }
                    .disabled(model.busy)
                    .accessibilityIdentifier("setupAction")
            }
        }
        .font(.callout)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
        .accessibilityElement(children: .contain)
    }
}
