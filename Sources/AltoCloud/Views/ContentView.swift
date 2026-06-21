import SwiftUI

struct ContentView: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        GeometryReader { proxy in
            let sidebarWidth = min(268, max(220, proxy.size.width * 0.24))

            HStack(spacing: 0) {
                SidebarView(store: store)
                    .frame(width: sidebarWidth)
                    .background(.bar)

                Divider()

                VStack(spacing: 0) {
                    TopStatusBar(store: store)
                    Divider()
                    DetailRouterView(store: store)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 660)
    }
}

struct TopStatusBar: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullBar
            compactBar
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private var titleBlock: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "cloud")
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
    }

    private var devicePicker: some View {
        Picker("Acting Device", selection: $store.actingDeviceID) {
            ForEach(store.devices) { device in
                Text(device.name).tag(device.id)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(maxWidth: 210)
    }

    private var sharedCloudButton: some View {
        Button {
            store.toggleSharedCloud()
        } label: {
            Label(store.sharedCloudSession.isActive ? "Stop Shared Cloud" : "Start Shared Cloud", systemImage: store.sharedCloudSession.isActive ? "xmark.circle" : "antenna.radiowaves.left.and.right")
                .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
    }

    private var fullBar: some View {
        HStack(spacing: 14) {
            titleBlock

            Spacer()

            LANStatusChip(title: "Browser", value: store.lanBrowserState)
            LANStatusChip(title: "Peer", value: store.peerAdvertiseState)
            LANStatusChip(title: "Shared Cloud", value: store.sharedCloudAdvertiseState)

            devicePicker
            sharedCloudButton
        }
    }

    private var compactBar: some View {
        HStack(spacing: 12) {
            titleBlock
            Spacer()
            LANStatusDot(value: store.sharedCloudSession.isActive ? store.sharedCloudAdvertiseState : store.peerAdvertiseState)
            devicePicker
            sharedCloudButton
        }
    }

    private var title: String {
        switch store.sidebarSelection {
        case .overview:
            "Control Center"
        case .peer:
            "Device"
        case .sharedCloud:
            "Shared Cloud"
        }
    }
}

private struct LANStatusDot: View {
    var value: String

    var body: some View {
        Circle()
            .fill(value == "Ready" ? .green : .orange)
            .frame(width: 9, height: 9)
            .help(value)
    }
}

private struct LANStatusChip: View {
    var title: String
    var value: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(value == "Ready" ? .green : .orange)
                .frame(width: 7, height: 7)
            Text("\(title) \(value)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct DetailRouterView: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        switch store.sidebarSelection {
        case .overview:
            OverviewView(store: store)
        case .peer(let id):
            PeerDetailView(store: store, deviceID: id)
        case .sharedCloud:
            SharedCloudConsoleView(store: store)
        }
    }
}
