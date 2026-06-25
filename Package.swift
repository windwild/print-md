// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PrintMD",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PrintMD", targets: ["PrintMD"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark.git", from: "0.8.0")
    ],
    targets: [
        .executableTarget(
            name: "PrintMD",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
