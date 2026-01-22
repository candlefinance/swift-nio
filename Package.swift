// swift-tools-version:5.9
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import PackageDescription

// Used only for environment variables, does not make its way
// into the product code.
import class Foundation.ProcessInfo

let swiftAtomics: PackageDescription.Target.Dependency = .product(name: "CandleAtomics", package: "candle-swift-atomics")
let swiftCollections: PackageDescription.Target.Dependency = .product(name: "CandleDequeModule", package: "candle-swift-collections")
let swiftSystem: PackageDescription.Target.Dependency = .product(name: "SystemPackage", package: "candle-swift-system")

// These platforms require a dependency on `NIOPosix` from `NIOHTTP1` to maintain backward
// compatibility with previous NIO versions.
let historicalNIOPosixDependencyRequired: [Platform] = [.macOS, .iOS, .tvOS, .watchOS, .linux, .android]

let strictConcurrencyDevelopment = false

let strictConcurrencySettings: [SwiftSetting] = {
    var initialSettings: [SwiftSetting] = []
    initialSettings.append(contentsOf: [
        .enableUpcomingFeature("StrictConcurrency"),
        .enableUpcomingFeature("InferSendableFromCaptures"),
    ])

    if strictConcurrencyDevelopment {
        // -warnings-as-errors here is a workaround so that IDE-based development can
        // get tripped up on -require-explicit-sendable.
        initialSettings.append(.unsafeFlags(["-require-explicit-sendable", "-warnings-as-errors"]))
    }

    return initialSettings
}()

// This doesn't work when cross-compiling: the privacy manifest will be included in the Bundle and
// Foundation will be linked. This is, however, strictly better than unconditionally adding the
// resource.
#if canImport(Darwin)
let includePrivacyManifest = true
#else
let includePrivacyManifest = false
#endif

let package = Package(
    name: "candle-swift-nio",
    products: [
        .library(name: "CandleNIOCore", targets: ["CandleNIOCore"]),
        .library(name: "CandleNIO", targets: ["CandleNIO"]),
        .library(name: "CandleNIOEmbedded", targets: ["CandleNIOEmbedded"]),
        .library(name: "CandleNIOPosix", targets: ["CandleNIOPosix"]),
        .library(name: "_NIOConcurrency", targets: ["_NIOConcurrency"]),
        .library(name: "CandleNIOTLS", targets: ["CandleNIOTLS"]),
        .library(name: "CandleNIOHTTP1", targets: ["CandleNIOHTTP1"]),
        .library(name: "CandleNIOConcurrencyHelpers", targets: ["CandleNIOConcurrencyHelpers"]),
        .library(name: "CandleNIOFoundationCompat", targets: ["CandleNIOFoundationCompat"]),
        .library(name: "CandleNIOWebSocket", targets: ["CandleNIOWebSocket"]),
        .library(name: "NIOTestUtils", targets: ["NIOTestUtils"]),
        .library(name: "_NIOFileSystem", targets: ["_NIOFileSystem", "NIOFileSystem"]),
        .library(name: "_NIOFileSystemFoundationCompat", targets: ["_NIOFileSystemFoundationCompat"]),
    ],
    targets: [
        // MARK: - Targets

        .target(
            name: "CandleNIOCore",
            dependencies: [
                "CandleNIOConcurrencyHelpers",
                "Candle_NIOBase64",
                "CandleCNIODarwin",
                "CandleCNIOLinux",
                "CandleCNIOWindows",
                "CandleCNIOWASI",
                "Candle_NIODataStructures",
                swiftCollections,
                swiftAtomics,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "Candle_NIODataStructures",
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "Candle_NIOBase64",
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleNIOEmbedded",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOConcurrencyHelpers",
                "Candle_NIODataStructures",
                swiftAtomics,
                swiftCollections,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleNIOPosix",
            dependencies: [
                "CandleCNIOLinux",
                "CandleCNIODarwin",
                "CandleCNIOWindows",
                "CandleNIOConcurrencyHelpers",
                "CandleNIOCore",
                "Candle_NIODataStructures",
                swiftAtomics,
            ],
            exclude: includePrivacyManifest ? [] : ["PrivacyInfo.xcprivacy"],
            resources: includePrivacyManifest ? [.copy("PrivacyInfo.xcprivacy")] : [],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleNIO",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOPosix",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_NIOConcurrency",
            dependencies: [
                .target(name: "CandleNIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "CandleNIOCore",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleNIOFoundationCompat",
            dependencies: [
                .target(name: "CandleNIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "CandleNIOCore",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleCNIOAtomics",
            dependencies: [],
            cSettings: [
                .define("_GNU_SOURCE")
            ]
        ),
        .target(
            name: "CandleCNIOSHA1",
            dependencies: []
        ),
        .target(
            name: "CandleCNIOLinux",
            dependencies: [],
            cSettings: [
                .define("_GNU_SOURCE")
            ]
        ),
        .target(
            name: "CandleCNIODarwin",
            dependencies: [],
            cSettings: [
                .define("__APPLE_USE_RFC_3542")
            ]
        ),
        .target(
            name: "CandleCNIOWindows",
            dependencies: []
        ),
        .target(
            name: "CandleCNIOWASI",
            dependencies: []
        ),
        .target(
            name: "CandleNIOConcurrencyHelpers",
            dependencies: [
                "CandleCNIOAtomics"
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleNIOHTTP1",
            dependencies: [
                .target(name: "CandleNIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "CandleNIOCore",
                "CandleNIOConcurrencyHelpers",
                "CandleCNIOLLHTTP",
                swiftCollections,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleNIOWebSocket",
            dependencies: [
                .target(name: "CandleNIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "CandleNIOCore",
                "CandleNIOHTTP1",
                "CandleCNIOSHA1",
                "Candle_NIOBase64",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleCNIOLLHTTP",
            cSettings: [
                .define("_GNU_SOURCE"),
                .define("LLHTTP_STRICT_MODE"),
            ]
        ),
        .target(
            name: "CandleNIOTLS",
            dependencies: [
                .target(name: "CandleNIO", condition: .when(platforms: historicalNIOPosixDependencyRequired)),
                "CandleNIOCore",
                swiftCollections,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "NIOTestUtils",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOHTTP1",
                swiftAtomics,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_NIOFileSystem",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOPosix",
                "CandleCNIOLinux",
                "CandleCNIODarwin",
                swiftAtomics,
                swiftCollections,
                swiftSystem,
            ],
            path: "Sources/NIOFileSystem",
            exclude: includePrivacyManifest ? [] : ["PrivacyInfo.xcprivacy"],
            resources: includePrivacyManifest ? [.copy("PrivacyInfo.xcprivacy")] : [],
            swiftSettings: strictConcurrencySettings + [
                .define("ENABLE_MOCKING", .when(configuration: .debug))
            ]
        ),
        .target(
            name: "NIOFileSystem",
            dependencies: [
                "_NIOFileSystem"
            ],
            path: "Sources/_NIOFileSystemExported",
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_NIOFileSystemFoundationCompat",
            dependencies: [
                "_NIOFileSystem",
                "CandleNIOFoundationCompat",
            ],
            path: "Sources/NIOFileSystemFoundationCompat",
            swiftSettings: strictConcurrencySettings
        ),

        // MARK: - Examples

        .executableTarget(
            name: "NIOTCPEchoServer",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOTCPEchoClient",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOEchoServer",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOEchoClient",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOHTTP1Server",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOHTTP1",
                "CandleNIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOHTTP1Client",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOHTTP1",
                "CandleNIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOChatServer",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOChatClient",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOConcurrencyHelpers",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOWebSocketServer",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOHTTP1",
                "CandleNIOWebSocket",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOWebSocketClient",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOHTTP1",
                "CandleNIOWebSocket",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOMulticastChat",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOUDPEchoServer",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOUDPEchoClient",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
            ],
            exclude: ["README.md"],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOAsyncAwaitDemo",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOHTTP1",
            ],
            swiftSettings: strictConcurrencySettings
        ),

        // MARK: - Tests

        .executableTarget(
            name: "NIOPerformanceTester",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOHTTP1",
                "CandleNIOFoundationCompat",
                "CandleNIOWebSocket",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .executableTarget(
            name: "NIOCrashTester",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOHTTP1",
                "CandleNIOWebSocket",
                "CandleNIOFoundationCompat",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOCoreTests",
            dependencies: [
                "CandleNIOConcurrencyHelpers",
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOFoundationCompat",
                swiftAtomics,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOEmbeddedTests",
            dependencies: [
                "CandleNIOConcurrencyHelpers",
                "CandleNIOCore",
                "CandleNIOEmbedded",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOPosixTests",
            dependencies: [
                "CandleNIOPosix",
                "CandleNIOCore",
                "CandleNIOFoundationCompat",
                "NIOTestUtils",
                "CandleNIOConcurrencyHelpers",
                "CandleNIOEmbedded",
                "CandleCNIOLinux",
                "CandleCNIODarwin",
                "CandleNIOTLS",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOConcurrencyHelpersTests",
            dependencies: [
                "CandleNIOConcurrencyHelpers",
                "CandleNIOCore",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIODataStructuresTests",
            dependencies: ["Candle_NIODataStructures"],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOBase64Tests",
            dependencies: ["Candle_NIOBase64"],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOHTTP1Tests",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOPosix",
                "CandleNIOHTTP1",
                "CandleNIOFoundationCompat",
                "NIOTestUtils",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOTLSTests",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOTLS",
                "CandleNIOFoundationCompat",
                "NIOTestUtils",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOWebSocketTests",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOWebSocket",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOTestUtilsTests",
            dependencies: [
                "NIOTestUtils",
                "CandleNIOCore",
                "CandleNIOEmbedded",
                "CandleNIOPosix",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOFoundationCompatTests",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOFoundationCompat",
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOTests",
            dependencies: ["CandleNIO"],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOSingletonsTests",
            dependencies: ["CandleNIOCore", "CandleNIOPosix"],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOFileSystemTests",
            dependencies: [
                "CandleNIOCore",
                "_NIOFileSystem",
                swiftAtomics,
                swiftCollections,
                swiftSystem,
            ],
            swiftSettings: strictConcurrencySettings + [
                .define("ENABLE_MOCKING", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "NIOFileSystemIntegrationTests",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOPosix",
                "_NIOFileSystem",
                "CandleNIOFoundationCompat",
            ],
            exclude: [
                // Contains known files and directory structures used
                // for the integration tests. Exclude the whole tree from
                // the build.
                "Test Data"
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .testTarget(
            name: "NIOFileSystemFoundationCompatTests",
            dependencies: [
                "_NIOFileSystem",
                "_NIOFileSystemFoundationCompat",
            ],
            swiftSettings: strictConcurrencySettings
        ),
    ]
)

if Context.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(url: "https://github.com/candlefinance/swift-atomics.git", name: "candle-swift-atomics", branch: "fix-candle-1.2.0"),
        .package(url: "https://github.com/candlefinance/swift-collections.git", name: "candle-swift-collections", branch: "fix-candle-1.1.4"),
        .package(url: "https://github.com/candlefinance/swift-system.git", name: "candle-swift-system", branch: "fix-candle-1.4.2"),
    ]
} else {
    package.dependencies += [
        .package(path: "../swift-atomics", name: "candle-swift-atomics"),
        .package(path: "../swift-collections", name: "candle-swift-collections"),
        .package(path: "../swift-system", name: "candle-swift-system"),
    ]
}

// ---    STANDARD CROSS-REPO SETTINGS DO NOT EDIT   --- //
for target in package.targets {
    switch target.type {
    case .regular, .test, .executable:
        var settings = target.swiftSettings ?? []
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
        settings.append(.enableUpcomingFeature("MemberImportVisibility"))
        target.swiftSettings = settings
    case .macro, .plugin, .system, .binary:
        ()  // not applicable
    @unknown default:
        ()  // we don't know what to do here, do nothing
    }
}
// --- END: STANDARD CROSS-REPO SETTINGS DO NOT EDIT --- //
