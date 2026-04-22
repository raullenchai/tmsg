// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "tmsg",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "tmsg",
            dependencies: ["SwiftTerm"],
            path: "tmsg"
        ),
    ]
)
