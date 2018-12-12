// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "HexavilleAuth",
    products: [
        .library(name: "HexavilleAuth", targets: ["HexavilleAuth"]),
        .executable(name: "hexaville-todo-example", targets: ["HexavilleAuthExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/noppoMan/HexavilleFramework.git", .upToNextMajor(from: "1.0.0-rc.1"))
    ],
    targets: [
        .target(name: "HexavilleAuth", dependencies: [
            "HexavilleFramework"
        ]),
        .target(name: "HexavilleAuthExample", dependencies: ["HexavilleAuth"])
    ]
)
