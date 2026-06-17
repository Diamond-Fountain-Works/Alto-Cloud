import Foundation

enum LANProtocol {
    static let version = "dt-lan-1"
    static let serviceType = "_diamondtransfer._tcp"
}

enum LANNodeRole: String, Codable, Hashable {
    case peer
    case hub
}

struct LANNodeDescriptor: Codable, Identifiable, Hashable {
    var id: UUID
    var role: LANNodeRole
    var displayName: String
    var deviceKind: DeviceKind
    var protocolVersion: String
    var endpointName: String
    var discoveredAt: Date
}

enum LANMessageType: String, Codable {
    case hello
    case joinHub
    case leaveHub
    case hubSnapshot
    case uploadIntent
    case uploadAccepted
    case uploadRejected
    case fileViewed
    case fileDeleted
}

struct LANEnvelope<Payload: Codable>: Codable {
    var protocolVersion: String = LANProtocol.version
    var messageID: UUID = UUID()
    var type: LANMessageType
    var senderID: UUID
    var sentAt: Date = Date()
    var payload: Payload
}

struct LANHelloPayload: Codable {
    var node: LANNodeDescriptor
}

struct LANJoinHubPayload: Codable {
    var deviceID: UUID
    var displayName: String
    var deviceKind: DeviceKind
}

struct LANUploadIntentPayload: Codable {
    var fileID: UUID
    var fileName: String
    var size: Int64
    var mode: FileMode
    var visibleToDeviceIDs: Set<UUID>
}

struct LANFileViewedPayload: Codable {
    var fileID: UUID
    var deviceID: UUID
}
