// swift-tools-version: 6.3.2

import PackageDescription

let package = Package(
    name: "ScrechCam",
    products: [
        .library(name: "ScrechCam", targets: ["ScrechCam"])
    ],
    targets: [
        .target(name: "ScrechCam")
    ]
)
