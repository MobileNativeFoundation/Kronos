// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Kronos",
    products: [
        .library(name: "Kronos", targets: ["Kronos"]),
        .library(name: "Kronos-Dynamic", type: .dynamic, targets: ["Kronos"]),
    ],
    targets: [
        .target(
            name: "Kronos",
            path: "Sources",
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(name: "KronosTests", dependencies: ["Kronos"]),
    ]
)
