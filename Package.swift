// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenWithGUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OpenWithGUI", targets: ["OpenWithGUIApp"])
    ],
    targets: [
        .executableTarget(
            name: "OpenWithGUIApp",
            path: "Sources/OpenWithGUIApp"
        ),
        .testTarget(
            name: "OpenWithGUIAppTests",
            dependencies: ["OpenWithGUIApp"],
            path: "Tests/OpenWithGUIAppTests"
        )
    ]
)
