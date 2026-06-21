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

enum SidebarSelection: Hashable {
    case overview
    case peer(UUID)
    case sharedCloud
}
