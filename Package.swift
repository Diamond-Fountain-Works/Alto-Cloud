// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DiamondTransfer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DiamondTransfer", targets: ["DiamondTransfer"])
    ],
    targets: [
        .executableTarget(
            name: "DiamondTransfer",
            path: "Sources/DiamondTransfer"
        )
    ]
)
