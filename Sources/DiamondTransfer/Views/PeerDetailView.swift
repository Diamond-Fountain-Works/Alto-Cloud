import SwiftUI

struct PeerDetailView: View {
    @ObservedObject var store: DemoStore
    var deviceID: UUID

    private var device: Device? {
        store.devices.first(where: { $0.id == deviceID })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if let device {
                HeaderBlock(
                    title: device.name,
                    subtitle: device.isLocal ? "This device can act as a direct peer or host Diamond Cloud." : "Discovered as a nearby app device on the same Wi-Fi."
                )

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(device.isConnectedToHub ? "Connected to Diamond Cloud" : "Available for direct transfer", systemImage: device.kind.symbolName)
                            .font(.title3.weight(.medium))

                        if !device.isLocal {
                            Button(device.isConnectedToHub ? "Leave Diamond Cloud" : "Join Diamond Cloud") {
                                store.toggleConnection(for: device.id)
                            }
                            .disabled(!store.hubSession.isActive)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: 420, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Endpoint")
                            .font(.headline)
                        DetailLine(title: "Role", value: device.isHubHost ? "Diamond Cloud" : "Peer")
                        DetailLine(title: "Kind", value: device.kind.rawValue)
                        DetailLine(title: "Local", value: device.isLocal ? "Yes" : "No")
                        DetailLine(title: "Cloud member", value: device.isConnectedToHub ? "Yes" : "No")
                    }
                    .padding(18)
                    .frame(maxWidth: 360, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            } else {
                ContentUnavailableView("Device Not Found", systemImage: "questionmark.circle")
            }
            Spacer()
        }
        .padding(28)
    }
}

private struct DetailLine: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.callout)
    }
}
