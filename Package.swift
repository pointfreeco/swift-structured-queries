// swift-tools-version: 6.1

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
      name: "StructuredQueriesSQLite",
      targets: ["StructuredQueriesSQLite"]
    ),
    .library(
      name: "StructuredQueriesSQLiteCore",
      targets: ["StructuredQueriesSQLiteCore"]
    ),
    .library(
      name: "StructuredQueriesTestSupport",
      targets: ["StructuredQueriesTestSupport"]
    ),
  ],
  traits: [
    .trait(
      name: "StructuredQueriesTagged",
      description: "Introduce StructuredQueries conformances to the swift-tagged package.",
      enabledTraits: []
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.8.1"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.3"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.4"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.5.2"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"602.0.0"),
  ],
  targets: [
    .target(
      name: "StructuredQueries",
      dependencies: [
        "StructuredQueriesCore",
        "StructuredQueriesMacros",
      ]
    ),
    .target(
      name: "StructuredQueriesCore",
      dependencies: [
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(
          name: "Tagged",
          package: "swift-tagged",
          condition: .when(traits: ["StructuredQueriesTagged"])
        ),
      ],
      exclude: ["Symbolic Links/README.md"]
    ),
    .macro(
      name: "StructuredQueriesMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ],
      exclude: ["Symbolic Links/README.md"]
    ),

    .target(
      name: "StructuredQueriesSQLite",
      dependencies: [
        "StructuredQueries",
        "StructuredQueriesSQLiteCore",
        "StructuredQueriesSQLiteMacros",
      ]
    ),
    .target(
      name: "StructuredQueriesSQLiteCore",
      dependencies: [
        "StructuredQueriesCore",
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay")
      ]
    ),
    .macro(
      name: "StructuredQueriesSQLiteMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
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
        "StructuredQueriesMacros",
        "StructuredQueriesSQLiteMacros",
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
        "_StructuredQueriesSQLite",
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
      ]
    ),

    .target(
      name: "_StructuredQueriesSQLite",
      dependencies: [
        "StructuredQueriesSQLite"
      ]
    ),
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

#if !canImport(Darwin)
  package.targets.append(
    .systemLibrary(
      name: "_StructuredQueriesSQLite3",
      providers: [.apt(["libsqlite3-dev"])]
    )
  )

  for index in package.targets.indices {
    if package.targets[index].name == "_StructuredQueriesSQLite" {
      package.targets[index].dependencies.append("_StructuredQueriesSQLite3")
    }
  }
#endif

#if !os(Windows)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
  )
#endif
