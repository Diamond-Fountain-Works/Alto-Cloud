import Foundation

enum StorageService {
    static func defaultHubFolder() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Diamond Transfer")
            .appending(path: "Diamond Cloud Sessions")
    }

    static func availableCapacity(for url: URL = FileManager.default.homeDirectoryForCurrentUser) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        if let capacity = values?.volumeAvailableCapacityForImportantUsage {
            return capacity
        }
        return 128 * 1_000_000_000
    }
}
