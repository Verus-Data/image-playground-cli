// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "image-helper",
    platforms: [
        .macOS("15.4")
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "image-helper",
            path: "Sources"
        )
    ]
)
