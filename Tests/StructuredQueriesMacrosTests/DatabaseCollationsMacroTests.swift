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
            return StructuredQueriesCore.CustomCollation("caseInsensitive", caseInsensitive)
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
            return StructuredQueriesCore.CustomCollation("caseInsensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func customName() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          @DatabaseCollation("case_insensitive")
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
            return StructuredQueriesCore.CustomCollation("case_insensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func emptyCustomName() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          @DatabaseCollation("")
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      } diagnostics: {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          @DatabaseCollation("")
                             ┬─
                             ╰─ 🛑 Argument must be a non-empty string literal
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      }
    }

    @Test func `Diagnose using @DatabaseCollation outside of @DatabaseCollations extension`() {
      assertMacro {
        """
        @DatabaseCollation("case_insensitive")
        func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation("case_insensitive")
        ┬─────────────────────────────────────
        ╰─ 🛑 '@DatabaseCollation' has no effect outside of a '@DatabaseCollations' extension
        func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
        }
        """
      }
    }

    @Test func `Diagnose and fix-it for @DatabaseCollation without constraint`() {
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
           ✏️ Insert 'where Self == CustomCollation'
        extension Collation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
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
            return StructuredQueriesCore.CustomCollation("caseInsensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func `Diagnose and fix-it for @DatabaseCollations on wrong constraint`() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == NamedCollation {
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
           ✏️ Replace constraint with 'Self == CustomCollation'
        extension Collation where Self == NamedCollation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
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
            return StructuredQueriesCore.CustomCollation("caseInsensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func `Diagnose and fix-it for @DatabaseCollations on wrong extension`() {
      assertMacro {
        """
        @DatabaseCollations
        extension CustomCollation {
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
           ✏️ Replace with 'extension Collation where Self == CustomCollation'
        extension CustomCollation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
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
            return StructuredQueriesCore.CustomCollation("caseInsensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func `Diagnose @DatabaseCollations on wrong type`() {
      assertMacro {
        """
        @DatabaseCollations
        struct Collations {
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
        struct Collations {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        }
        """
      }
    }

    @Test func `Ignore computed variables`() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          var nocase: Bool { true }
        }
        """
      } expansion: {
        """
        extension Collation where Self == CustomCollation {
          var nocase: Bool { true }
        }
        """
      }
    }

    @Test func `Diagnose and fix-it for @DatabaseCollations with non-static functions`() {
      assertMacro {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        var what: Int { 42 }
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
        var what: Int { 42 }
        }
        """
      } fixes: {
        """
        @DatabaseCollations
        extension Collation where Self == CustomCollation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        var what: Int { 42 }
        }
        """
      } expansion: {
        """
        extension Collation where Self == CustomCollation {
          static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
          }
        var what: Int { 42 }

          static nonisolated var caseInsensitive: Self {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(collation: caseInsensitive)
            #sourceLocation()
            #endif
            return StructuredQueriesCore.CustomCollation("caseInsensitive", caseInsensitive)
          }
        }
        """
      }
    }

    @Test func `Diagnose non-string arguments`() {
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
