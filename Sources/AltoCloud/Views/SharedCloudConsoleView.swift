import SwiftUI

struct SharedCloudConsoleView: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        if store.sharedCloudSession.isActive {
            GeometryReader { proxy in
                let isCompact = proxy.size.width < 780

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeaderBlock(
                            title: store.sharedCloudSession.name,
                            subtitle: "Host: \(store.sharedCloudHost?.name ?? "Unknown"). The selected device controls visibility and One-Time Drop status."
                        )

                        if isCompact {
                            VStack(spacing: 18) {
                                SharedCloudStatusPanel(store: store)
                                UploadComposerView(store: store)
                                FileListView(store: store)
                                    .frame(minHeight: 360)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 18) {
                                VStack(spacing: 18) {
                                    SharedCloudStatusPanel(store: store)
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
                ContentUnavailableView("Shared Cloud Inactive", systemImage: "externaldrive.badge.xmark", description: Text("Start Shared Cloud on this Mac to create a local sharing session."))
                Button("Start Shared Cloud") {
                    store.startSharedCloud()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

private struct SharedCloudStatusPanel: View {
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
                    if device.isSharedCloudHost {
                            Text("Host")
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
                Text("Browser \(store.lanBrowserState) · Shared Cloud \(store.sharedCloudAdvertiseState)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            StorageMeter(used: store.sharedCloudSession.usedCapacity, quota: store.sharedCloudSession.quota)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
