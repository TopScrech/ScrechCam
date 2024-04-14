// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ScrechCam",
    products: [
        .library(
            name: "ScrechCam",
            targets: ["ScrechCam"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ScrechCam",
            dependencies: []
        )
    ]
)
