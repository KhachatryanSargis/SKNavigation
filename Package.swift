// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SKNavigation",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SKNavigation",
            targets: ["SKNavigation"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/KhachatryanSargis/SKCore.git", branch: "main")
    ],
    targets: [
        .target(
            name: "SKNavigation",
            dependencies: ["SKCore"],
            path: "Sources/SKNavigation"
        ),
        .testTarget(
            name: "SKNavigationTests",
            dependencies: ["SKNavigation"],
            path: "Tests/SKNavigationTests"
        )
    ]
)
