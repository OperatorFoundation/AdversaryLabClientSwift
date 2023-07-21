// swift-tools-version:5.8
import PackageDescription

#if os(macOS)
let package = Package(
    name: "AdversaryLabClientSwift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AdversaryLabClient", targets: ["AdversaryLabClient"]),
        .library(name: "AdversaryLabClientCore", targets: ["AdversaryLabClientCore"]),
        .library(name: "RawPacket", targets: ["RawPacket"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.2"),
        .package(url: "https://github.com/OperatorFoundation/Bits.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Chord.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Datable.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/PacketCaptureBPF.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/PacketStream.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Song.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/swift-netutils.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", branch: "main"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.12")
    ],
    targets: [
        .executableTarget(
            name: "AdversaryLabClient",
            dependencies: [
                "AdversaryLabClientCore",
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]),
        .target(name: "AdversaryLabClientCore", dependencies: [
            "Bits",
            "Chord",
            "Datable",
            "InternetProtocols",
            "PacketCaptureBPF",
            "PacketStream",
            "RawPacket",
            "SwiftQueue",
            "ZIPFoundation",
            .product(name: "NetUtils", package: "swift-netutils"),
            .product(name: "Symphony", package: "Song"),
        ]),
        .target(name: "RawPacket"),
        .testTarget(
            name: "AdversaryLabClientCoreTests",
            dependencies: ["AdversaryLabClientCore"]),
    ]
)
#else
let package = Package(
    name: "AdversaryLabClientSwift",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "AdversaryLabClient", targets: ["AdversaryLabClient"]),
        .library(name: "AdversaryLabClientCore", targets: ["AdversaryLabClientCore"]),
        .library(name: "RawPacket", targets: ["RawPacket"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.2"),
        .package(url: "https://github.com/OperatorFoundation/Bits.git", branch: "main"),
        .package(url:"https://github.com/OperatorFoundation/Chord.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Datable.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/PacketCaptureLibpcap.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/PacketStream.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Song.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/swift-netutils.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", branch: "main"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.12"),
    ],
    targets: [
        .executableTarget(
            name: "AdversaryLabClient",
            dependencies: [
                "AdversaryLabClientCore",
                //"PacketStream",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "AdversaryLabClientCore", dependencies: [
            "Bits",
            "Chord",
            "Datable",
            "InternetProtocols",
            "PacketStream",
            "RawPacket",
            "SwiftQueue",
            "ZIPFoundation",
            .product(name: "NetUtils", package: "swift-netutils"),
            .product(name: "Symphony", package: "Song"),
            .product(name: "PacketCaptureLibpcap", package: "PacketCaptureLibpcap"),
        ]),
        .target(name: "RawPacket"),
        .testTarget(
            name: "AdversaryLabClientCoreTests",
            dependencies: ["AdversaryLabClientCore"]),
    ]
)
#endif
