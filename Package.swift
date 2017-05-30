// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SNSAuthenticationMiddleware",
    targets: [
        Target(name: "SNSAuthenticationMiddleware"),
        Target(name: "SNSAuthenticationMiddlewareExample", dependencies: ["SNSAuthenticationMiddleware"])
    ],
    dependencies: [
        .Package(url: "https://github.com/noppoMan/HexavilleFramework.git", majorVersion: 0, minor: 1)
    ]
)
