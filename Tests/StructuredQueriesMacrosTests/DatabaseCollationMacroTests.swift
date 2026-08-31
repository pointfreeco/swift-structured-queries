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
          return __macro_local_15caseInsensitivefMu_()
        }

        nonisolated func __macro_local_15caseInsensitivefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          caseInsensitive(arg0, arg1)
        }

        nonisolated struct __macro_local_15caseInsensitivefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "caseInsensitive"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_15caseInsensitivefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
          return __macro_local_15caseInsensitivefMu_()
        }

        nonisolated func __macro_local_15caseInsensitivefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          caseInsensitive(arg0, arg1)
        }

        nonisolated struct __macro_local_15caseInsensitivefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "case_insensitive"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_15caseInsensitivefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
                                  │            ╰─ 🛑 '@DatabaseCollation' functions must take two 'String', two 'UnsafeRawBufferPointer', two 'UTF8Span', or two 'Span<UInt8>' arguments
                                  │               ✏️ Replace 'Date' with 'String'
                                  ┬───
                                  ╰─ 🛑 '@DatabaseCollation' functions must take two 'String', two 'UnsafeRawBufferPointer', two 'UTF8Span', or two 'Span<UInt8>' arguments
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
          return __macro_local_13chronologicalfMu_()
        }

        nonisolated func __macro_local_13chronologicalfMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          chronological(arg0, arg1)
        }

        nonisolated struct __macro_local_13chronologicalfMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "chronological"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_13chronologicalfMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
          return __macro_local_7comparefMu_()
        }

        nonisolated func __macro_local_7comparefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          compare(lhs: arg0, rhs: arg1)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "compare"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
          }
        }
        """
      }
    }

    @Test func rawBuffers() {
      assertMacro {
        """
        @DatabaseCollation
        func caseInsensitive(
          _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
        ) -> CollationOrder {
          CollationOrder(lhs.count, rhs.count)
        }
        """
      } expansion: {
        """
        func caseInsensitive(
          _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
        ) -> CollationOrder {
          CollationOrder(lhs.count, rhs.count)
        }

        nonisolated var $caseInsensitive: __macro_local_15caseInsensitivefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: caseInsensitive)
          #sourceLocation()
          #endif
          return __macro_local_15caseInsensitivefMu_()
        }

        nonisolated func __macro_local_15caseInsensitivefMu0_(
          _ arg0: UnsafeRawBufferPointer, _ arg1: UnsafeRawBufferPointer
        ) -> CollationOrder {
          caseInsensitive(arg0, arg1)
        }

        nonisolated struct __macro_local_15caseInsensitivefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "caseInsensitive"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_15caseInsensitivefMu0_(lhs, rhs)
          }
        }
        """
      }
    }

    @Test func utf8SpanBuffers() {
      assertMacro {
        """
        @DatabaseCollation
        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *)
        func canonical(_ lhs: UTF8Span, _ rhs: UTF8Span) -> CollationOrder {
          if lhs.isCanonicallyLessThan(rhs) { return .ascending }
          if rhs.isCanonicallyLessThan(lhs) { return .descending }
          return .same
        }
        """
      } expansion: {
        """
        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *)
        func canonical(_ lhs: UTF8Span, _ rhs: UTF8Span) -> CollationOrder {
          if lhs.isCanonicallyLessThan(rhs) { return .ascending }
          if rhs.isCanonicallyLessThan(lhs) { return .descending }
          return .same
        }

        #if DEBUG
        func __macro_local_23canonicalIsolationProbefMu_() {
        }
        #endif

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *) nonisolated var $canonical: __macro_local_9canonicalfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: __macro_local_23canonicalIsolationProbefMu_)
          #sourceLocation()
          #endif
          return __macro_local_9canonicalfMu_()
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *) nonisolated func __macro_local_9canonicalfMu0_(
          _ arg0: UTF8Span, _ arg1: UTF8Span
        ) -> CollationOrder {
          canonical(arg0, arg1)
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *) nonisolated struct __macro_local_9canonicalfMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "canonical"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            do {
              let lhsSpan = try UTF8Span(validating: lhs.assumingMemoryBound(to: UInt8.self).span)
              let rhsSpan = try UTF8Span(validating: rhs.assumingMemoryBound(to: UInt8.self).span)
              return __macro_local_9canonicalfMu0_(lhsSpan, rhsSpan)
            } catch {
              return lhs.elementsEqual(rhs)
              ? .same
              : lhs.lexicographicallyPrecedes(rhs) ? .ascending : .descending
            }
          }
        }
        """
      }
    }

    @Test func byteSpanBuffers() {
      assertMacro {
        """
        @DatabaseCollation
        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *)
        func byteCount(_ lhs: Span<UInt8>, _ rhs: Span<UInt8>) -> CollationOrder {
          CollationOrder(lhs.count, rhs.count)
        }
        """
      } expansion: {
        """
        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *)
        func byteCount(_ lhs: Span<UInt8>, _ rhs: Span<UInt8>) -> CollationOrder {
          CollationOrder(lhs.count, rhs.count)
        }

        #if DEBUG
        func __macro_local_23byteCountIsolationProbefMu_() {
        }
        #endif

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *) nonisolated var $byteCount: __macro_local_9byteCountfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: __macro_local_23byteCountIsolationProbefMu_)
          #sourceLocation()
          #endif
          return __macro_local_9byteCountfMu_()
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *) nonisolated func __macro_local_9byteCountfMu0_(
          _ arg0: Span<UInt8>, _ arg1: Span<UInt8>
        ) -> CollationOrder {
          byteCount(arg0, arg1)
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *) nonisolated struct __macro_local_9byteCountfMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "byteCount"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_9byteCountfMu0_(lhs.assumingMemoryBound(to: UInt8.self).span, rhs.assumingMemoryBound(to: UInt8.self).span)
          }
        }
        """
      }
    }

    @Test func mixedArguments() {
      assertMacro {
        """
        @DatabaseCollation
        func caseInsensitive(_ lhs: String, _ rhs: UnsafeRawBufferPointer) -> CollationOrder {
          CollationOrder(lhs.count, rhs.count)
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        func caseInsensitive(_ lhs: String, _ rhs: UnsafeRawBufferPointer) -> CollationOrder {
                            ┬─────────────────────────────────────────────
                            ╰─ 🛑 '@DatabaseCollation' functions must take two 'String', two 'UnsafeRawBufferPointer', two 'UTF8Span', or two 'Span<UInt8>' arguments
                               ✏️ Replace 'UnsafeRawBufferPointer' with 'String'
          CollationOrder(lhs.count, rhs.count)
        }
        """
      } fixes: {
        """
        @DatabaseCollation
        func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs.count, rhs.count)
        }
        """
      } expansion: {
        """
        func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs.count, rhs.count)
        }

        nonisolated var $caseInsensitive: __macro_local_15caseInsensitivefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: caseInsensitive)
          #sourceLocation()
          #endif
          return __macro_local_15caseInsensitivefMu_()
        }

        nonisolated func __macro_local_15caseInsensitivefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          caseInsensitive(arg0, arg1)
        }

        nonisolated struct __macro_local_15caseInsensitivefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "caseInsensitive"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_15caseInsensitivefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
          }
        }
        """
      }
    }

    @Test func asyncFunction() {
      assertMacro {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) async -> CollationOrder {
          CollationOrder(lhs, rhs)
        }
        """
      } diagnostics: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) async -> CollationOrder {
                                                   ┬────
                                                   ╰─ 🛑 '@DatabaseCollation' functions cannot be asynchronous
                                                      ✏️ Remove 'async'
          CollationOrder(lhs, rhs)
        }
        """
      } fixes: {
        """
        @DatabaseCollation
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }
        """
      } expansion: {
        """
        func compare(_ lhs: String, _ rhs: String) -> CollationOrder {
          CollationOrder(lhs, rhs)
        }

        nonisolated var $compare: __macro_local_7comparefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(collation: compare)
          #sourceLocation()
          #endif
          return __macro_local_7comparefMu_()
        }

        nonisolated func __macro_local_7comparefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          compare(arg0, arg1)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "compare"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
          return __macro_local_7comparefMu_()
        }

        nonisolated func __macro_local_7comparefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          compare(arg0, arg1)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "compare"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
          return __macro_local_7comparefMu_()
        }

        public nonisolated func __macro_local_7comparefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          compare(arg0, arg1)
        }

        public nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "compare"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
          return __macro_local_7comparefMu_()
        }

        package nonisolated func __macro_local_7comparefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          compare(arg0, arg1)
        }

        package nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "compare"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
          return __macro_local_7comparefMu_()
        }

        fileprivate nonisolated func __macro_local_7comparefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          compare(arg0, arg1)
        }

        fileprivate nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "compare"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
        #"""
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
            return __macro_local_7comparefMu_(self)
          }

          nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
            public var name: String {
              "compare"
            }
            private weak var base: Engine?
            public init(_ base: Engine) {
              self.base = base
            }
            public func compare(
              _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
            ) -> CollationOrder {
              guard let base else {
                reportIssue(
                  """
                  Failed to invoke 'compare'; 'Engine' was deallocated
                  """
                )
                return lhs.elementsEqual(rhs)
                ? .same
                : lhs.lexicographicallyPrecedes(rhs) ? .ascending : .descending
              }
              return base.compare(lhs: String(decoding: lhs, as: UTF8.self), rhs: String(decoding: rhs, as: UTF8.self))
            }
          }
        }
        """#
      }
    }

    @Test func structInstanceMethod() {
      assertMacro {
        """
        struct Engine {
          @DatabaseCollation
          func compare(lhs: String, rhs: String) -> CollationOrder {
            CollationOrder(lhs, rhs)
          }
        }
        """
      } expansion: {
        """
        struct Engine {
          func compare(lhs: String, rhs: String) -> CollationOrder {
            CollationOrder(lhs, rhs)
          }

          nonisolated var $compare: __macro_local_7comparefMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 2)
            #StructuredQueriesIsolationCheck(collation: compare)
            #sourceLocation()
            #endif
            return __macro_local_7comparefMu_(self)
          }

          nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
            public var name: String {
              "compare"
            }
            private let base: Engine
            public init(_ base: Engine) {
              self.base = base
            }
            public func compare(
              _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
            ) -> CollationOrder {
              return base.compare(lhs: String(decoding: lhs, as: UTF8.self), rhs: String(decoding: rhs, as: UTF8.self))
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
            return __macro_local_7comparefMu_()
          }

          static nonisolated func __macro_local_7comparefMu0_(
            _ arg0: String, _ arg1: String
          ) -> CollationOrder {
            compare(arg0, arg1)
          }

          nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
            public var name: String {
              "compare"
            }
            public init() {
            }
            public func compare(
              _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
            ) -> CollationOrder {
              return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
          return __macro_local_7comparefMu_()
        }

        nonisolated func __macro_local_7comparefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          compare(arg0, arg1)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "compare"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
            return __macro_local_7comparefMu_()
        }

        nonisolated func __macro_local_7comparefMu0_(
            _ arg0: String, _ arg1: String
        ) -> CollationOrder {
            compare(arg0, arg1)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
            public var name: String {
                "compare"
            }
            public init() {
            }
            public func compare(
                _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
            ) -> CollationOrder {
                return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
                    ╰─ 🛑 '@DatabaseCollation' functions must take two 'String', two 'UnsafeRawBufferPointer', two 'UTF8Span', or two 'Span<UInt8>' arguments
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
                                           ╰─ 🛑 '@DatabaseCollation' functions must take two 'String', two 'UnsafeRawBufferPointer', two 'UTF8Span', or two 'Span<UInt8>' arguments
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
          return __macro_local_7comparefMu_()
        }

        nonisolated func __macro_local_7comparefMu0_(
          _ arg0: String, _ arg1: String
        ) -> CollationOrder {
          compare(arg0, arg1)
        }

        nonisolated struct __macro_local_7comparefMu_: StructuredQueriesSQLiteCore.DatabaseCollation {
          public var name: String {
            "compare"
          }
          public init() {
          }
          public func compare(
            _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
          ) -> CollationOrder {
            return __macro_local_7comparefMu0_(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
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
