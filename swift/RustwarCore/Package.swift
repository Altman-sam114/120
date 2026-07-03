// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RustwarCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RustwarCore", targets: ["RustwarCore"])
    ],
    targets: [
        .target(name: "RustwarCore"),
        .testTarget(
            name: "RustwarCoreTests",
            dependencies: ["RustwarCore"]
        )
    ]
)
