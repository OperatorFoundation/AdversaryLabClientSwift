// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdversaryLabClientSwift",
    platforms: [.macOS(.v10_15)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "AdversaryLabClient", targets: ["AdversaryLabClient"]),
        .executable(
            name: "AdversaryLabClientSwift",
            targets: ["AdversaryLabClientSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", from: "0.0.3"),
        .package(url: "https://github.com/OperatorFoundation/SwiftPCAP.git", from: "1.1.6"),
        .package(url: "https://github.com/OperatorFoundation/Datable.git", from: "2.0.0"),
        .package(url: "https://github.com/OperatorFoundation/rethink-swift.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "AdversaryLabClient",
            dependencies: ["SwiftPCAP", "SwiftQueue", "Datable", "Rethink"]),
        .target(
            name: "AdversaryLabClientSwift",
            dependencies: ["SwiftPCAP", "SwiftQueue", "AdversaryLabClient", "Rethink"]),
        .testTarget(
            name: "AdversaryLabClientSwiftTests",
            dependencies: ["AdversaryLabClientSwift"]),
    ]
)
