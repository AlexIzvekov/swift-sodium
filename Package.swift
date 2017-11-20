// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swift-sodium",
    products: [
        .library(
            name: "Sodium",
            targets: ["Sodium"]),
    ],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Clibsodium.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Sodium",
            dependencies: [],
            path: ".",
            exclude: ["Sodium/libsodium"],
            sources: ["Sodium"]),
        .testTarget(
            name: "SodiumTests",
            dependencies: ["Sodium"]),
    ]
)
