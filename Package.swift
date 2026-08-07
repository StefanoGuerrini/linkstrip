// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LinkStrip",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "LinkStrip", targets: ["LinkStrip"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LinkStrip",
            dependencies: [],
            resources: [
                .process("Resources"),
                .copy("fonts")
            ],
            linkerSettings: [
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "LinkStripTests",
            dependencies: ["LinkStrip"]
        )
    ]
)
