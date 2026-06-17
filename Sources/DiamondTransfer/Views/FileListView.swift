import SwiftUI

struct FileListView: View {
    @ObservedObject var store: DemoStore

    private var visibleFiles: [HubFile] {
        store.hubSession.files.filter { $0.isVisible(to: store.actingDeviceID) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("File Queue")
                        .font(.headline)
                    Text("\(visibleFiles.count) visible of \(store.hubSession.files.count) files in Diamond Cloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    store.addSampleFile()
                } label: {
                    Label("Sample", systemImage: "plus")
                }
            }
            .padding(16)

            Divider()

            if visibleFiles.isEmpty {
                ContentUnavailableView("No Visible Files", systemImage: "tray", description: Text("Upload a file or switch the acting device."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(visibleFiles) { file in
                            FileRowView(store: store, file: file)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct FileRowView: View {
    @ObservedObject var store: DemoStore
    var file: HubFile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: file.isOneTime ? "flame.fill" : "doc.fill")
                    .foregroundStyle(file.isOneTime ? .red : .blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(file.name)
                            .font(.headline)
                            .lineLimit(1)
                        if file.isOneTime {
                            Text("一次性文件")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                    }
                    Text("\(ByteFormat.string(file.size)) · uploaded by \(store.deviceName(file.uploadedBy))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Delete from Diamond Cloud", role: .destructive) {
                        store.removeFile(file.id)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.button)
            }

            if file.isOneTime {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Viewed \(file.viewedTargetCount)/\(file.targetCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Deletes after all selected devices open it")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    FlowTags(ids: Array(file.visibleTo), file: file, store: store)
                }
            }

            HStack {
                Text("Viewing as \(store.actingDevice?.name ?? "Device")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if file.isOneTime, file.visibleTo.contains(store.actingDeviceID) {
                    Button(file.hasViewed(store.actingDeviceID) ? "Opened" : "Open") {
                        store.markViewed(fileID: file.id, by: store.actingDeviceID)
                    }
                    .disabled(file.hasViewed(store.actingDeviceID))
                } else if !file.isOneTime {
                    Button("Download") {}
                } else {
                    Text("Not visible to this device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(.background.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct FlowTags: View {
    var ids: [UUID]
    var file: HubFile
    @ObservedObject var store: DemoStore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                tags
            }
            VStack(alignment: .leading, spacing: 8) {
                tags
            }
        }
    }

    @ViewBuilder
    private var tags: some View {
        ForEach(ids, id: \.self) { id in
            Label(store.deviceName(id), systemImage: file.hasViewed(id) ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(file.hasViewed(id) ? .green : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
    }
}
