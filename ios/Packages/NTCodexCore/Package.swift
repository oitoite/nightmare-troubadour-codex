// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NTCodexCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "NTCodexCore", targets: ["NTCodexCore"]),
    ],
    targets: [
        .target(
            name: "NTCodexCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "NTCodexCoreTests",
            dependencies: ["NTCodexCore"]
        ),
    ]
)
