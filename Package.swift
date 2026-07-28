// swift-tools-version: 6.0
import PackageDescription

// Linux-only companion to ForkedEchoes.xcodeproj: exposes the platform-agnostic
// Engine/ sources as a SwiftPM module so `swift test` can exercise them in the
// devcontainer, without SwiftUI/UIKit and without touching the Xcode project.
let package = Package(
    name: "ForkedEchoes",
    targets: [
        .target(
            name: "ForkedEchoes",
            path: "ForkedEchoes/Engine"
        ),
        .testTarget(
            name: "ForkedEchoesTests",
            dependencies: ["ForkedEchoes"],
            path: "ForkedEchoesTests"
        ),
    ]
)
