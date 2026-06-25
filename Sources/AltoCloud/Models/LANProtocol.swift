import Foundation

enum LANProtocol {
    static let version = "ac-lan-1"
    static let serviceType = "_altocloud._tcp"
}

enum LANNodeRole: String, Codable, Hashable {
    case peer
    case sharedCloud
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
    case joinSharedCloud
    case leaveSharedCloud
    case sharedCloudSnapshot
    case uploadIntent
    case uploadAccepted
    case uploadRejected
    case fileViewed
    case fileDeleted
    case scriptRunIntent
    case scriptRunAccepted
    case scriptRunRejected
    case scriptRunStarted
    case scriptRunFinished
    case scriptRunCancelled
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

struct LANJoinSharedCloudPayload: Codable {
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

struct LANScriptRunIntentPayload: Codable {
    var taskID: UUID
    var name: String
    var targetDeviceID: UUID
    var scriptBody: String
    var permissions: Set<ScriptPermission>
    var maxRuntimeSeconds: Int
}

struct LANScriptRunStatusPayload: Codable {
    var taskID: UUID
    var deviceID: UUID
    var status: ScriptTaskStatus
    var logTail: [String]
}
