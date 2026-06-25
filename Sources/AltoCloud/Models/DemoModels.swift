import Foundation

enum DeviceKind: String, CaseIterable, Codable, Identifiable {
    case mac
    case iPhone
    case iPad
    case android
    case windows

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .mac: "desktopcomputer"
        case .iPhone: "iphone"
        case .iPad: "ipad"
        case .android: "apps.iphone"
        case .windows: "display"
        }
    }
}

struct Device: Identifiable, Hashable {
    let id: UUID
    var name: String
    var kind: DeviceKind
    var isLocal: Bool
    var isSharedCloudHost: Bool
    var isConnectedToSharedCloud: Bool

    var supportsPythonExecution: Bool {
        switch kind {
        case .mac, .iPad:
            true
        case .iPhone, .android, .windows:
            false
        }
    }

    var pythonRuntimeLabel: String {
        switch kind {
        case .mac:
            "Local Python runtime"
        case .iPad:
            "Embedded iPadOS Python runtime"
        case .iPhone:
            "Planned mobile runtime"
        case .android:
            "Unsupported in prototype"
        case .windows:
            "Unsupported in prototype"
        }
    }
}

enum FileMode: String, CaseIterable, Codable, Identifiable {
    case standard
    case oneTimeDrop

    var id: String { rawValue }
}

struct SharedCloudFile: Identifiable, Hashable {
    let id: UUID
    var name: String
    var size: Int64
    var uploadedBy: UUID
    var createdAt: Date
    var mode: FileMode
    var visibleTo: Set<UUID>
    var viewedBy: Set<UUID>

    var isOneTimeDrop: Bool { mode == .oneTimeDrop }

    func isVisible(to deviceID: UUID) -> Bool {
        !isOneTimeDrop || visibleTo.contains(deviceID) || uploadedBy == deviceID
    }

    func hasViewed(_ deviceID: UUID) -> Bool {
        viewedBy.contains(deviceID)
    }

    var targetCount: Int {
        visibleTo.count
    }

    var viewedTargetCount: Int {
        viewedBy.intersection(visibleTo).count
    }
}

struct SharedCloudSession {
    var isActive = false
    var name = "Shared Cloud"
    var hostDeviceID: UUID?
    var storageFolder: URL
    var availableCapacity: Int64
    var quota: Int64
    var rememberSettings = false
    var files: [SharedCloudFile] = []

    var usedCapacity: Int64 {
        files.reduce(0) { $0 + $1.size }
    }

    var remainingQuota: Int64 {
        max(0, quota - usedCapacity)
    }
}

enum ScriptPermission: String, CaseIterable, Codable, Identifiable, Hashable {
    case localFiles
    case network
    case aiModels

    var id: String { rawValue }

    var title: String {
        switch self {
        case .localFiles:
            "Local files"
        case .network:
            "Network"
        case .aiModels:
            "AI models"
        }
    }
}

enum ScriptTaskStatus: String, Codable, Hashable {
    case pendingApproval
    case queued
    case running
    case succeeded
    case rejected
    case failed

    var title: String {
        switch self {
        case .pendingApproval:
            "Pending approval"
        case .queued:
            "Queued"
        case .running:
            "Running"
        case .succeeded:
            "Succeeded"
        case .rejected:
            "Rejected"
        case .failed:
            "Failed"
        }
    }
}

struct ScriptExecutionTask: Identifiable, Hashable {
    let id: UUID
    var name: String
    var sourceDeviceID: UUID
    var targetDeviceID: UUID
    var scriptBody: String
    var permissions: Set<ScriptPermission>
    var status: ScriptTaskStatus
    var createdAt: Date
    var startedAt: Date?
    var finishedAt: Date?
    var logLines: [String]
}

struct ScriptRelaySession {
    var isEnabled = true
    var requireManualApproval = true
    var maxRuntimeSeconds = 30
    var tasks: [ScriptExecutionTask] = []
}

enum SidebarSelection: Hashable {
    case overview
    case peer(UUID)
    case sharedCloud
    case scriptRelay
}
