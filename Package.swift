// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MenuTerm",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", .upToNextMinor(from: "1.20.0"))
    ],
    targets: [
        .executableTarget(
            name: "MenuTerm",
            dependencies: [.product(name: "SwiftTerm", package: "SwiftTerm")],
            path: "Sources/MenuTerm"
        )
    ]
)
