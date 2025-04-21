// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-structured-queries",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "StructuredQueries",
      targets: ["StructuredQueries"]
    ),
    .library(
      name: "StructuredQueriesCore",
      targets: ["StructuredQueriesCore"]
    ),
    .library(
      name: "StructuredQueriesTestSupport",
      targets: ["StructuredQueriesTestSupport"]
    ),
    .library(
      name: "_StructuredQueriesSQLite",
      targets: ["StructuredQueriesSQLite"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.8.1"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.1"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.5.2"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"601.0.0"),
  ],
  targets: [
    .target(
      name: "StructuredQueriesCore",
      dependencies: [
        "StructuredQueriesSupport",
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ]
    ),
    .target(
      name: "StructuredQueries",
      dependencies: [
        "StructuredQueriesCore",
        "StructuredQueriesMacros",
      ]
    ),
    .macro(
      name: "StructuredQueriesMacros",
      dependencies: [
        "StructuredQueriesSupport",
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "StructuredQueriesSQLite",
      dependencies: [
        "StructuredQueries"
      ]
    ),
    .target(
      name: "StructuredQueriesTestSupport",
      dependencies: [
        "StructuredQueriesCore",
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
      ]
    ),
    .testTarget(
      name: "StructuredQueriesMacrosTests",
      dependencies: [
        "StructuredQueries",
        "StructuredQueriesMacros",
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
    .testTarget(
      name: "StructuredQueriesTests",
      dependencies: [
        "StructuredQueries",
        "StructuredQueriesSQLite",
        "StructuredQueriesTestSupport",
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
      ]
    ),

    .target(name: "StructuredQueriesSupport"),
  ],
  swiftLanguageModes: [.v6]
)

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("MemberImportVisibility")
  // .unsafeFlags([
  //   "-Xfrontend",
  //   "-warn-long-function-bodies=50",
  //   "-Xfrontend",
  //   "-warn-long-expression-type-checking=50",
  // ])
]

for index in package.targets.indices {
  package.targets[index].swiftSettings = swiftSettings
}

#if !os(Darwin)
  package.targets.append(
    .systemLibrary(
      name: "StructuredQueriesSQLite3",
      providers: [.apt(["libsqlite3-dev"])]
    )
  )

  for index in package.targets.indices {
    if package.targets[index].name == "StructuredQueriesSQLite" {
      package.targets[index].dependencies.append("StructuredQueriesSQLite3")
    }
  }
#endif

#if !os(Windows)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
