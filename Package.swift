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
        .package(url: "https://github.com/swiftlang/swift-syntax", exact: "510.0.2")
    ],

    targets: [

        .macro(
            name: "DufapMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        .target(name: "Dufap", dependencies: ["DufapMacros"]),

        .testTarget(
            name: "DufapTests",
            dependencies: [
                "Dufap",
                "DufapMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        ),
    ]
)
