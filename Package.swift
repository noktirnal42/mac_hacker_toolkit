// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacHackerToolkit",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "MacHackerToolkit",
            targets: ["MacHackerToolkit"]
        )
    ],
    dependencies: [
        // Swift Collections for advanced data structures
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        // Swift Algorithms
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        // Yams for YAML configuration parsing
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
        // Swift Crypto for additional cryptographic operations
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MacHackerToolkit",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Crypto", package: "swift-crypto"),
            ],
            path: "MacHackerToolkit/Sources",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"]),
            ]
        ),
        .testTarget(
            name: "MacHackerToolkitTests",
            dependencies: ["MacHackerToolkit"],
            path: "MacHackerToolkit/Tests"
        )
    ]
)
