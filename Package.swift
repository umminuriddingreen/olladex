// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Olladex",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Olladex", targets: ["Olladex"]),
    ],
    targets: [
        .executableTarget(name: "Olladex"),
        .testTarget(name: "OlladexTests", dependencies: ["Olladex"]),
    ]
)
