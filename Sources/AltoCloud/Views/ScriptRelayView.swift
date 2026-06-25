import SwiftUI

struct ScriptRelayView: View {
    @ObservedObject var store: DemoStore
    @State private var taskName = "Inventory sync"
    @State private var scriptBody = """
print("hello from Alto Cloud")
result = {"status": "ok"}
"""
    @State private var targetDeviceID = UUID()
    @State private var permissions: Set<ScriptPermission> = [.localFiles]

    private var targetDevices: [Device] {
        store.scriptCapableDevices
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 880

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(
                        title: "Script Relay",
                        subtitle: "Send a Python task to a trusted Alto Cloud device, require local approval, and return logs to the sender."
                    )

                    ScriptRelaySafetyPanel(store: store)

                    if isCompact {
                        VStack(spacing: 18) {
                            composer
                            taskQueue
                        }
                    } else {
                        HStack(alignment: .top, spacing: 18) {
                            composer
                                .frame(width: min(430, max(360, proxy.size.width * 0.38)))
                            taskQueue
                                .frame(maxWidth: .infinity, minHeight: max(460, proxy.size.height - 160))
                        }
                    }
                }
                .padding(26)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            chooseDefaultTargetIfNeeded()
        }
        .onChange(of: targetDevices.map(\.id)) { _, _ in
            chooseDefaultTargetIfNeeded()
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("New Task")
                    .font(.headline)
                Spacer()
                Text(store.actingDevice?.name ?? "Device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            TextField("Task name", text: $taskName)

            VStack(alignment: .leading, spacing: 6) {
                Text("Target")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Target", selection: $targetDeviceID) {
                    ForEach(targetDevices) { device in
                        Text("\(device.name) - \(device.pythonRuntimeLabel)").tag(device.id)
                    }
                }
                .labelsHidden()
                .disabled(targetDevices.isEmpty)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Python")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(scriptBody.count) chars")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                TextEditor(text: $scriptBody)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 170)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.background.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Requested permissions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(ScriptPermission.allCases) { permission in
                    Toggle(isOn: permissionBinding(permission)) {
                        Text(permission.title)
                    }
                }
            }

            Button {
                dispatchTask()
            } label: {
                Label("Send Script Task", systemImage: "paperplane")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canDispatch)

            if targetDevices.isEmpty {
                Text("No Python-capable Alto Cloud device has been discovered yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var taskQueue: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task Queue")
                        .font(.headline)
                    Text("\(store.scriptRelaySession.tasks.count) script tasks in this prototype session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)

            Divider()

            if store.scriptRelaySession.tasks.isEmpty {
                ContentUnavailableView("No Script Tasks", systemImage: "chevron.left.forwardslash.chevron.right", description: Text("Create a task to model the device-to-device Python workflow."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.scriptRelaySession.tasks) { task in
                            ScriptTaskRow(store: store, task: task)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var canDispatch: Bool {
        !taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !scriptBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && targetDevices.contains(where: { $0.id == targetDeviceID })
    }

    private func permissionBinding(_ permission: ScriptPermission) -> Binding<Bool> {
        Binding(
            get: { permissions.contains(permission) },
            set: { isOn in
                if isOn {
                    permissions.insert(permission)
                } else {
                    permissions.remove(permission)
                }
            }
        )
    }

    private func chooseDefaultTargetIfNeeded() {
        guard !targetDevices.contains(where: { $0.id == targetDeviceID }) else {
            return
        }
        targetDeviceID = targetDevices.first?.id ?? UUID()
    }

    private func dispatchTask() {
        store.submitPythonScript(
            name: taskName,
            body: scriptBody,
            targetDeviceID: targetDeviceID,
            permissions: permissions
        )
    }
}

private struct ScriptRelaySafetyPanel: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Execution Guardrails", systemImage: "lock.shield")
                    .font(.headline)
                Spacer()
                Text(store.scriptRelayStatus)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
            }

            HStack(alignment: .top, spacing: 18) {
                Toggle("Manual approval", isOn: $store.scriptRelaySession.requireManualApproval)
                Stepper("Runtime \(store.scriptRelaySession.maxRuntimeSeconds)s", value: $store.scriptRelaySession.maxRuntimeSeconds, in: 5...300, step: 5)
            }

            Text("The prototype models the dispatch, approval, and log-return flow. Real iPadOS execution needs an embedded Python runtime, a sandboxed working directory, and explicit file/network permission gates.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ScriptTaskRow: View {
    @ObservedObject var store: DemoStore
    var task: ScriptExecutionTask

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(task.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(task.status.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(iconColor)
                    }
                    Text("\(store.deviceName(task.sourceDeviceID)) -> \(store.deviceName(task.targetDeviceID))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button("Remove Task", role: .destructive) {
                        store.removeScriptTask(task.id)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.button)
            }

            HStack(spacing: 8) {
                ForEach(task.permissions.sorted(by: { $0.title < $1.title })) { permission in
                    Text(permission.title)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                if task.permissions.isEmpty {
                    Text("No elevated permissions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(task.logLines.suffix(4), id: \.self) { line in
                    Text(line)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            HStack {
                Text("Created \(task.createdAt, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                actionButtons
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(.background.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch task.status {
        case .pendingApproval:
            Button("Reject") {
                store.rejectScriptTask(task.id)
            }
            Button("Approve") {
                store.approveScriptTask(task.id)
            }
        case .queued:
            Button("Run") {
                store.runScriptTask(task.id)
            }
        case .running:
            ProgressView()
                .controlSize(.small)
        case .succeeded, .rejected, .failed:
            EmptyView()
        }
    }

    private var iconName: String {
        switch task.status {
        case .pendingApproval:
            "lock.circle"
        case .queued:
            "clock"
        case .running:
            "play.circle"
        case .succeeded:
            "checkmark.circle.fill"
        case .rejected:
            "xmark.circle"
        case .failed:
            "exclamationmark.triangle"
        }
    }

    private var iconColor: Color {
        switch task.status {
        case .pendingApproval, .queued:
            .orange
        case .running:
            .blue
        case .succeeded:
            .green
        case .rejected, .failed:
            .red
        }
    }
}
