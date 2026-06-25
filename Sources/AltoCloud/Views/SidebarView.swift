import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Alto Cloud", systemImage: "cloud.fill")
                    .font(.title3.weight(.semibold))
                Text("Nearby sharing, no internet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)

            SidebarButton(
                title: "Control Center",
                subtitle: "Storage, protocol, setup",
                systemImage: "slider.horizontal.3",
                isSelected: store.sidebarSelection == .overview
            ) {
                store.sidebarSelection = .overview
            }

            SidebarButton(
                title: "Script Relay",
                subtitle: "Python tasks across devices",
                systemImage: "chevron.left.forwardslash.chevron.right",
                isSelected: store.sidebarSelection == .scriptRelay
            ) {
                store.sidebarSelection = .scriptRelay
            }

            SidebarSectionTitle("Quick Send")
            VStack(spacing: 4) {
                ForEach(store.peerDevices) { device in
                    DeviceSidebarRow(
                        device: device,
                        isSelected: store.sidebarSelection == .peer(device.id)
                    ) {
                        store.sidebarSelection = .peer(device.id)
                    }
                }
            }

            SidebarSectionTitle("Shared Cloud")
            if store.sharedCloudSession.isActive, let host = store.sharedCloudHost {
                SidebarButton(
                    title: store.sharedCloudSession.name,
                    subtitle: "Host: \(host.name)",
                    systemImage: "externaldrive.connected.to.line.below",
                    isSelected: store.sidebarSelection == .sharedCloud
                ) {
                    store.sidebarSelection = .sharedCloud
                }
            } else {
                EmptySidebarNote(text: "No Shared Cloud is broadcasting")
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Protocol")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(LANProtocol.serviceType)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
    }
}

private struct DeviceSidebarRow: View {
    var device: Device
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: device.kind.symbolName)
                    .frame(width: 20)
                    .foregroundStyle(device.isLocal ? .blue : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SidebarRowButtonStyle(isSelected: isSelected))
        .padding(.horizontal, 8)
    }

    private var statusText: String {
        if device.isLocal {
            return "This Mac"
        }
        if device.isConnectedToSharedCloud {
            return "Connected to Shared Cloud"
        }
        return "Quick Send available"
    }
}

private struct SidebarButton: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SidebarRowButtonStyle(isSelected: isSelected))
        .padding(.horizontal, 8)
    }
}

private struct SidebarSectionTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 4)
    }
}

private struct EmptySidebarNote: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

private struct SidebarRowButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : (configuration.isPressed ? Color.primary.opacity(0.06) : Color.clear))
            )
            .foregroundStyle(.primary)
    }
}
