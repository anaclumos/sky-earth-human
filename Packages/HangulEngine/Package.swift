// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "HangulEngine",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "HangulEngine", targets: ["HangulEngine"]),
  ],
  targets: [
    .target(name: "HangulEngine"),
    .testTarget(name: "HangulEngineTests", dependencies: ["HangulEngine"]),
  ],
  swiftLanguageModes: [.v6]
)
