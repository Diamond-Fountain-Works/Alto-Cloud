import SwiftUI

struct HubConsoleView: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        if store.hubSession.isActive {
            GeometryReader { proxy in
                let isCompact = proxy.size.width < 780

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeaderBlock(
                            title: store.hubSession.name,
                            subtitle: "Host: \(store.hubHost?.name ?? "Unknown"). The selected acting device controls visibility and one-time file viewed state."
                        )

                        if isCompact {
                            VStack(spacing: 18) {
                                HubStatusPanel(store: store)
                                UploadComposerView(store: store)
                                FileListView(store: store)
                                    .frame(minHeight: 360)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 18) {
                                VStack(spacing: 18) {
                                    HubStatusPanel(store: store)
                                    UploadComposerView(store: store)
                                }
                                .frame(width: min(390, max(330, proxy.size.width * 0.34)))

                                FileListView(store: store)
                                    .frame(maxWidth: .infinity, minHeight: max(460, proxy.size.height - 110))
                            }
                        }
                    }
                    .padding(26)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            VStack(spacing: 18) {
                ContentUnavailableView("Diamond Cloud Inactive", systemImage: "externaldrive.badge.xmark", description: Text("Start Diamond Cloud on this Mac to create a local sharing session."))
                Button("Start Diamond Cloud") {
                    store.startHub()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

private struct HubStatusPanel: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Connected Devices", systemImage: "person.2")
                    .font(.headline)
                Spacer()
                Text("\(store.connectedDevices.count) unique")
                    .foregroundStyle(.secondary)
            }

            ForEach(store.connectedDevices) { device in
                HStack {
                    Label(device.name, systemImage: device.kind.symbolName)
                    Spacer()
                    if device.isHubHost {
                            Text("Cloud")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.blue)
                    }
                    if device.id == store.actingDeviceID {
                        Text("Viewing")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()
            HStack {
                Label("mDNS", systemImage: "dot.radiowaves.left.and.right")
                Spacer()
                Text("Browser \(store.lanBrowserState) · Cloud \(store.hubAdvertiseState)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            StorageMeter(used: store.hubSession.usedCapacity, quota: store.hubSession.quota)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
