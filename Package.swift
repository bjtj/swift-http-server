// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftHttpServer",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "SwiftHttpServer",
      targets: ["SwiftHttpServer"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/IBM-Swift/BlueSocket.git", from: "1.0.200")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "SwiftHttpServer",
      dependencies: ["Socket"],
      path: "Sources/swift-http-server"),
    .testTarget(
      name: "swift-http-serverTests",
      dependencies: ["SwiftHttpServer"]),
  ]
)
