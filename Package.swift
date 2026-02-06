// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VirtualScreen",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "VirtualScreen",
            path: "Sources/VirtualScreen",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/VirtualScreen/Info.plist",
                ]),
            ]
        ),
    ]
)
