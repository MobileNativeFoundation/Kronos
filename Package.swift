// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Kronos",
    products: [
        .library(name: "Kronos", targets: ["Kronos"]),
    ],
    targets: [
        .target(name: "Kronos", path: "Sources"),
        .testTarget(name: "KronosTests", dependencies: ["Kronos"]),
    ],
    swiftLanguageVersions: [.v4, .v4_2]
)
