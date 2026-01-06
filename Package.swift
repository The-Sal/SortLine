// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SortLine",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "SortLine",
            targets: ["SortLine"]
        ),
    ],
    targets: [
        .executableTarget(name: "SortLine")
    ]
)
