// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "HexavilleAuth",
    targets: [
        Target(name: "HexavilleAuth"),
        Target(name: "HexavilleAuthExample", dependencies: ["HexavilleAuth"])
    ],
    dependencies: [
        .Package(url: "https://github.com/noppoMan/HexavilleFramework.git", majorVersion: 0, minor: 1)
    ]
)
