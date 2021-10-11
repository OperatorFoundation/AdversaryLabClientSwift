// swift-tools-version:5.3
import PackageDescription

#if os(macOS)
let package = Package(
    name: "AdversaryLabClientSwift",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "AdversaryLabClient", targets: ["AdversaryLabClient"]),
        .library(name: "AdversaryLabClientCore", targets: ["AdversaryLabClientCore"]),
        .library(name: "RawPacket", targets: ["RawPacket"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.1"),
        .package(url: "https://github.com/OperatorFoundation/Bits.git", from: "2.0.1"),
        .package(url: "https://github.com/OperatorFoundation/Chord.git", from: "0.0.13"),
        .package(url: "https://github.com/OperatorFoundation/Datable.git", from: "3.1.1"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", from: "2.1.1"),
        .package(url: "https://github.com/OperatorFoundation/PacketCaptureBPF.git", from: "0.2.9"),
        .package(url: "https://github.com/OperatorFoundation/PacketStream.git", from: "0.2.1"),
        .package(url: "https://github.com/OperatorFoundation/Song.git", from: "0.2.1"),
        .package(name: "NetUtils", url: "https://github.com/OperatorFoundation/swift-netutils.git", from: "4.3.0"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", from: "0.1.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.12")
    ],
    targets: [
        .target(
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
            "NetUtils",
            "PacketCaptureBPF",
            "PacketStream",
            "RawPacket",
            "SwiftQueue",
            "ZIPFoundation",
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
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "AdversaryLabClient", targets: ["AdversaryLabClient"]),
        .library(name: "AdversaryLabClientCore", targets: ["AdversaryLabClientCore"]),
        .library(name: "RawPacket", targets: ["RawPacket"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.4.3"),
        .package(url: "https://github.com/OperatorFoundation/Bits.git", from: "1.0.3"),
        .package(url:"https://github.com/OperatorFoundation/Chord.git", from: "0.0.12"),
        .package(url: "https://github.com/OperatorFoundation/Datable.git", from: "3.0.4"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", from: "1.1.1"),
        .package(url: "https://github.com/OperatorFoundation/PacketCaptureLibpcap.git", from: "0.2.3"),
        .package(url: "https://github.com/OperatorFoundation/PacketStream.git", from: "0.0.1"),
        .package(url: "https://github.com/OperatorFoundation/Song.git", from: "0.1.7"),
        .package(name: "NetUtils", url: "https://github.com/svdo/swift-netutils.git", from: "4.2.0"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", from: "0.1.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11"),
    ],
    targets: [
        .target(
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
            "NetUtils",
            "PacketStream",
            "RawPacket",
            "SwiftQueue",
            "ZIPFoundation",
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
