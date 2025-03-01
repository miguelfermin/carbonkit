// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CarbonKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "CarbonKit", targets: ["CarbonKit"]),
        .library(name: "CarbonUI", targets: ["CarbonUI"]),
        .library(name: "CarbonCore", targets: ["CarbonCore"]),
    ],
    targets: [
        .target(name: "CarbonCore"),
        .target(name: "CarbonKit", dependencies: ["CarbonCore", "CarbonUI"]),
        .target(name: "CarbonUI", dependencies: ["CarbonCore"]),
        
        .testTarget(name: "CarbonKitTests", dependencies: ["CarbonKit"]),
    ]
)
