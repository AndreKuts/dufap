// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Dufap",

    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],

    products: [
        .library(
            name: "Dufap",
            targets: ["Dufap"]
        ),
    ],

    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"601.0.0-prerelease"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.2.0"),
    ],

    targets: [

        .macro(
            name: "DufapMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        .target(name: "Dufap", dependencies: ["DufapMacros"]),

        .testTarget(
            name: "DufapTests",
            dependencies: [
                "DufapMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ]
        ),
    ]
)
