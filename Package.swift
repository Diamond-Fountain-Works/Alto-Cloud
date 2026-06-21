// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AltoCloud",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AltoCloud", targets: ["AltoCloud"])
    ],
    targets: [
        .executableTarget(
            name: "AltoCloud",
            path: "Sources/AltoCloud"
        )
    ]
)
