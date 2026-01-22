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

let swiftAtomics: PackageDescription.Target.Dependency = .product(name: "CandleAtomics", package: "swift-atomics")
let swiftCollections: PackageDescription.Target.Dependency = .product(name: "CandleDequeModule", package: "swift-collections")
let swiftSystem: PackageDescription.Target.Dependency = .product(name: "SystemPackage", package: "swift-system")

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
    name: "swift-nio",
    products: [
        .library(name: "CandleNIOCore", targets: ["CandleNIOCore"]),
        .library(name: "CandleNIO", targets: ["CandleNIO"]),
        .library(name: "CandleNIOEmbedded", targets: ["CandleNIOEmbedded"]),
        .library(name: "CandleNIOPosix", targets: ["CandleNIOPosix"]),
        .library(name: "CandleNIOTLS", targets: ["CandleNIOTLS"]),
        .library(name: "CandleNIOHTTP1", targets: ["CandleNIOHTTP1"]),
        .library(name: "CandleNIOConcurrencyHelpers", targets: ["CandleNIOConcurrencyHelpers"]),
        .library(name: "CandleNIOFoundationCompat", targets: ["CandleNIOFoundationCompat"]),
        .library(name: "CandleNIOWebSocket", targets: ["CandleNIOWebSocket"]),
    ],
    targets: [
        // MARK: - Targets

        .target(
            name: "CandleNIOCore",
            dependencies: [
                "CandleNIOConcurrencyHelpers",
                "_Candle_NIOBase64",
                "CandleCNIODarwin",
                "CandleCNIOLinux",
                "CandleCNIOWindows",
                "CandleCNIOWASI",
                "_Candle_NIODataStructures",
                swiftCollections,
                swiftAtomics,
            ],
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_Candle_NIODataStructures",
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "_Candle_NIOBase64",
            swiftSettings: strictConcurrencySettings
        ),
        .target(
            name: "CandleNIOEmbedded",
            dependencies: [
                "CandleNIOCore",
                "CandleNIOConcurrencyHelpers",
                "_Candle_NIODataStructures",
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
                "_Candle_NIODataStructures",
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
                "_Candle_NIOBase64",
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
    ]
)

if Context.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
    package.dependencies += [
        .package(name: "candle-swift-atomics", url: "https://github.com/candlefinance/candle-swift-atomics.git", branch: "fix-candle-1.2.0"),
        .package(name: "candle-swift-collections", url: "https://github.com/candlefinance/candle-swift-collections.git", branch: "fix-candle-1.1.4"),
        .package(name: "candle-swift-system", url: "https://github.com/candlefinance/candle-swift-system.git", branch: "fix-candle-1.4.2"),
    ]
} else {
    package.dependencies += [
        .package(name: "candle-swift-atomics", path: "../swift-atomics"),
        .package(name: "candle-swift-collections", path: "../swift-collections"),
        .package(name: "candle-swift-system", path: "../swift-system"),
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
