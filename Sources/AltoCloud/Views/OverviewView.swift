import SwiftUI

struct OverviewView: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderBlock(
                    title: "Control Center",
                    subtitle: "Use Quick Send, start a Shared Cloud, and set its storage boundary before devices join."
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 14)], spacing: 14) {
                    StatusSummary(icon: "dot.radiowaves.left.and.right", title: "Discovery", value: store.lanBrowserState, detail: LANProtocol.serviceType)
                    StatusSummary(icon: "arrow.left.arrow.right", title: "Quick Send", value: store.peerAdvertiseState, detail: "Nearby target is always published")
                    StatusSummary(icon: "externaldrive.connected.to.line.below", title: "Shared Cloud", value: store.sharedCloudSession.isActive ? "Active" : "Stopped", detail: "Shared local session")
                }

                SharedCloudSetupView(store: store)
            }
            .padding(28)
            .frame(maxWidth: 1040, alignment: .leading)
        }
    }
}

struct HeaderBlock: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StatusSummary: View {
    var icon: String
    var title: String
    var value: String
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
