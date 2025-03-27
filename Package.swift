// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Quest",
    platforms: [
       .macOS(.v13)
    ],
    products: [
        .executable(
            name: "revenuecat-sign",
            targets: ["RevenueCatSignatureCLI"]
        ),
        .executable(
            name: "asr-cli",
            targets: ["ASRCLI"]
        ),
        .executable(
            name: "stress-test",
            targets: ["StressTestCLI"]
        ),
        .library(
            name: "TencentCloudAPI",
            targets: ["TencentCloudAPI"]
        ),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🔑 JSON Web Token (JWT) support
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        // 🤖 OpenAI SDK
        .package(url: "https://github.com/MacPaw/OpenAI.git", branch: "main"),
        // 🔑 Swift Crypto
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
        // 🧰 Swift Async Algorithms
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        // 🌐 Async HTTP Client
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.2"),
        // 📝 Argument Parser
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",    
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "Crypto", package: "swift-crypto"),
                .target(name: "TencentCloudAPI"),
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(
            name: "RevenueCatSignatureCLI",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .executableTarget(
            name: "ASRCLI",
            dependencies: [
                .target(name: "TencentCloudAPI"),
            ]
        ),
        .executableTarget(
            name: "StressTestCLI",
            dependencies: [
                .target(name: "TencentCloudAPI"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ]
        ),
        .target(
            name: "TencentCloudAPI",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "NIOCore", package: "swift-nio"),
            ],
            resources: [
                .process("README.md")
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "TencentCloudAPITests",
            dependencies: [
                .target(name: "TencentCloudAPI"),
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
    .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
] }
