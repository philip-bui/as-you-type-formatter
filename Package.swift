// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "AsYouTypeFormatter",
    products: [
        .library(name: "AsYouTypeFormatter", targets: ["AsYouTypeFormatter"]),
    ],
    targets: [
        .target(name: "AsYouTypeFormatter", path: "Sources")
    ]
)
