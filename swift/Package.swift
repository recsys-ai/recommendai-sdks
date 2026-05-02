// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RecommendAI",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)],
    products: [
        .library(name: "RecommendAI", targets: ["RecommendAI"]),
        .executable(name: "RecommendAISimulation", targets: ["RecommendAISimulation"]),
    ],
    targets: [
        .target(
            name: "RecommendAI",
            path: "Sources/RecommendAI"
        ),
        .executableTarget(
            name: "RecommendAISimulation",
            dependencies: ["RecommendAI"],
            path: "Sources/RecommendAISimulation"
        ),
        .testTarget(
            name: "RecommendAITests",
            dependencies: ["RecommendAI"],
            path: "Tests/RecommendAITests"
        ),
    ]
)
