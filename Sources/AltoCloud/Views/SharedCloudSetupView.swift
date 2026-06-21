import SwiftUI

struct SharedCloudSetupView: View {
    @ObservedObject var store: DemoStore

    private var quotaGB: Binding<Double> {
        Binding(
            get: { Double(store.sharedCloudSession.quota) / 1_000_000_000 },
            set: { store.setQuota(gigabytes: $0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shared Cloud Setup")
                        .font(.headline)
                    Text("Choose how much local disk this Shared Cloud session can use.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(store.sharedCloudSession.isActive ? "Stop Shared Cloud" : "Start Shared Cloud") {
                    store.toggleSharedCloud()
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    SetupMetric(title: "Available", value: ByteFormat.string(store.sharedCloudSession.availableCapacity))
                    SetupMetric(title: "Quota", value: ByteFormat.string(store.sharedCloudSession.quota))
                    SetupMetric(title: "Used", value: ByteFormat.string(store.sharedCloudSession.usedCapacity))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Session quota")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ByteFormat.string(store.sharedCloudSession.quota))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: quotaGB, in: 1...max(1, Double(store.sharedCloudSession.availableCapacity) / 1_000_000_000), step: 1)
                    StorageMeter(used: store.sharedCloudSession.usedCapacity, quota: store.sharedCloudSession.quota)
                }

                HStack(spacing: 10) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    Text(store.sharedCloudSession.storageFolder.path)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Choose") {
                        store.chooseSharedCloudFolder()
                    }
                }
                .padding(10)
                .background(.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 7))

                Toggle("Remember this Shared Cloud folder and quota for this Mac", isOn: $store.sharedCloudSession.rememberSettings)
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SetupMetric: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 7))
    }
}

struct StorageMeter: View {
    var used: Int64
    var quota: Int64

    private var progress: Double {
        guard quota > 0 else { return 0 }
        return min(1, Double(used) / Double(quota))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: progress)
            HStack {
                Text("Used \(ByteFormat.string(used))")
                Spacer()
                Text("Remaining \(ByteFormat.string(max(0, quota - used)))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
