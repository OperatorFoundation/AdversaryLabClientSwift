// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "AdversaryLabClientSwift",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "AdversaryLabClientSwift",
            targets: ["AdversaryLabClientSwift"]),
        .library(name: "RawPacket", targets: ["RawPacket"])
    ],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", from: "0.0.3"),
        .package(url: "https://github.com/OperatorFoundation/SwiftPCAP.git", from: "1.1.7"),
        .package(url: "https://github.com/OperatorFoundation/Datable.git", from: "3.0.2"),
        .package(url: "https://github.com/OperatorFoundation/Song.git", from: "0.0.19"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.0.1"),
        .package(url: "https://github.com/OperatorFoundation/Bits.git", from: "1.0.3"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", from: "1.0.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11"),
    ],
    targets: [
        .target(
            name: "AdversaryLabClientSwift",
            dependencies: ["SwiftPCAP", "SwiftQueue", "RawPacket", .product(name: "Symphony", package: "Song"), .product(name: "ArgumentParser", package: "swift-argument-parser"), "Bits", "InternetProtocols", "Datable", "ZIPFoundation"]),
        .target(name: "RawPacket"),
        .testTarget(
            name: "AdversaryLabClientSwiftTests",
            dependencies: ["AdversaryLabClientSwift"]),
    ]
)
