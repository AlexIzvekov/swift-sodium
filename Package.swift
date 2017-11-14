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
        .package(url: "https://github.com/Bouke/CLibSodium.git", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "Sodium",
            dependencies: [],
            path: ".",
            exclude: ["Sodium/libsodium"],
            sources: ["Sodium"]),
    ]
)
