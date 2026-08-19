import MacroTesting
import StructuredQueriesSQLiteMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct DatabaseCollationsMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      } expansion: {
        """
        extension Collation where Self == CustomCollation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }

          static nonisolated var caseInsensitive: Self {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(collation: caseInsensitive)
            #sourceLocation()
            #endif
            return StructuredQueriesSQLiteCore.CustomCollation("caseInsensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func accessControl() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          public static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      } expansion: {
        """
        extension Collation where Self == CustomCollation {
          public static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }

          public static nonisolated var caseInsensitive: Self {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(collation: caseInsensitive)
            #sourceLocation()
            #endif
            return StructuredQueriesSQLiteCore.CustomCollation("caseInsensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func unconstrainedExtension() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      } diagnostics: {
        """
        @DatabaseCollations
        ┬──────────────────
        ╰─ 🛑 '@DatabaseCollations' can only be applied to an 'extension Collation where Self == CustomCollation'
        extension Collation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      }
    }

    @Test func nonStaticFunction() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      } diagnostics: {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
               ┬──────────────
               ╰─ 🛑 '@DatabaseCollations' functions must be 'static'
                  ✏️ Insert 'static'
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      } fixes: {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      } expansion: {
        """
        extension Collation where Self == CustomCollation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }

          static nonisolated var caseInsensitive: Self {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(collation: caseInsensitive)
            #sourceLocation()
            #endif
            return StructuredQueriesSQLiteCore.CustomCollation("caseInsensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func nonStringArgument() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          static func chronological(_ lhs: Date, _ rhs: Date) -> CollationOrder {
            CollationOrder(lhs, rhs)
          }
        }
        """
      } diagnostics: {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          static func chronological(_ lhs: Date, _ rhs: Date) -> CollationOrder {
                                   ┬─────────────────────────
                                   ╰─ 🛑 '@DatabaseCollations' functions must take two 'String' arguments
            CollationOrder(lhs, rhs)
          }
        }
        """
      }
    }
  }
}
