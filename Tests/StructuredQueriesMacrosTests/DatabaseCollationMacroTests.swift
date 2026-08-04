import MacroTesting
import StructuredQueriesSQLiteMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct DatabaseCollationMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @DatabaseCollation
        func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
        }
        """
      } expansion: {
        """
        func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
        }

        nonisolated var $caseInsensitive: __macro_local_15caseInsensitivefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: caseInsensitive)
          #sourceLocation()
          #endif
          return __macro_local_15caseInsensitivefMu_(caseInsensitive)
        }

        nonisolated struct __macro_local_15caseInsensitivefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "caseInsensitive"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func customName() {
      assertMacro {
        """
        @DatabaseCollation("case_insensitive")
        func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
        }
        """
      } expansion: {
        """
        func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
        }

        nonisolated var $caseInsensitive: __macro_local_15caseInsensitivefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: caseInsensitive)
          #sourceLocation()
          #endif
          return __macro_local_15caseInsensitivefMu_(caseInsensitive)
        }

        nonisolated struct __macro_local_15caseInsensitivefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "case_insensitive"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func nonStringArgument() {
      assertMacro {
        """
        @DatabaseCollation
        func chronological(_ lhs: Date, _ rhs: Date) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        func chronological(_ lhs: Date, _ rhs: Date) -> CollationOrder {
                                               ┬───
                                  │            ╰─ 🛑 '@DatabaseCollation' functions must take two 'String' arguments

        SQLite only invokes a collating sequence with the text being compared.
                                  │               ✏️ Replace 'Date' with 'String'
                                  ┬───
                                  ╰─ 🛑 '@DatabaseCollation' functions must take two 'String' arguments

        SQLite only invokes a collating sequence with the text being compared.
                                     ✏️ Replace 'Date' with 'String'
          CollationOrder(lhs, rhs)
        }
        """
      } fixes: {
        """
        @DatabaseCollation
        func chronological(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }
        """
      } expansion: {
        """
        func chronological(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }

        nonisolated var $chronological: __macro_local_13chronologicalfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: chronological)
          #sourceLocation()
          #endif
          return __macro_local_13chronologicalfMu_(chronological)
        }

        nonisolated struct __macro_local_13chronologicalfMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "chronological"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func labeledArguments() {
      assertMacro {
        """
        @DatabaseCollation
        func compare(lhs: String, rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }
        """
      } expansion: {
        """
        func compare(lhs: String, rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }

        nonisolated var $compare: __macro_local_7comparefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: compare)
          #sourceLocation()
          #endif
          return __macro_local_7comparefMu_(compare)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "compare"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func throwingFunction() {
      assertMacro {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) throws -> CollationOrder {
          try validate(lhs, rhs)
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) throws -> CollationOrder {
                                                   ┬─────
                                                   ╰─ 🛑 '@DatabaseCollation' functions cannot throw

        SQLite requires a collating sequence to define a total ordering, and it offers no way of surfacing an error from one.
                                                      ✏️ Remove 'throws'
          try validate(lhs, rhs)
        }
        """
      } fixes: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          try validate(lhs, rhs)
        }
        """
      } expansion: {
        """
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          try validate(lhs, rhs)
        }

        nonisolated var $compare: __macro_local_7comparefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: compare)
          #sourceLocation()
          #endif
          return __macro_local_7comparefMu_(compare)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "compare"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func accessControl() {
      assertMacro {
        """
        @DatabaseCollation
        public func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }
        """
      } expansion: {
        """
        public func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }

        public nonisolated var $compare: __macro_local_7comparefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: compare)
          #sourceLocation()
          #endif
          return __macro_local_7comparefMu_(compare)
        }

        public nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "compare"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func packageAccess() {
      assertMacro {
        """
        @DatabaseCollation
        package func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }
        """
      } expansion: {
        """
        package func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }

        package nonisolated var $compare: __macro_local_7comparefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: compare)
          #sourceLocation()
          #endif
          return __macro_local_7comparefMu_(compare)
        }

        package nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "compare"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func fileprivateAccess() {
      assertMacro {
        """
        @DatabaseCollation
        fileprivate func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }
        """
      } expansion: {
        """
        fileprivate func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }

        fileprivate nonisolated var $compare: __macro_local_7comparefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: compare)
          #sourceLocation()
          #endif
          return __macro_local_7comparefMu_(compare)
        }

        fileprivate nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "compare"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func classInstanceMethod() {
      assertMacro {
        """
        class Engine {
          @DatabaseCollation
          func compare(lhs: String, rhs: String) -> CollationOrder {
            CollationOrder(lhs, rhs)
          }
        }
        """
      } expansion: {
        """
        class Engine {
          func compare(lhs: String, rhs: String) -> CollationOrder {
            CollationOrder(lhs, rhs)
          }

          nonisolated var $compare: __macro_local_7comparefMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 2)
            #StructuredQueriesIsolationCheck(collation: compare)
            #sourceLocation()
            #endif
            return __macro_local_7comparefMu_({ [weak self] arg0, arg1 in
                guard let self else {
                  throw StructuredQueriesSQLiteCore._DatabaseCollationDeallocated()
                }
                return self.compare(lhs: arg0, rhs: arg1)
              })
          }

          nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
            public let name = "compare"
            public let body: (String, String) throws -> CollationOrder
            public init(_ body: @escaping (String, String) throws -> CollationOrder) {
              self.body = body
            }
            public func compare(
              _ lhs: String, _ rhs: String
            ) throws -> CollationOrder {
              try self.body(lhs, rhs)
            }
          }
        }
        """
      }
    }

    @Test func classStaticMethodNotWeakified() {
      assertMacro {
        """
        class Engine {
          @DatabaseCollation
          static func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs, rhs)
          }
        }
        """
      } expansion: {
        """
        class Engine {
          static func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
            CollationOrder(lhs, rhs)
          }

          static nonisolated var $compare: __macro_local_7comparefMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 2)
            #StructuredQueriesIsolationCheck(collation: compare)
            #sourceLocation()
            #endif
            return __macro_local_7comparefMu_(compare)
          }

          nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
            public let name = "compare"
            public let body: (String, String) -> CollationOrder
            public init(_ body: @escaping (String, String) -> CollationOrder) {
              self.body = body
            }
            public func compare(
              _ lhs: String, _ rhs: String
            ) -> CollationOrder {
              self.body(lhs, rhs)
            }
          }
        }
        """
      }
    }

    @Test func notAFunction() {
      assertMacro {
        """
        @DatabaseCollation
        var compare: (String, String) -> CollationOrder {
          { $0.compare($1) }
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        ┬─────────────────
        ╰─ 🛑 '@DatabaseCollation' can only be applied to functions
        var compare: (String, String) -> CollationOrder {
          { $0.compare($1) }
        }
        """
      }
    }

    @Test func invalidReturnType() {
      assertMacro {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) -> Bool {
          lhs < rhs
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) -> Bool {
                                                      ┬───
                                                      ╰─ 🛑 '@DatabaseCollation' functions must return 'CollationOrder'
                                                         ✏️ Replace 'Bool' with 'CollationOrder'
          lhs < rhs
        }
        """
      } fixes: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          lhs < rhs
        }
        """
      } expansion: {
        """
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          lhs < rhs
        }

        nonisolated var $compare: __macro_local_7comparefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: compare)
          #sourceLocation()
          #endif
          return __macro_local_7comparefMu_(compare)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "compare"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func missingReturnType() {
      assertMacro {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) {
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) {
                    ┬─────────────────────────────
                    ╰─ 🛑 '@DatabaseCollation' functions must return 'CollationOrder'
                       ✏️ Return 'CollationOrder'
        }
        """
      } fixes: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
        }
        """
      } expansion: {
        """
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
        }

        nonisolated var $compare: __macro_local_7comparefMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(collation: compare)
            #sourceLocation()
            #endif
            return __macro_local_7comparefMu_(compare)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
            public let name = "compare"
            public let body: (String, String) -> CollationOrder
            public init(_ body: @escaping (String, String) -> CollationOrder) {
                self.body = body
            }
            public func compare(
                _ lhs: String, _ rhs: String
            ) -> CollationOrder {
                self.body(lhs, rhs)
            }
        }
        """
      }
    }

    @Test func invalidArgumentCount() {
      assertMacro {
        """
        @DatabaseCollation
        func compare(_ lhs: String) -> CollationOrder {
          .orderedSame
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        func compare(_ lhs: String) -> CollationOrder {
                    ┬──────────────
                    ╰─ 🛑 '@DatabaseCollation' functions must take two 'String' arguments
          .orderedSame
        }
        """
      }
    }

    @Test func mismatchedArgumentTypes() {
      assertMacro {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: Int) -> CollationOrder {
          .same
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: Int) -> CollationOrder {
                                           ┬──
                                           ╰─ 🛑 '@DatabaseCollation' functions must take two 'String' arguments

        SQLite only invokes a collating sequence with the text being compared.
                                              ✏️ Replace 'Int' with 'String'
          .same
        }
        """
      } fixes: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          .same
        }
        """
      } expansion: {
        """
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          .same
        }

        nonisolated var $compare: __macro_local_7comparefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: compare)
          #sourceLocation()
          #endif
          return __macro_local_7comparefMu_(compare)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public let name = "compare"
          public let body: (String, String) -> CollationOrder
          public init(_ body: @escaping (String, String) -> CollationOrder) {
            self.body = body
          }
          public func compare(
            _ lhs: String, _ rhs: String
          ) -> CollationOrder {
            self.body(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func invalidName() {
      assertMacro {
        """
        @DatabaseCollation(name)
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          .orderedSame
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation(name)
                           ┬───
                           ╰─ 🛑 Argument must be a non-empty string literal
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          .orderedSame
        }
        """
      }
    }
  }
}
