// swift-tools-version: 6.0
import PackageDescription

// Linux-only companion to ForkedEchoes.xcodeproj: exposes the platform-agnostic Content/ and
// Engine/ sources (no SwiftUI/UIKit) as a single SwiftPM module so `swift test` can exercise them
// in the devcontainer. Deliberately ONE target covering both directories via `sources`, not two
// targets with a dependency edge between them: the real Xcode app target compiles Content/,
// Engine/, and Views/ together with no module boundary at all, and a two-target split here would
// invent a boundary that doesn't exist in production — forcing every Engine file that touches a
// Content type to special-case its import for a distinction only this package draws. One target
// means no file in Content/ or Engine/ ever needs a cross-target import in either build graph.
let package = Package(
    name: "ForkedEchoes",
    targets: [
        .target(
            name: "ForkedEchoes",
            path: "ForkedEchoes",
            exclude: ["App", "Views", "Resources"],
            sources: ["Content", "Engine"]
        ),
        .testTarget(
            name: "ForkedEchoesTests",
            dependencies: ["ForkedEchoes"],
            path: "ForkedEchoesTests"
        ),
    ]
)
