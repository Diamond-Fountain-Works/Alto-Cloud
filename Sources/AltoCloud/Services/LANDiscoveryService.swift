import Foundation
import Network

final class LANDiscoveryService: ObservableObject {
    @Published private(set) var discoveredNodes: [LANNodeDescriptor] = []
    @Published private(set) var peerAdvertiseState = "Stopped"
    @Published private(set) var sharedCloudAdvertiseState = "Stopped"
    @Published private(set) var browserState = "Stopped"

    let localPeerID: UUID
    let localSharedCloudID: UUID

    private let queue = DispatchQueue(label: "altocloud.lan")
    private let displayName: String
    private var browser: NWBrowser?
    private var peerListener: NWListener?
    private var sharedCloudListener: NWListener?

    init(displayName: String = Host.current().localizedName ?? "Alto Mac") {
        self.displayName = displayName
        self.localPeerID = UUID()
        self.localSharedCloudID = UUID()
        startBrowser()
        startPeerAdvertiser()
    }

    var localPeerNode: LANNodeDescriptor {
        LANNodeDescriptor(
            id: localPeerID,
            role: .peer,
            displayName: displayName,
            deviceKind: .mac,
            protocolVersion: LANProtocol.version,
            endpointName: "local-peer",
            discoveredAt: Date()
        )
    }

    var localSharedCloudNode: LANNodeDescriptor {
        LANNodeDescriptor(
            id: localSharedCloudID,
            role: .sharedCloud,
            displayName: "Shared Cloud on \(displayName)",
            deviceKind: .mac,
            protocolVersion: LANProtocol.version,
            endpointName: "local-shared-cloud",
            discoveredAt: Date()
        )
    }

    func startSharedCloudAdvertiser() {
        guard sharedCloudListener == nil else { return }
        sharedCloudListener = makeAdvertiser(for: localSharedCloudNode)
        sharedCloudListener?.stateUpdateHandler = { [weak self] state in
            self?.publishState(state, keyPath: \.sharedCloudAdvertiseState)
        }
        sharedCloudListener?.newConnectionHandler = { [weak self] connection in
            self?.accept(connection, as: self?.localSharedCloudNode)
        }
        sharedCloudListener?.start(queue: queue)
    }

    func stopSharedCloudAdvertiser() {
        sharedCloudListener?.cancel()
        sharedCloudListener = nil
        DispatchQueue.main.async {
            self.sharedCloudAdvertiseState = "Stopped"
        }
    }

    private func startPeerAdvertiser() {
        guard peerListener == nil else { return }
        peerListener = makeAdvertiser(for: localPeerNode)
        peerListener?.stateUpdateHandler = { [weak self] state in
            self?.publishState(state, keyPath: \.peerAdvertiseState)
        }
        peerListener?.newConnectionHandler = { [weak self] connection in
            self?.accept(connection, as: self?.localPeerNode)
        }
        peerListener?.start(queue: queue)
    }

    private func startBrowser() {
        let browser = NWBrowser(for: .bonjour(type: LANProtocol.serviceType, domain: nil), using: .tcp)
        self.browser = browser

        browser.stateUpdateHandler = { [weak self] state in
            self?.publishBrowserState(state)
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            self?.updateResults(results)
        }

        browser.start(queue: queue)
    }

    private func makeAdvertiser(for node: LANNodeDescriptor) -> NWListener? {
        do {
            let listener = try NWListener(using: .tcp)
            listener.service = NWListener.Service(
                name: serviceName(for: node),
                type: LANProtocol.serviceType,
                domain: nil,
                txtRecord: NWTXTRecord([
                    "protocol": LANProtocol.version,
                    "node": node.id.uuidString,
                    "role": node.role.rawValue,
                    "name": node.displayName,
                    "kind": node.deviceKind.rawValue
                ])
            )
            return listener
        } catch {
            DispatchQueue.main.async {
                if node.role == .sharedCloud {
                    self.sharedCloudAdvertiseState = "Failed: \(error.localizedDescription)"
                } else {
                    self.peerAdvertiseState = "Failed: \(error.localizedDescription)"
                }
            }
            return nil
        }
    }

    private func accept(_ connection: NWConnection, as node: LANNodeDescriptor?) {
        guard let node else {
            connection.cancel()
            return
        }

        connection.stateUpdateHandler = { state in
            if case .ready = state {
                let payload = LANHelloPayload(node: node)
                let envelope = LANEnvelope(type: .hello, senderID: node.id, payload: payload)
                if let data = try? JSONEncoder.lan.encode(envelope) {
                    connection.send(content: data + Data([0x0A]), completion: .contentProcessed { _ in })
                }
            }
        }
        connection.start(queue: queue)
    }

    private func updateResults(_ results: Set<NWBrowser.Result>) {
        let nodes = results.compactMap(parseNode)
            .filter { $0.id != localPeerID && $0.id != localSharedCloudID }
            .sorted { lhs, rhs in
                if lhs.role != rhs.role {
                    return lhs.role.rawValue < rhs.role.rawValue
                }
                return lhs.displayName < rhs.displayName
            }

        DispatchQueue.main.async {
            self.discoveredNodes = nodes
        }
    }

    private func parseNode(_ result: NWBrowser.Result) -> LANNodeDescriptor? {
        guard case let .service(name, _, _, _) = result.endpoint else {
            return nil
        }

        guard let parsed = parseServiceName(name),
              let role = LANNodeRole(rawValue: parsed.role)
        else {
            return nil
        }

        return LANNodeDescriptor(
            id: parsed.id,
            role: role,
            displayName: parsed.displayName,
            deviceKind: parsed.kind,
            protocolVersion: LANProtocol.version,
            endpointName: name,
            discoveredAt: Date()
        )
    }

    private func serviceName(for node: LANNodeDescriptor) -> String {
        let role = node.role == .sharedCloud ? "sharedCloud" : "peer"
        let compactID = node.id.uuidString.replacingOccurrences(of: "-", with: "")
        return "AC|\(role)|\(compactID)|\(node.deviceKind.rawValue)"
    }

    private func parseServiceName(_ name: String) -> (role: String, id: UUID, kind: DeviceKind, displayName: String)? {
        let parts = name.split(separator: "|").map(String.init)
        guard parts.count == 4, parts[0] == "AC" else {
            return nil
        }

        let compactID = parts[2]
        guard compactID.count == 32 else {
            return nil
        }

        let uuidString = [
            compactID.prefix(8),
            compactID.dropFirst(8).prefix(4),
            compactID.dropFirst(12).prefix(4),
            compactID.dropFirst(16).prefix(4),
            compactID.dropFirst(20)
        ].map(String.init).joined(separator: "-")

        guard let id = UUID(uuidString: uuidString) else {
            return nil
        }

        let role = parts[1]
        let kind = DeviceKind(rawValue: parts[3]) ?? .mac
        let short = compactID.prefix(6).uppercased()
        let displayName = role == "sharedCloud" ? "Shared Cloud \(short)" : "Alto Cloud \(short)"
        return (role, id, kind, displayName)
    }

    private func publishBrowserState(_ state: NWBrowser.State) {
        let text: String
        switch state {
        case .setup: text = "Setup"
        case .waiting(let error): text = "Waiting: \(error.localizedDescription)"
        case .ready: text = "Ready"
        case .failed(let error): text = "Failed: \(error.localizedDescription)"
        case .cancelled: text = "Cancelled"
        @unknown default: text = "Unknown"
        }
        DispatchQueue.main.async {
            self.browserState = text
        }
    }

    private func publishState(_ state: NWListener.State, keyPath: ReferenceWritableKeyPath<LANDiscoveryService, String>) {
        let text: String
        switch state {
        case .setup: text = "Setup"
        case .waiting(let error): text = "Waiting: \(error.localizedDescription)"
        case .ready: text = "Ready"
        case .failed(let error): text = "Failed: \(error.localizedDescription)"
        case .cancelled: text = "Cancelled"
        @unknown default: text = "Unknown"
        }
        DispatchQueue.main.async {
            self[keyPath: keyPath] = text
        }
    }
}

private extension JSONEncoder {
    static var lan: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
