// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "AdversaryLabClientSwift",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "AdversaryLabClient", targets: ["AdversaryLabClient"]),
        .library(name: "AdversaryLabClientCore", targets: ["AdversaryLabClientCore"]),
        .library(name: "RawPacket", targets: ["RawPacket"])
    ],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", from: "0.0.3"),
        .package(url: "https://github.com/OperatorFoundation/PacketStream.git", from: "0.0.1"),
        .package(url: "https://github.com/OperatorFoundation/PacketCaptureLibpcap.git", from: "0.0.2"),
        .package(url: "https://github.com/OperatorFoundation/PacketCaptureBPF.git", from: "0.0.1"),
        .package(url: "https://github.com/OperatorFoundation/Datable.git", from: "3.0.2"),
        .package(url: "https://github.com/OperatorFoundation/Song.git", from: "0.1.3"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.0.1"),
        .package(url: "https://github.com/OperatorFoundation/Bits.git", from: "1.0.3"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", from: "1.1.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11"),
    ],
    targets: [
        .target(
            name: "AdversaryLabClient",
            dependencies: [
                "AdversaryLabClientCore", "PacketStream",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PacketCaptureLibpcap", package: "PacketCaptureLibpcap", condition: .when(platforms: [.linux])),
                .product(name: "PacketCaptureBPF", package: "PacketCaptureBPF", condition: .when(platforms: [.macOS])),
        ]),
        .target(name: "AdversaryLabClientCore", dependencies: [
            "PacketStream", "SwiftQueue", "RawPacket", "Bits", "InternetProtocols", "Datable", "ZIPFoundation",
            .product(name: "Symphony", package: "Song"),
            .product(name: "PacketCaptureLibpcap", package: "PacketCaptureLibpcap", condition: .when(platforms: [.linux])),
            .product(name: "PacketCaptureBPF", package: "PacketCaptureBPF", condition: .when(platforms: [.macOS])),
        ]),
        .target(name: "RawPacket"),
        .testTarget(
            name: "AdversaryLabClientCoreTests",
            dependencies: ["AdversaryLabClientCore"]),
    ]
)
