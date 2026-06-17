import SwiftUI

struct UploadComposerView: View {
    @ObservedObject var store: DemoStore
    @State private var fileName = "Photo from iPhone.heic"
    @State private var fileSizeMB = 8.0
    @State private var mode: FileMode = .standard
    @State private var selectedTargets: Set<UUID> = []

    private var targetDevices: [Device] {
        store.connectedDevices.filter { $0.id != store.actingDeviceID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upload")
                    .font(.headline)
                Spacer()
                Text(store.actingDevice?.name ?? "Device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Sender")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Sender", selection: $store.actingDeviceID) {
                    ForEach(store.connectedDevices) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                .labelsHidden()
            }

            TextField("File name", text: $fileName)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Size")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(fileSizeMB)) MB")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $fileSizeMB, in: 1...950, step: 1)
            }

            Picker("Mode", selection: $mode) {
                Text("Normal").tag(FileMode.standard)
                Text("一次性文件").tag(FileMode.oneTime)
            }
            .pickerStyle(.segmented)

            if mode == .oneTime {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Visible to")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(targetDevices) { device in
                        Toggle(isOn: targetBinding(for: device.id)) {
                            Label(device.name, systemImage: device.kind.symbolName)
                        }
                    }
                    if targetDevices.isEmpty {
                        Text("No other joined devices yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                upload()
            } label: {
                Label("Upload to Diamond Cloud", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canUpload)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .onAppear {
            resetTargets()
        }
        .onChange(of: store.connectedDevices.map(\.id)) { _, _ in
            resetTargets()
        }
        .onChange(of: store.actingDeviceID) { _, _ in
            resetTargets()
        }
    }

    private var canUpload: Bool {
        !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && store.hubSession.remainingQuota >= Int64(fileSizeMB * 1_000_000)
            && (mode == .standard || !selectedTargets.isEmpty)
    }

    private func targetBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedTargets.contains(id) },
            set: { isOn in
                if isOn {
                    selectedTargets.insert(id)
                } else {
                    selectedTargets.remove(id)
                }
            }
        )
    }

    private func resetTargets() {
        selectedTargets = Set(targetDevices.map(\.id))
    }

    private func upload() {
        store.addFile(
            name: fileName,
            size: Int64(fileSizeMB * 1_000_000),
            mode: mode,
            uploadedBy: store.actingDeviceID,
            visibleTo: selectedTargets
        )
    }
}
