import AppKit
import Combine
import Foundation

final class DemoStore: ObservableObject {
    @Published var devices: [Device] = []
    @Published var hubSession: HubSession
    @Published var selectedDeviceID: UUID
    @Published var actingDeviceID: UUID
    @Published var sidebarSelection: SidebarSelection = .overview
    @Published var lanBrowserState = "Stopped"
    @Published var peerAdvertiseState = "Stopped"
    @Published var hubAdvertiseState = "Stopped"

    private let lanService: LANDiscoveryService
    private var cancellables: Set<AnyCancellable> = []
    private var joinedHubDeviceIDs: Set<UUID> = []
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
        hubSession = HubSession(
            storageFolder: StorageService.defaultHubFolder(),
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
        devices.filter { $0.isConnectedToHub || $0.isHubHost }
    }

    var peerDevices: [Device] {
        devices.filter { !$0.isHubHost }
    }

    var hubHost: Device? {
        devices.first(where: { $0.id == hubSession.hostDeviceID }) ?? devices.first(where: \.isHubHost)
    }

    func toggleHub() {
        hubSession.isActive ? stopHub() : startHub()
    }

    func startHub() {
        let hostID = lanService.localHubID
        hubSession.isActive = true
        hubSession.hostDeviceID = hostID
        sidebarSelection = .hub
        joinedHubDeviceIDs.insert(hostID)
        joinedHubDeviceIDs.insert(lanService.localPeerID)
        lanService.startHubAdvertiser()
        rebuildDevices(from: lanService.discoveredNodes)
    }

    func stopHub() {
        hubSession.isActive = false
        hubSession.hostDeviceID = nil
        hubSession.files.removeAll()
        joinedHubDeviceIDs.removeAll()
        lanService.stopHubAdvertiser()
        rebuildDevices(from: lanService.discoveredNodes)
        sidebarSelection = .overview
    }

    func setQuota(gigabytes: Double) {
        let bytes = Int64(gigabytes * 1_000_000_000)
        let safetyReserve = min(10 * 1_000_000_000, hubSession.availableCapacity / 10)
        hubSession.quota = min(max(bytes, 1_000_000_000), max(1_000_000_000, hubSession.availableCapacity - safetyReserve))
    }

    func chooseHubFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = hubSession.storageFolder.deletingLastPathComponent()
        if panel.runModal() == .OK, let url = panel.url {
            hubSession.storageFolder = url
        }
    }

    func toggleConnection(for deviceID: UUID) {
        guard let index = devices.firstIndex(where: { $0.id == deviceID }), !devices[index].isHubHost else {
            return
        }
        if joinedHubDeviceIDs.contains(deviceID) {
            joinedHubDeviceIDs.remove(deviceID)
        } else {
            joinedHubDeviceIDs.insert(deviceID)
        }
        rebuildDevices(from: lanService.discoveredNodes)
    }

    func addSampleFile() {
        let currentName = sampleNames[hubSession.files.count % sampleNames.count]
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
        guard hubSession.isActive, hubSession.remainingQuota >= size else {
            NSSound.beep()
            return
        }

        var visible = visibleTo
        if mode == .standard {
            visible = Set(connectedDevices.map(\.id))
        }

        let file = HubFile(
            id: UUID(),
            name: name,
            size: size,
            uploadedBy: uploadedBy,
            createdAt: Date(),
            mode: mode,
            visibleTo: visible,
            viewedBy: []
        )
        hubSession.files.insert(file, at: 0)
    }

    func markViewed(fileID: UUID, by deviceID: UUID) {
        guard let index = hubSession.files.firstIndex(where: { $0.id == fileID }) else {
            return
        }
        guard hubSession.files[index].isOneTime else {
            return
        }
        guard hubSession.files[index].visibleTo.contains(deviceID) else {
            return
        }

        hubSession.files[index].viewedBy.insert(deviceID)

        let file = hubSession.files[index]
        if file.visibleTo.isSubset(of: file.viewedBy) {
            hubSession.files.remove(at: index)
        }
    }

    func removeFile(_ fileID: UUID) {
        hubSession.files.removeAll { $0.id == fileID }
    }

    func deviceName(_ id: UUID) -> String {
        devices.first(where: { $0.id == id })?.name ?? "Unknown device"
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

        lanService.$hubAdvertiseState
            .receive(on: DispatchQueue.main)
            .assign(to: &$hubAdvertiseState)
    }

    private func rebuildDevices(from nodes: [LANNodeDescriptor]) {
        var next: [Device] = [
            Device(
                id: lanService.localPeerID,
                name: lanService.localPeerNode.displayName,
                kind: .mac,
                isLocal: true,
                isHubHost: false,
                isConnectedToHub: joinedHubDeviceIDs.contains(lanService.localPeerID)
            )
        ]

        if hubSession.isActive {
            next.append(
                Device(
                    id: lanService.localHubID,
                    name: lanService.localHubNode.displayName,
                    kind: .mac,
                    isLocal: true,
                    isHubHost: true,
                    isConnectedToHub: true
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
                    isHubHost: node.role == .hub,
                    isConnectedToHub: joinedHubDeviceIDs.contains(node.id)
                )
            )
        }

        devices = next
        if !devices.contains(where: { $0.id == actingDeviceID }) {
            actingDeviceID = lanService.localPeerID
        }
    }
}
