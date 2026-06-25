import AppKit
import Combine
import Foundation

final class DemoStore: ObservableObject {
    @Published var devices: [Device] = []
    @Published var sharedCloudSession: SharedCloudSession
    @Published var scriptRelaySession = ScriptRelaySession()
    @Published var selectedDeviceID: UUID
    @Published var actingDeviceID: UUID
    @Published var sidebarSelection: SidebarSelection = .overview
    @Published var lanBrowserState = "Stopped"
    @Published var peerAdvertiseState = "Stopped"
    @Published var sharedCloudAdvertiseState = "Stopped"

    private let lanService: LANDiscoveryService
    private var cancellables: Set<AnyCancellable> = []
    private var joinedSharedCloudDeviceIDs: Set<UUID> = []
    private let sampleNames = [
        "Vacation Photo.heic",
        "Meeting Notes.txt",
        "Client Brief.pdf",
        "Screen Recording.mov",
        "Design Export.zip"
    ]

    init() {
        lanService = LANDiscoveryService()
        let available = StorageService.availableCapacity()
        sharedCloudSession = SharedCloudSession(
            storageFolder: StorageService.defaultSharedCloudFolder(),
            availableCapacity: available,
            quota: min(20 * 1_000_000_000, max(1_000_000_000, available / 8))
        )
        selectedDeviceID = lanService.localPeerID
        actingDeviceID = lanService.localPeerID
        rebuildDevices(from: [])
        bindLANService()
    }

    var localDevice: Device {
        devices.first(where: \.isLocal) ?? devices[0]
    }

    var actingDevice: Device? {
        devices.first(where: { $0.id == actingDeviceID })
    }

    var connectedDevices: [Device] {
        devices.filter { $0.isConnectedToSharedCloud || $0.isSharedCloudHost }
    }

    var peerDevices: [Device] {
        devices.filter { !$0.isSharedCloudHost }
    }

    var sharedCloudHost: Device? {
        devices.first(where: { $0.id == sharedCloudSession.hostDeviceID }) ?? devices.first(where: \.isSharedCloudHost)
    }

    var scriptCapableDevices: [Device] {
        devices.filter { $0.supportsPythonExecution && !$0.isSharedCloudHost }
    }

    var scriptRelayStatus: String {
        guard scriptRelaySession.isEnabled else {
            return "Disabled"
        }
        if scriptRelaySession.tasks.contains(where: { $0.status == .running }) {
            return "Running"
        }
        if scriptRelaySession.tasks.contains(where: { $0.status == .queued || $0.status == .pendingApproval }) {
            return "Queued"
        }
        return "Ready"
    }

    func toggleSharedCloud() {
        sharedCloudSession.isActive ? stopSharedCloud() : startSharedCloud()
    }

    func startSharedCloud() {
        let hostID = lanService.localSharedCloudID
        sharedCloudSession.isActive = true
        sharedCloudSession.hostDeviceID = hostID
        sidebarSelection = .sharedCloud
        joinedSharedCloudDeviceIDs.insert(hostID)
        joinedSharedCloudDeviceIDs.insert(lanService.localPeerID)
        lanService.startSharedCloudAdvertiser()
        rebuildDevices(from: lanService.discoveredNodes)
    }

    func stopSharedCloud() {
        sharedCloudSession.isActive = false
        sharedCloudSession.hostDeviceID = nil
        sharedCloudSession.files.removeAll()
        joinedSharedCloudDeviceIDs.removeAll()
        lanService.stopSharedCloudAdvertiser()
        rebuildDevices(from: lanService.discoveredNodes)
        sidebarSelection = .overview
    }

    func setQuota(gigabytes: Double) {
        let bytes = Int64(gigabytes * 1_000_000_000)
        let safetyReserve = min(10 * 1_000_000_000, sharedCloudSession.availableCapacity / 10)
        sharedCloudSession.quota = min(max(bytes, 1_000_000_000), max(1_000_000_000, sharedCloudSession.availableCapacity - safetyReserve))
    }

    func chooseSharedCloudFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = sharedCloudSession.storageFolder.deletingLastPathComponent()
        if panel.runModal() == .OK, let url = panel.url {
            sharedCloudSession.storageFolder = url
        }
    }

    func toggleConnection(for deviceID: UUID) {
        guard let index = devices.firstIndex(where: { $0.id == deviceID }), !devices[index].isSharedCloudHost else {
            return
        }
        if joinedSharedCloudDeviceIDs.contains(deviceID) {
            joinedSharedCloudDeviceIDs.remove(deviceID)
        } else {
            joinedSharedCloudDeviceIDs.insert(deviceID)
        }
        rebuildDevices(from: lanService.discoveredNodes)
    }

    func addSampleFile() {
        let currentName = sampleNames[sharedCloudSession.files.count % sampleNames.count]
        let connected = connectedDevices.map(\.id)
        addFile(
            name: currentName,
            size: Int64.random(in: 1_200_000...420_000_000),
            mode: .standard,
            uploadedBy: actingDeviceID,
            visibleTo: Set(connected.filter { $0 != actingDeviceID })
        )
    }

    func addFile(name: String, size: Int64, mode: FileMode, uploadedBy: UUID, visibleTo: Set<UUID>) {
        guard sharedCloudSession.isActive, sharedCloudSession.remainingQuota >= size else {
            NSSound.beep()
            return
        }

        var visible = visibleTo
        if mode == .standard {
            visible = Set(connectedDevices.map(\.id))
        }

        let file = SharedCloudFile(
            id: UUID(),
            name: name,
            size: size,
            uploadedBy: uploadedBy,
            createdAt: Date(),
            mode: mode,
            visibleTo: visible,
            viewedBy: []
        )
        sharedCloudSession.files.insert(file, at: 0)
    }

    func markViewed(fileID: UUID, by deviceID: UUID) {
        guard let index = sharedCloudSession.files.firstIndex(where: { $0.id == fileID }) else {
            return
        }
        guard sharedCloudSession.files[index].isOneTimeDrop else {
            return
        }
        guard sharedCloudSession.files[index].visibleTo.contains(deviceID) else {
            return
        }

        sharedCloudSession.files[index].viewedBy.insert(deviceID)

        let file = sharedCloudSession.files[index]
        if file.visibleTo.isSubset(of: file.viewedBy) {
            sharedCloudSession.files.remove(at: index)
        }
    }

    func removeFile(_ fileID: UUID) {
        sharedCloudSession.files.removeAll { $0.id == fileID }
    }

    func submitPythonScript(name: String, body: String, targetDeviceID: UUID, permissions: Set<ScriptPermission>) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard scriptRelaySession.isEnabled, !trimmedName.isEmpty, !trimmedBody.isEmpty else {
            NSSound.beep()
            return
        }
        guard let target = devices.first(where: { $0.id == targetDeviceID }), target.supportsPythonExecution else {
            NSSound.beep()
            return
        }

        let status: ScriptTaskStatus = scriptRelaySession.requireManualApproval ? .pendingApproval : .queued
        let task = ScriptExecutionTask(
            id: UUID(),
            name: trimmedName,
            sourceDeviceID: actingDeviceID,
            targetDeviceID: targetDeviceID,
            scriptBody: trimmedBody,
            permissions: permissions,
            status: status,
            createdAt: Date(),
            startedAt: nil,
            finishedAt: nil,
            logLines: [
                "Created by \(deviceName(actingDeviceID))",
                "Target: \(target.name)",
                "Runtime limit: \(scriptRelaySession.maxRuntimeSeconds)s"
            ]
        )
        scriptRelaySession.tasks.insert(task, at: 0)
        if status == .queued {
            runScriptTask(task.id)
        }
    }

    func approveScriptTask(_ taskID: UUID) {
        updateScriptTask(taskID) { task in
            guard task.status == .pendingApproval else {
                return
            }
            task.status = .queued
            task.logLines.append("Approved on \(deviceName(task.targetDeviceID))")
        }
    }

    func rejectScriptTask(_ taskID: UUID) {
        updateScriptTask(taskID) { task in
            guard task.status == .pendingApproval else {
                return
            }
            task.status = .rejected
            task.finishedAt = Date()
            task.logLines.append("Rejected before execution")
        }
    }

    func runScriptTask(_ taskID: UUID) {
        updateScriptTask(taskID) { task in
            guard task.status == .queued else {
                return
            }
            task.status = .running
            task.startedAt = Date()
            task.logLines.append("Starting sandboxed Python runtime")
            task.logLines.append("Permissions: \(permissionSummary(task.permissions))")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.finishScriptTask(taskID)
        }
    }

    func removeScriptTask(_ taskID: UUID) {
        scriptRelaySession.tasks.removeAll { $0.id == taskID }
    }

    func deviceName(_ id: UUID) -> String {
        devices.first(where: { $0.id == id })?.name ?? "Unknown device"
    }

    func permissionSummary(_ permissions: Set<ScriptPermission>) -> String {
        if permissions.isEmpty {
            return "No elevated permissions"
        }
        return permissions
            .map(\.title)
            .sorted()
            .joined(separator: ", ")
    }

    private func bindLANService() {
        lanService.$discoveredNodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nodes in
                self?.rebuildDevices(from: nodes)
            }
            .store(in: &cancellables)

        lanService.$browserState
            .receive(on: DispatchQueue.main)
            .assign(to: &$lanBrowserState)

        lanService.$peerAdvertiseState
            .receive(on: DispatchQueue.main)
            .assign(to: &$peerAdvertiseState)

        lanService.$sharedCloudAdvertiseState
            .receive(on: DispatchQueue.main)
            .assign(to: &$sharedCloudAdvertiseState)
    }

    private func rebuildDevices(from nodes: [LANNodeDescriptor]) {
        var next: [Device] = [
            Device(
                id: lanService.localPeerID,
                name: lanService.localPeerNode.displayName,
                kind: .mac,
                isLocal: true,
                isSharedCloudHost: false,
                isConnectedToSharedCloud: joinedSharedCloudDeviceIDs.contains(lanService.localPeerID)
            )
        ]

        if sharedCloudSession.isActive {
            next.append(
                Device(
                    id: lanService.localSharedCloudID,
                    name: lanService.localSharedCloudNode.displayName,
                    kind: .mac,
                    isLocal: true,
                    isSharedCloudHost: true,
                    isConnectedToSharedCloud: true
                )
            )
        }

        for node in nodes {
            next.append(
                Device(
                    id: node.id,
                    name: node.displayName,
                    kind: node.deviceKind,
                    isLocal: false,
                    isSharedCloudHost: node.role == .sharedCloud,
                    isConnectedToSharedCloud: joinedSharedCloudDeviceIDs.contains(node.id)
                )
            )
        }

        devices = next
        if !devices.contains(where: { $0.id == actingDeviceID }) {
            actingDeviceID = lanService.localPeerID
        }
    }

    private func updateScriptTask(_ taskID: UUID, mutate: (inout ScriptExecutionTask) -> Void) {
        guard let index = scriptRelaySession.tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }
        mutate(&scriptRelaySession.tasks[index])
    }

    private func finishScriptTask(_ taskID: UUID) {
        updateScriptTask(taskID) { task in
            guard task.status == .running else {
                return
            }
            task.status = .succeeded
            task.finishedAt = Date()
            task.logLines.append("stdout: script completed in prototype mode")
            task.logLines.append("Result returned to \(deviceName(task.sourceDeviceID))")
        }
    }
}
