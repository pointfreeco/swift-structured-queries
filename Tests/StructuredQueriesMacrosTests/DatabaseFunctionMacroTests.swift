import MacroTesting
import StructuredQueriesSQLiteMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct DatabaseFunctionMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @DatabaseFunction
        func currentDate() -> Date {
          Date()
        }
        """
      } expansion: {
        #"""
        func currentDate() -> Date {
          Date()
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_() -> Date {
          currentDate()
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: __macro_local_11currentDatefMu0_()
            )
            .queryBinding
          }
        }
        """#
      }
    }

    @Test func customName() {
      assertMacro {
        """
        @DatabaseFunction("current_date")
        func currentDate() -> Date {
          Date()
        }
        """
      } expansion: {
        #"""
        func currentDate() -> Date {
          Date()
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_() -> Date {
          currentDate()
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public var name: String {
            "current_date"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: __macro_local_11currentDatefMu0_()
            )
            .queryBinding
          }
        }
        """#
      }
    }

    @Test func customRepresentation() {
      assertMacro {
        """
        @DatabaseFunction(as: (([String].JSONRepresentation) -> [String].JSONRepresentation).self)
        func jsonCapitalize(_ strings: [String]) -> [String] {
          strings.map { $0.capitalized }
        }
        """
      } expansion: {
        #"""
        func jsonCapitalize(_ strings: [String]) -> [String] {
          strings.map { $0.capitalized }
        }

        nonisolated var $jsonCapitalize: __macro_local_14jsonCapitalizefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: jsonCapitalize)
          #sourceLocation()
          #endif
          return __macro_local_14jsonCapitalizefMu_()
        }

        nonisolated func __macro_local_14jsonCapitalizefMu0_(_ arg0: [String]) -> [String] {
          jsonCapitalize(arg0)
        }

        nonisolated struct __macro_local_14jsonCapitalizefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = [String].JSONRepresentation
          public typealias Output = [String].JSONRepresentation
          public var name: String {
            "jsonCapitalize"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth([String].JSONRepresentation.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(_ strings: some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation>) -> some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(strings))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let strings = try decoder.decode(_requireQueryRepresentable([String].JSONRepresentation.self))
            guard let strings else {
              throw InvalidInvocation()
            }
            return [String].JSONRepresentation(
              queryOutput: __macro_local_14jsonCapitalizefMu0_(strings)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func customDeterminism() {
      assertMacro {
        """
        @DatabaseFunction(isDeterministic: true)
        func fortyTwo() -> Int {
          42
        }
        """
      } expansion: {
        #"""
        func fortyTwo() -> Int {
          42
        }

        nonisolated var $fortyTwo: __macro_local_8fortyTwofMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: fortyTwo)
          #sourceLocation()
          #endif
          return __macro_local_8fortyTwofMu_()
        }

        nonisolated func __macro_local_8fortyTwofMu0_() -> Int {
          fortyTwo()
        }

        nonisolated struct __macro_local_8fortyTwofMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Int
          public var name: String {
            "fortyTwo"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            true
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Int> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Int(
              queryOutput: __macro_local_8fortyTwofMu0_()
            )
            .queryBinding
          }
        }
        """#
      }
    }

    @Test func unnamedArgument() {
      assertMacro {
        """
        @DatabaseFunction
        func currentDate(_ format: String) -> Date? {
          dateFormatter.date(from: format)
        }
        """
      } expansion: {
        #"""
        func currentDate(_ format: String) -> Date? {
          dateFormatter.date(from: format)
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_(_ arg0: String) -> Date? {
          currentDate(arg0)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String>) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: __macro_local_11currentDatefMu0_(format)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func namedArgument() {
      assertMacro {
        """
        @DatabaseFunction
        func currentDate(format: String) -> Date? {
          dateFormatter.date(from: format)
        }
        """
      } expansion: {
        #"""
        func currentDate(format: String) -> Date? {
          dateFormatter.date(from: format)
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_(_ arg0: String) -> Date? {
          currentDate(format: arg0)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(format: some StructuredQueriesCore.QueryExpression<String>) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: __macro_local_11currentDatefMu0_(format)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func unnamedArgumentDefault() {
      assertMacro {
        """
        @DatabaseFunction
        func currentDate(_ format: String = "") -> Date? {
          dateFormatter.date(from: format)
        }
        """
      } expansion: {
        #"""
        func currentDate(_ format: String = "") -> Date? {
          dateFormatter.date(from: format)
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_(_ arg0: String) -> Date? {
          currentDate(arg0)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: __macro_local_11currentDatefMu0_(format)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func namedArgumentDefault() {
      assertMacro {
        """
        @DatabaseFunction
        func currentDate(format: String = "") -> Date? {
          dateFormatter.date(from: format)
        }
        """
      } expansion: {
        #"""
        func currentDate(format: String = "") -> Date? {
          dateFormatter.date(from: format)
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_(_ arg0: String) -> Date? {
          currentDate(format: arg0)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(format: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: __macro_local_11currentDatefMu0_(format)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func multipleArguments() {
      assertMacro {
        """
        @DatabaseFunction
        func concat(first: String = "", second: String = "") -> String {
          first + second
        }
        """
      } expansion: {
        #"""
        func concat(first: String = "", second: String = "") -> String {
          first + second
        }

        nonisolated var $concat: __macro_local_6concatfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: concat)
          #sourceLocation()
          #endif
          return __macro_local_6concatfMu_()
        }

        nonisolated func __macro_local_6concatfMu0_(_ arg0: String, _ arg1: String) -> String {
          concat(first: arg0, second: arg1)
        }

        nonisolated struct __macro_local_6concatfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (String, String)
          public typealias Output = String
          public var name: String {
            "concat"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
            argumentCount += _columnWidth(String.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(first: some StructuredQueriesCore.QueryExpression<String> = "", second: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<String> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(first), \(second))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let first = try decoder.decode(_requireQueryRepresentable(String.self))
            let second = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let first else {
              throw InvalidInvocation()
            }
            guard let second else {
              throw InvalidInvocation()
            }
            return String(
              queryOutput: __macro_local_6concatfMu0_(first, second)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func wrongDeclDiagnostic() {
      assertMacro {
        """
        @DatabaseFunction
        struct Foo {
        }
        """
      } diagnostics: {
        """
        @DatabaseFunction
        ╰─ 🛑 '@DatabaseFunction' must be applied to a function or computed property
        struct Foo {
        }
        """
      }
    }

    @Test func unnamedArgumentNilDefault() {
      assertMacro {
        """
        @DatabaseFunction
        func currentDate(_ format: String? = nil) -> Date? {
          dateFormatter.date(from: format)
        }
        """
      } expansion: {
        #"""
        func currentDate(_ format: String? = nil) -> Date? {
          dateFormatter.date(from: format)
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_(_ arg0: String?) -> Date? {
          currentDate(arg0)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String?
          public typealias Output = Date?
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String?.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String?> = String?.none) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(_requireQueryRepresentable(String?.self))
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: __macro_local_11currentDatefMu0_(format)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func untypedThrows() {
      assertMacro {
        """
        @DatabaseFunction
        func currentDate() throws -> Date {
          Date()
        }
        """
      } expansion: {
        #"""
        func currentDate() throws -> Date {
          Date()
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_() throws -> Date {
          currentDate()
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            do {
              return Date(
                queryOutput: try __macro_local_11currentDatefMu0_()
              )
              .queryBinding
            } catch {
              return .invalid(error)
            }
          }
        }
        """#
      }
    }

    @Test func typedThrows() {
      assertMacro {
        """
        @DatabaseFunction
        func currentDate() throws(MyError) -> Date {
          Date()
        }
        """
      } expansion: {
        #"""
        func currentDate() throws(MyError) -> Date {
          Date()
        }

        nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        nonisolated func __macro_local_11currentDatefMu0_() throws -> Date {
          currentDate()
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            do {
              return Date(
                queryOutput: try __macro_local_11currentDatefMu0_()
              )
              .queryBinding
            } catch {
              return .invalid(error)
            }
          }
        }
        """#
      }
    }

    @Test func publicAccess() {
      assertMacro {
        """
        @DatabaseFunction
        public func currentDate() -> Date {
          Date()
        }
        """
      } expansion: {
        #"""
        public func currentDate() -> Date {
          Date()
        }

        public nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        public nonisolated func __macro_local_11currentDatefMu0_() -> Date {
          currentDate()
        }

        public nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: __macro_local_11currentDatefMu0_()
            )
            .queryBinding
          }
        }
        """#
      }
    }

    @Test func staticAccess() {
      assertMacro {
        """
        @DatabaseFunction
        static func currentDate() -> Date {
          Date()
        }
        """
      } expansion: {
        #"""
        static func currentDate() -> Date {
          Date()
        }

        static nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        static nonisolated func __macro_local_11currentDatefMu0_() -> Date {
          currentDate()
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: __macro_local_11currentDatefMu0_()
            )
            .queryBinding
          }
        }
        """#
      }
    }

    // TODO: Get working
    @Test func variadic() {
      assertMacro {
        """
        @DatabaseFunction
        func concat(_ strings: String...) -> String {
          strings.joined()
        }
        """
      } diagnostics: {
        """
        @DatabaseFunction
        func concat(_ strings: String...) -> String {
                                     ┬──
                                     ╰─ 🛑 Variadic arguments are not supported
          strings.joined()
        }
        """
      }
    }

    @Test func asyncFunction() {
      assertMacro {
        """
        @DatabaseFunction
        func currentTemperature() async -> Double {
          await weatherService.temperature
        }
        """
      } diagnostics: {
        """
        @DatabaseFunction
        func currentTemperature() async -> Double {
                                  ┬────
                                  ╰─ 🛑 '@DatabaseFunction' functions cannot be asynchronous
                                     ✏️ Remove 'async'
          await weatherService.temperature
        }
        """
      } fixes: {
        """
        @DatabaseFunction
        func currentTemperature() -> Double {
          await weatherService.temperature
        }
        """
      } expansion: {
        #"""
        func currentTemperature() -> Double {
          await weatherService.temperature
        }

        nonisolated var $currentTemperature: __macro_local_18currentTemperaturefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: currentTemperature)
          #sourceLocation()
          #endif
          return __macro_local_18currentTemperaturefMu_()
        }

        nonisolated func __macro_local_18currentTemperaturefMu0_() -> Double {
          currentTemperature()
        }

        nonisolated struct __macro_local_18currentTemperaturefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Double
          public var name: String {
            "currentTemperature"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Double> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Double(
              queryOutput: __macro_local_18currentTemperaturefMu0_()
            )
            .queryBinding
          }
        }
        """#
      }
    }

    @Test func asyncProperty() {
      assertMacro {
        """
        @DatabaseFunction
        var currentTemperature: Double {
          get async {
            await weatherService.temperature
          }
        }
        """
      } diagnostics: {
        """
        @DatabaseFunction
        var currentTemperature: Double {
          get async {
              ┬────
              ╰─ 🛑 '@DatabaseFunction' properties cannot be asynchronous
                 ✏️ Remove 'async'
            await weatherService.temperature
          }
        }
        """
      } fixes: {
        """
        @DatabaseFunction
        var currentTemperature: Double {
          get {
            await weatherService.temperature
          }
        }
        """
      } expansion: {
        #"""
        var currentTemperature: Double {
          get {
            await weatherService.temperature
          }
        }

        #if DEBUG
        func __macro_local_32currentTemperatureIsolationProbefMu_() {
        }
        #endif

        nonisolated var $currentTemperature: __macro_local_18currentTemperaturefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(property: __macro_local_32currentTemperatureIsolationProbefMu_)
          #sourceLocation()
          #endif
          return __macro_local_18currentTemperaturefMu_()
        }

        nonisolated func __macro_local_18currentTemperaturefMu0_() -> Double {
          currentTemperature
        }

        nonisolated struct __macro_local_18currentTemperaturefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
          public typealias Input = ()
          public typealias Output = Double
          public typealias QueryValue = Output
          public var name: String {
            "currentTemperature"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Double(
              queryOutput: __macro_local_18currentTemperaturefMu0_()
            )
            .queryBinding
          }
          public var queryFragment: StructuredQueriesCore.QueryFragment {
            "\(quote: self.name)()"
          }
        }
        """#
      }
    }

    @Test func availability() {
      assertMacro {
        """
        @available(*, unavailable)
        @DatabaseFunction
        func currentDate() -> Date {
          Date()
        }
        """
      } expansion: {
        #"""
        @available(*, unavailable)
        func currentDate() -> Date {
          Date()
        }

        @available(*, unavailable) nonisolated var $currentDate: __macro_local_11currentDatefMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 2)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_()
        }

        @available(*, unavailable) nonisolated func __macro_local_11currentDatefMu0_() -> Date {
          currentDate()
        }

        @available(*, unavailable) nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public var name: String {
            "currentDate"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: __macro_local_11currentDatefMu0_()
            )
            .queryBinding
          }
        }
        """#
      }
    }

    @Test func backticks() {
      assertMacro {
        """
        @DatabaseFunction
        public func `default`() -> Int {
          42
        }
        """
      } expansion: {
        #"""
        public func `default`() -> Int {
          42
        }

        public nonisolated var $default: __macro_local_7defaultfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: `default`)
          #sourceLocation()
          #endif
          return __macro_local_7defaultfMu_()
        }

        public nonisolated func __macro_local_7defaultfMu0_() -> Int {
          `default`()
        }

        public nonisolated struct __macro_local_7defaultfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Int
          public var name: String {
            "default"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Int> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Int(
              queryOutput: __macro_local_7defaultfMu0_()
            )
            .queryBinding
          }
        }
        """#
      }
    }

    @Test func voidReturnType() {
      assertMacro {
        """
        @DatabaseFunction
        public func void() {
          print("...")
        }
        """
      } expansion: {
        #"""
        public func void() {
          print("...")
        }

        public nonisolated var $void: __macro_local_4voidfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: void)
          #sourceLocation()
          #endif
          return __macro_local_4voidfMu_()
        }

        public nonisolated func __macro_local_4voidfMu0_() -> Swift.Void {
          void()
        }

        public nonisolated struct __macro_local_4voidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Swift.Void
          public var name: String {
            "void"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Swift.Void> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            __macro_local_4voidfMu0_()
            return .null
          }
        }
        """#
      }
      assertMacro {
        """
        @DatabaseFunction
        public func void() throws {
          throw Failure()
        }
        """
      } expansion: {
        #"""
        public func void() throws {
          throw Failure()
        }

        public nonisolated var $void: __macro_local_4voidfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: void)
          #sourceLocation()
          #endif
          return __macro_local_4voidfMu_()
        }

        public nonisolated func __macro_local_4voidfMu0_() throws -> Swift.Void {
          void()
        }

        public nonisolated struct __macro_local_4voidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Swift.Void
          public var name: String {
            "void"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Swift.Void> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            do {
              try __macro_local_4voidfMu0_()
              return .null
            } catch {
              return .invalid(error)
            }
          }
        }
        """#
      }
    }

    @Test func formatting() {
      assertMacro {
        """
        @DatabaseFunction
        func min(
          _ x: Int,
          _ y: Int
        ) {
          Swift.min(x, y)
        }
        """
      } expansion: {
        #"""
        func min(
          _ x: Int,
          _ y: Int
        ) {
          Swift.min(x, y)
        }

        nonisolated var $min: __macro_local_3minfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: min)
          #sourceLocation()
          #endif
          return __macro_local_3minfMu_()
        }

        nonisolated func __macro_local_3minfMu0_(_ arg0: Int, _ arg1: Int) -> Swift.Void {
          min(arg0, arg1)
        }

        nonisolated struct __macro_local_3minfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Int, Int)
          public typealias Output = Swift.Void
          public var name: String {
            "min"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(Int.self)
            argumentCount += _columnWidth(Int.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(
            _ x: some StructuredQueriesCore.QueryExpression<Int>,
            _ y: some StructuredQueriesCore.QueryExpression<Int>
          ) -> some StructuredQueriesCore.QueryExpression<Swift.Void> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(x), \(y))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let x = try decoder.decode(_requireQueryRepresentable(Int.self))
            let y = try decoder.decode(_requireQueryRepresentable(Int.self))
            guard let x else {
              throw InvalidInvocation()
            }
            guard let y else {
              throw InvalidInvocation()
            }
            __macro_local_3minfMu0_(x, y)
            return .null
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
      assertMacro {
        """
        @DatabaseFunction
        func min(
          x: Int,
          y: Int
        ) {
          Swift.min(x, y)
        }
        """
      } expansion: {
        #"""
        func min(
          x: Int,
          y: Int
        ) {
          Swift.min(x, y)
        }

        nonisolated var $min: __macro_local_3minfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: min)
          #sourceLocation()
          #endif
          return __macro_local_3minfMu_()
        }

        nonisolated func __macro_local_3minfMu0_(_ arg0: Int, _ arg1: Int) -> Swift.Void {
          min(x: arg0, y: arg1)
        }

        nonisolated struct __macro_local_3minfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Int, Int)
          public typealias Output = Swift.Void
          public var name: String {
            "min"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(Int.self)
            argumentCount += _columnWidth(Int.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(
            x: some StructuredQueriesCore.QueryExpression<Int>,
            y: some StructuredQueriesCore.QueryExpression<Int>
          ) -> some StructuredQueriesCore.QueryExpression<Swift.Void> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(x), \(y))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let x = try decoder.decode(_requireQueryRepresentable(Int.self))
            let y = try decoder.decode(_requireQueryRepresentable(Int.self))
            guard let x else {
              throw InvalidInvocation()
            }
            guard let y else {
              throw InvalidInvocation()
            }
            __macro_local_3minfMu0_(x, y)
            return .null
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func argumentCount() {
      assertMacro {
        """
        @DatabaseFunction
        func isValid(_ reminder: Reminder, _ override: Bool = false) -> Bool {
          !reminder.title.isEmpty || override
        }
        """
      } expansion: {
        #"""
        func isValid(_ reminder: Reminder, _ override: Bool = false) -> Bool {
          !reminder.title.isEmpty || override
        }

        nonisolated var $isValid: __macro_local_7isValidfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(function: isValid)
          #sourceLocation()
          #endif
          return __macro_local_7isValidfMu_()
        }

        nonisolated func __macro_local_7isValidfMu0_(_ arg0: Reminder, _ arg1: Bool) -> Bool {
          isValid(arg0, arg1)
        }

        nonisolated struct __macro_local_7isValidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Reminder, Bool)
          public typealias Output = Bool
          public var name: String {
            "isValid"
          }
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(Reminder.self)
            argumentCount += _columnWidth(Bool.self)
            return argumentCount
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func callAsFunction(_ reminder: some StructuredQueriesCore.QueryExpression<Reminder>, _ override: some StructuredQueriesCore.QueryExpression<Bool> = false) -> some StructuredQueriesCore.QueryExpression<Bool> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(reminder), \(override))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let reminder = try decoder.decode(_requireQueryRepresentable(Reminder.self))
            let override = try decoder.decode(_requireQueryRepresentable(Bool.self))
            guard let reminder else {
              throw InvalidInvocation()
            }
            guard let override else {
              throw InvalidInvocation()
            }
            return Bool(
              queryOutput: __macro_local_7isValidfMu0_(reminder, override)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }

    @Test func computedProperty() {
      assertMacro {
        """
        @DatabaseFunction
        var now: Date {
          Date()
        }
        """
      } expansion: {
        #"""
        var now: Date {
          Date()
        }

        #if DEBUG
        func __macro_local_17nowIsolationProbefMu_() {
        }
        #endif

        nonisolated var $now: __macro_local_3nowfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(property: __macro_local_17nowIsolationProbefMu_)
          #sourceLocation()
          #endif
          return __macro_local_3nowfMu_()
        }

        nonisolated func __macro_local_3nowfMu0_() -> Date {
          now
        }

        nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
          public typealias Input = ()
          public typealias Output = Date
          public typealias QueryValue = Output
          public var name: String {
            "now"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: __macro_local_3nowfMu0_()
            )
            .queryBinding
          }
          public var queryFragment: StructuredQueriesCore.QueryFragment {
            "\(quote: self.name)()"
          }
        }
        """#
      }
    }

    @Test func computedPropertyGetter() {
      assertMacro {
        """
        @DatabaseFunction
        var now: Date {
          get {
            Date()
          }
        }
        """
      } expansion: {
        #"""
        var now: Date {
          get {
            Date()
          }
        }

        #if DEBUG
        func __macro_local_17nowIsolationProbefMu_() {
        }
        #endif

        nonisolated var $now: __macro_local_3nowfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(property: __macro_local_17nowIsolationProbefMu_)
          #sourceLocation()
          #endif
          return __macro_local_3nowfMu_()
        }

        nonisolated func __macro_local_3nowfMu0_() -> Date {
          now
        }

        nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
          public typealias Input = ()
          public typealias Output = Date
          public typealias QueryValue = Output
          public var name: String {
            "now"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: __macro_local_3nowfMu0_()
            )
            .queryBinding
          }
          public var queryFragment: StructuredQueriesCore.QueryFragment {
            "\(quote: self.name)()"
          }
        }
        """#
      }
    }

    @Test func computedThrowingProperty() {
      assertMacro {
        """
        @DatabaseFunction
        var now: Date {
          get throws {
            Date()
          }
        }
        """
      } expansion: {
        #"""
        var now: Date {
          get throws {
            Date()
          }
        }

        #if DEBUG
        func __macro_local_17nowIsolationProbefMu_() {
        }
        #endif

        nonisolated var $now: __macro_local_3nowfMu_ {
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 1)
          #StructuredQueriesIsolationCheck(property: __macro_local_17nowIsolationProbefMu_)
          #sourceLocation()
          #endif
          return __macro_local_3nowfMu_()
        }

        nonisolated func __macro_local_3nowfMu0_() throws -> Date {
          try now
        }

        nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
          public typealias Input = ()
          public typealias Output = Date
          public typealias QueryValue = Output
          public var name: String {
            "now"
          }
          public var argumentCount: Int? {
            0
          }
          public var isDeterministic: Bool {
            false
          }
          public init() {
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: try __macro_local_3nowfMu0_()
            )
            .queryBinding
          }
          public var queryFragment: StructuredQueriesCore.QueryFragment {
            "\(quote: self.name)()"
          }
        }
        """#
      }
    }

    @Test func staticProperty() {
      assertMacro {
        """
        enum Functions {
          @DatabaseFunction
          static var now: Date {
            Date()
          }
        }
        """
      } expansion: {
        #"""
        enum Functions {
          static var now: Date {
            Date()
          }

          #if DEBUG

            static func __macro_local_17nowIsolationProbefMu_() {
          }
          #endif

          static nonisolated var $now: __macro_local_3nowfMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 2)
            #StructuredQueriesIsolationCheck(property: __macro_local_17nowIsolationProbefMu_)
            #sourceLocation()
            #endif
            return __macro_local_3nowfMu_()
          }

          static nonisolated func __macro_local_3nowfMu0_() -> Date {
            now
          }

          nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
            public typealias Input = ()
            public typealias Output = Date
            public typealias QueryValue = Output
            public var name: String {
              "now"
            }
            public var argumentCount: Int? {
              0
            }
            public var isDeterministic: Bool {
              false
            }
            public init() {
            }
            public func invoke(
              _ decoder: inout some StructuredQueriesCore.QueryDecoder
            ) throws -> StructuredQueriesCore.QueryBinding {
              return Date(
                queryOutput: __macro_local_3nowfMu0_()
              )
              .queryBinding
            }
            public var queryFragment: StructuredQueriesCore.QueryFragment {
              "\(quote: self.name)()"
            }
          }
        }
        """#
      }
    }

    @Suite struct AggregateTests {
      @Test func basics() {
        assertMacro {
          """
          @DatabaseFunction
          func sum(_ xs: some Sequence<Int>) -> Int {
            xs.reduce(into: 0, +=)
          }
          """
        } expansion: {
          """
          func sum(_ xs: some Sequence<Int>) -> Int {
            xs.reduce(into: 0, +=)
          }

          #if DEBUG
          func __macro_local_17sumIsolationProbefMu_() {
          }
          #endif

          nonisolated var $sum: __macro_local_3sumfMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(function: __macro_local_17sumIsolationProbefMu_)
            #sourceLocation()
            #endif
            return __macro_local_3sumfMu_()
          }

          nonisolated func __macro_local_3sumfMu0_(_ arg0: some Sequence<Int>) -> Int {
            sum(arg0)
          }

          nonisolated struct __macro_local_3sumfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = Int
            public typealias Output = Int
            public var name: String {
              "sum"
            }
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(Int.self)
              return argumentCount
            }
            public var isDeterministic: Bool {
              false
            }
            public init() {
            }
            public func callAsFunction(_ xs: some StructuredQueriesCore.QueryExpression<Int>, order: (some QueryExpression)? = Bool?.none, filter: (some QueryExpression<Bool>)? = Bool?.none) -> some StructuredQueriesCore.QueryExpression<Int> {
              StructuredQueriesCore.$_isSelecting.withValue(false) {
                StructuredQueriesCore.AggregateFunctionExpression(
                  self.name, xs, order: order, filter: filter
                )
              }
            }
            public func step(
              _ decoder: inout some StructuredQueriesCore.QueryDecoder
            ) throws -> Int {
              let xs = try decoder.decode(_requireQueryRepresentable(Int.self))
              guard let xs else {
                throw InvalidInvocation()
              }
              return xs
            }
            public func invoke(_ arguments: some Sequence<Int>) -> QueryBinding {
              return Int(queryOutput: __macro_local_3sumfMu0_(arguments)).queryBinding
            }
            private struct InvalidInvocation: Error {
            }
          }
          """
        }
      }

      @Test func namedArgument() {
        assertMacro {
          """
          @DatabaseFunction
          func sum(of xs: some Sequence<Int>) -> Int {
            xs.reduce(into: 0, +=)
          }
          """
        } expansion: {
          """
          func sum(of xs: some Sequence<Int>) -> Int {
            xs.reduce(into: 0, +=)
          }

          #if DEBUG
          func __macro_local_17sumIsolationProbefMu_() {
          }
          #endif

          nonisolated var $sum: __macro_local_3sumfMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(function: __macro_local_17sumIsolationProbefMu_)
            #sourceLocation()
            #endif
            return __macro_local_3sumfMu_()
          }

          nonisolated func __macro_local_3sumfMu0_(_ arg0: some Sequence<Int>) -> Int {
            sum(of: arg0)
          }

          nonisolated struct __macro_local_3sumfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = Int
            public typealias Output = Int
            public var name: String {
              "sum"
            }
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(Int.self)
              return argumentCount
            }
            public var isDeterministic: Bool {
              false
            }
            public init() {
            }
            public func callAsFunction(of xs: some StructuredQueriesCore.QueryExpression<Int>, order: (some QueryExpression)? = Bool?.none, filter: (some QueryExpression<Bool>)? = Bool?.none) -> some StructuredQueriesCore.QueryExpression<Int> {
              StructuredQueriesCore.$_isSelecting.withValue(false) {
                StructuredQueriesCore.AggregateFunctionExpression(
                  self.name, xs, order: order, filter: filter
                )
              }
            }
            public func step(
              _ decoder: inout some StructuredQueriesCore.QueryDecoder
            ) throws -> Int {
              let xs = try decoder.decode(_requireQueryRepresentable(Int.self))
              guard let xs else {
                throw InvalidInvocation()
              }
              return xs
            }
            public func invoke(_ arguments: some Sequence<Int>) -> QueryBinding {
              return Int(queryOutput: __macro_local_3sumfMu0_(arguments)).queryBinding
            }
            private struct InvalidInvocation: Error {
            }
          }
          """
        }
      }

      @Test func multipleArguments() {
        assertMacro {
          """
          @DatabaseFunction
          func joined(_ arguments: some Sequence<(String, separator: String)>) -> String? {
            var iterator = arguments.makeIterator()
            guard var (result, _) = iterator.next() else { return nil }
            while let (string, separator) = iterator.next() {
              result.append(separator)
              result.append(string)
            }
            return result
          }
          """
        } expansion: {
          """
          func joined(_ arguments: some Sequence<(String, separator: String)>) -> String? {
            var iterator = arguments.makeIterator()
            guard var (result, _) = iterator.next() else { return nil }
            while let (string, separator) = iterator.next() {
              result.append(separator)
              result.append(string)
            }
            return result
          }

          #if DEBUG
          func __macro_local_20joinedIsolationProbefMu_() {
          }
          #endif

          nonisolated var $joined: __macro_local_6joinedfMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(function: __macro_local_20joinedIsolationProbefMu_)
            #sourceLocation()
            #endif
            return __macro_local_6joinedfMu_()
          }

          nonisolated func __macro_local_6joinedfMu0_(_ arg0: some Sequence<(String, separator: String)>) -> String? {
            joined(arg0)
          }

          nonisolated struct __macro_local_6joinedfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = (String, separator: String)
            public typealias Output = String?
            public var name: String {
              "joined"
            }
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(String.self)
              argumentCount += _columnWidth(String.self)
              return argumentCount
            }
            public var isDeterministic: Bool {
              false
            }
            public init() {
            }
            public func callAsFunction(_ p0: some StructuredQueriesCore.QueryExpression<String>, separator: some StructuredQueriesCore.QueryExpression<String>, order: (some QueryExpression)? = Bool?.none, filter: (some QueryExpression<Bool>)? = Bool?.none) -> some StructuredQueriesCore.QueryExpression<String?> {
              StructuredQueriesCore.$_isSelecting.withValue(false) {
                StructuredQueriesCore.AggregateFunctionExpression(
                  self.name, p0, separator, order: order, filter: filter
                )
              }
            }
            public func step(
              _ decoder: inout some StructuredQueriesCore.QueryDecoder
            ) throws -> (String, separator: String) {
              let p0 = try decoder.decode(_requireQueryRepresentable(String.self))
              let separator = try decoder.decode(_requireQueryRepresentable(String.self))
              guard let p0 else {
                throw InvalidInvocation()
              }
              guard let separator else {
                throw InvalidInvocation()
              }
              return (p0, separator)
            }
            public func invoke(_ arguments: some Sequence<(String, separator: String)>) -> QueryBinding {
              return String?(queryOutput: __macro_local_6joinedfMu0_(arguments)).queryBinding
            }
            private struct InvalidInvocation: Error {
            }
          }
          """
        }
      }

      @Test func customRepresentations() {
        assertMacro {
          #"""
          @DatabaseFunction(
            as: ((any Sequence<[String].JSONRepresentation>) -> [String].JSONRepresentation).self
          ) 
          func joined(_ arrays: some Sequence<[String]>) -> [String] {
            arrays.flatMap(\.self)
          }
          """#
        } expansion: {
          #"""
          func joined(_ arrays: some Sequence<[String]>) -> [String] {
            arrays.flatMap(\.self)
          }

          #if DEBUG
          func __macro_local_20joinedIsolationProbefMu_() {
          }
          #endif

          nonisolated var $joined: __macro_local_6joinedfMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(function: __macro_local_20joinedIsolationProbefMu_)
            #sourceLocation()
            #endif
            return __macro_local_6joinedfMu_()
          }

          nonisolated func __macro_local_6joinedfMu0_(_ arg0: some Sequence<[String]>) -> [String] {
            joined(arg0)
          }

          nonisolated struct __macro_local_6joinedfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = [String].JSONRepresentation
            public typealias Output = [String].JSONRepresentation
            public var name: String {
              "joined"
            }
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth([String].JSONRepresentation.self)
              return argumentCount
            }
            public var isDeterministic: Bool {
              false
            }
            public init() {
            }
            public func callAsFunction(_ arrays: some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation>, order: (some QueryExpression)? = Bool?.none, filter: (some QueryExpression<Bool>)? = Bool?.none) -> some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation> {
              StructuredQueriesCore.$_isSelecting.withValue(false) {
                StructuredQueriesCore.AggregateFunctionExpression(
                  self.name, arrays, order: order, filter: filter
                )
              }
            }
            public func step(
              _ decoder: inout some StructuredQueriesCore.QueryDecoder
            ) throws -> [String] {
              let arrays = try decoder.decode(_requireQueryRepresentable([String].JSONRepresentation.self))
              guard let arrays else {
                throw InvalidInvocation()
              }
              return arrays
            }
            public func invoke(_ arguments: some Sequence<[String]>) -> QueryBinding {
              return [String].JSONRepresentation(queryOutput: __macro_local_6joinedfMu0_(arguments)).queryBinding
            }
            private struct InvalidInvocation: Error {
            }
          }
          """#
        }
      }

      @Test func voidReturning() {
        assertMacro {
          """
          @DatabaseFunction
          func print(_ xs: some Sequence<Int>) {
            for x in xs {
              Swift.print(x)
            }
          }
          """
        } expansion: {
          """
          func print(_ xs: some Sequence<Int>) {
            for x in xs {
              Swift.print(x)
            }
          }

          #if DEBUG
          func __macro_local_19printIsolationProbefMu_() {
          }
          #endif

          nonisolated var $print: __macro_local_5printfMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(function: __macro_local_19printIsolationProbefMu_)
            #sourceLocation()
            #endif
            return __macro_local_5printfMu_()
          }

          nonisolated func __macro_local_5printfMu0_(_ arg0: some Sequence<Int>) -> Swift.Void {
            print(arg0)
          }

          nonisolated struct __macro_local_5printfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = Int
            public typealias Output = Swift.Void
            public var name: String {
              "print"
            }
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(Int.self)
              return argumentCount
            }
            public var isDeterministic: Bool {
              false
            }
            public init() {
            }
            public func callAsFunction(_ xs: some StructuredQueriesCore.QueryExpression<Int>, order: (some QueryExpression)? = Bool?.none, filter: (some QueryExpression<Bool>)? = Bool?.none) -> some StructuredQueriesCore.QueryExpression<Swift.Void> {
              StructuredQueriesCore.$_isSelecting.withValue(false) {
                StructuredQueriesCore.AggregateFunctionExpression(
                  self.name, xs, order: order, filter: filter
                )
              }
            }
            public func step(
              _ decoder: inout some StructuredQueriesCore.QueryDecoder
            ) throws -> Int {
              let xs = try decoder.decode(_requireQueryRepresentable(Int.self))
              guard let xs else {
                throw InvalidInvocation()
              }
              return xs
            }
            public func invoke(_ arguments: some Sequence<Int>) -> QueryBinding {
              __macro_local_5printfMu0_(arguments)
              return .null
            }
            private struct InvalidInvocation: Error {
            }
          }
          """
        }
      }

      @Test func throwing() {
        assertMacro {
          """
          @DatabaseFunction
          func validatePositive(_ xs: some Sequence<Int>) throws {
            for x in xs {
              guard x.sign == .plus else {
                throw NegativeError()
              }
            }
          }
          """
        } expansion: {
          """
          func validatePositive(_ xs: some Sequence<Int>) throws {
            for x in xs {
              guard x.sign == .plus else {
                throw NegativeError()
              }
            }
          }

          #if DEBUG
          func __macro_local_30validatePositiveIsolationProbefMu_() {
          }
          #endif

          nonisolated var $validatePositive: __macro_local_16validatePositivefMu_ {
            #if DEBUG
            #sourceLocation(file: "Test.swift", line: 1)
            #StructuredQueriesIsolationCheck(function: __macro_local_30validatePositiveIsolationProbefMu_)
            #sourceLocation()
            #endif
            return __macro_local_16validatePositivefMu_()
          }

          nonisolated func __macro_local_16validatePositivefMu0_(_ arg0: some Sequence<Int>) throws -> Swift.Void {
            validatePositive(arg0)
          }

          nonisolated struct __macro_local_16validatePositivefMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = Int
            public typealias Output = Swift.Void
            public var name: String {
              "validatePositive"
            }
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(Int.self)
              return argumentCount
            }
            public var isDeterministic: Bool {
              false
            }
            public init() {
            }
            public func callAsFunction(_ xs: some StructuredQueriesCore.QueryExpression<Int>, order: (some QueryExpression)? = Bool?.none, filter: (some QueryExpression<Bool>)? = Bool?.none) -> some StructuredQueriesCore.QueryExpression<Swift.Void> {
              StructuredQueriesCore.$_isSelecting.withValue(false) {
                StructuredQueriesCore.AggregateFunctionExpression(
                  self.name, xs, order: order, filter: filter
                )
              }
            }
            public func step(
              _ decoder: inout some StructuredQueriesCore.QueryDecoder
            ) throws -> Int {
              let xs = try decoder.decode(_requireQueryRepresentable(Int.self))
              guard let xs else {
                throw InvalidInvocation()
              }
              return xs
            }
            public func invoke(_ arguments: some Sequence<Int>) -> QueryBinding {
              do {
                try __macro_local_16validatePositivefMu0_(arguments)
                return .null
              } catch {
                return .invalid(error)
              }
            }
            private struct InvalidInvocation: Error {
            }
          }
          """
        }
      }
    }

    @Suite struct WeakSelfTests {
      @Test func classInstanceMethod() {
        assertMacro {
          """
          class Engine {
            @DatabaseFunction
            func uuid() -> String {
              UUID().uuidString
            }
          }
          """
        } expansion: {
          #"""
          class Engine {
            func uuid() -> String {
              UUID().uuidString
            }

            nonisolated var $uuid: __macro_local_4uuidfMu_ {
              #if DEBUG
              #sourceLocation(file: "Test.swift", line: 2)
              #StructuredQueriesIsolationCheck(function: uuid)
              #sourceLocation()
              #endif
              return __macro_local_4uuidfMu_(self)
            }

            nonisolated struct __macro_local_4uuidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = ()
              public typealias Output = String
              public var name: String {
                "uuid"
              }
              public var argumentCount: Int? {
                0
              }
              public var isDeterministic: Bool {
                false
              }
              private weak var base: Engine?
              public init(_ base: Engine) {
                self.base = base
              }
              public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<String> {
                StructuredQueriesCore.$_isSelecting.withValue(false) {
                  StructuredQueriesCore.SQLQueryExpression(
                    "\(quote: self.name)()"
                  )
                }
              }
              public func invoke(
                _ decoder: inout some StructuredQueriesCore.QueryDecoder
              ) throws -> StructuredQueriesCore.QueryBinding {
                guard let base else {
                  return .invalid(
                    StructuredQueriesSQLiteCore._DatabaseFunctionDeallocated(
                      """
                      Failed to invoke 'uuid'; 'Engine' was deallocated
                      """
                    )
                  )
                }
                return String(
                  queryOutput: base.uuid()
                )
                .queryBinding
              }
            }
          }
          """#
        }
      }

      @Test func classInstanceMethodWithLabeledArgs() {
        assertMacro {
          """
          class Engine {
            @DatabaseFunction
            func concat(first: String, second: String) -> String {
              first + second
            }
          }
          """
        } expansion: {
          #"""
          class Engine {
            func concat(first: String, second: String) -> String {
              first + second
            }

            nonisolated var $concat: __macro_local_6concatfMu_ {
              #if DEBUG
              #sourceLocation(file: "Test.swift", line: 2)
              #StructuredQueriesIsolationCheck(function: concat)
              #sourceLocation()
              #endif
              return __macro_local_6concatfMu_(self)
            }

            nonisolated struct __macro_local_6concatfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = (String, String)
              public typealias Output = String
              public var name: String {
                "concat"
              }
              public var argumentCount: Int? {
                var argumentCount = 0
                argumentCount += _columnWidth(String.self)
                argumentCount += _columnWidth(String.self)
                return argumentCount
              }
              public var isDeterministic: Bool {
                false
              }
              private weak var base: Engine?
              public init(_ base: Engine) {
                self.base = base
              }
              public func callAsFunction(first: some StructuredQueriesCore.QueryExpression<String>, second: some StructuredQueriesCore.QueryExpression<String>) -> some StructuredQueriesCore.QueryExpression<String> {
                StructuredQueriesCore.$_isSelecting.withValue(false) {
                  StructuredQueriesCore.SQLQueryExpression(
                    "\(quote: self.name)(\(first), \(second))"
                  )
                }
              }
              public func invoke(
                _ decoder: inout some StructuredQueriesCore.QueryDecoder
              ) throws -> StructuredQueriesCore.QueryBinding {
                let first = try decoder.decode(_requireQueryRepresentable(String.self))
                let second = try decoder.decode(_requireQueryRepresentable(String.self))
                guard let first else {
                  throw InvalidInvocation()
                }
                guard let second else {
                  throw InvalidInvocation()
                }
                guard let base else {
                  return .invalid(
                    StructuredQueriesSQLiteCore._DatabaseFunctionDeallocated(
                      """
                      Failed to invoke 'concat'; 'Engine' was deallocated
                      """
                    )
                  )
                }
                return String(
                  queryOutput: base.concat(first: first, second: second)
                )
                .queryBinding
              }
              private struct InvalidInvocation: Error {
              }
            }
          }
          """#
        }
      }

      @Test func classInstanceMethodWithUnlabeledArgs() {
        assertMacro {
          """
          class Engine {
            @DatabaseFunction
            func double(_ value: Int) -> Int {
              value * 2
            }
          }
          """
        } expansion: {
          #"""
          class Engine {
            func double(_ value: Int) -> Int {
              value * 2
            }

            nonisolated var $double: __macro_local_6doublefMu_ {
              #if DEBUG
              #sourceLocation(file: "Test.swift", line: 2)
              #StructuredQueriesIsolationCheck(function: double)
              #sourceLocation()
              #endif
              return __macro_local_6doublefMu_(self)
            }

            nonisolated struct __macro_local_6doublefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = Int
              public typealias Output = Int
              public var name: String {
                "double"
              }
              public var argumentCount: Int? {
                var argumentCount = 0
                argumentCount += _columnWidth(Int.self)
                return argumentCount
              }
              public var isDeterministic: Bool {
                false
              }
              private weak var base: Engine?
              public init(_ base: Engine) {
                self.base = base
              }
              public func callAsFunction(_ value: some StructuredQueriesCore.QueryExpression<Int>) -> some StructuredQueriesCore.QueryExpression<Int> {
                StructuredQueriesCore.$_isSelecting.withValue(false) {
                  StructuredQueriesCore.SQLQueryExpression(
                    "\(quote: self.name)(\(value))"
                  )
                }
              }
              public func invoke(
                _ decoder: inout some StructuredQueriesCore.QueryDecoder
              ) throws -> StructuredQueriesCore.QueryBinding {
                let value = try decoder.decode(_requireQueryRepresentable(Int.self))
                guard let value else {
                  throw InvalidInvocation()
                }
                guard let base else {
                  return .invalid(
                    StructuredQueriesSQLiteCore._DatabaseFunctionDeallocated(
                      """
                      Failed to invoke 'double'; 'Engine' was deallocated
                      """
                    )
                  )
                }
                return Int(
                  queryOutput: base.double(value)
                )
                .queryBinding
              }
              private struct InvalidInvocation: Error {
              }
            }
          }
          """#
        }
      }

      @Test func classStaticMethodNotWeakified() {
        assertMacro {
          """
          class Engine {
            @DatabaseFunction
            static func uuid() -> String {
              UUID().uuidString
            }
          }
          """
        } expansion: {
          #"""
          class Engine {
            static func uuid() -> String {
              UUID().uuidString
            }

            static nonisolated var $uuid: __macro_local_4uuidfMu_ {
              #if DEBUG
              #sourceLocation(file: "Test.swift", line: 2)
              #StructuredQueriesIsolationCheck(function: uuid)
              #sourceLocation()
              #endif
              return __macro_local_4uuidfMu_()
            }

            static nonisolated func __macro_local_4uuidfMu0_() -> String {
              uuid()
            }

            nonisolated struct __macro_local_4uuidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = ()
              public typealias Output = String
              public var name: String {
                "uuid"
              }
              public var argumentCount: Int? {
                0
              }
              public var isDeterministic: Bool {
                false
              }
              public init() {
              }
              public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<String> {
                StructuredQueriesCore.$_isSelecting.withValue(false) {
                  StructuredQueriesCore.SQLQueryExpression(
                    "\(quote: self.name)()"
                  )
                }
              }
              public func invoke(
                _ decoder: inout some StructuredQueriesCore.QueryDecoder
              ) throws -> StructuredQueriesCore.QueryBinding {
                return String(
                  queryOutput: __macro_local_4uuidfMu0_()
                )
                .queryBinding
              }
            }
          }
          """#
        }
      }

      @Test func structInstanceMethodNotWeakified() {
        assertMacro {
          """
          struct Helpers {
            @DatabaseFunction
            func uuid() -> String {
              UUID().uuidString
            }
          }
          """
        } expansion: {
          #"""
          struct Helpers {
            func uuid() -> String {
              UUID().uuidString
            }

            nonisolated var $uuid: __macro_local_4uuidfMu_ {
              #if DEBUG
              #sourceLocation(file: "Test.swift", line: 2)
              #StructuredQueriesIsolationCheck(function: uuid)
              #sourceLocation()
              #endif
              return __macro_local_4uuidfMu_(self)
            }

            nonisolated struct __macro_local_4uuidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = ()
              public typealias Output = String
              public var name: String {
                "uuid"
              }
              public var argumentCount: Int? {
                0
              }
              public var isDeterministic: Bool {
                false
              }
              private let base: Helpers
              public init(_ base: Helpers) {
                self.base = base
              }
              public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<String> {
                StructuredQueriesCore.$_isSelecting.withValue(false) {
                  StructuredQueriesCore.SQLQueryExpression(
                    "\(quote: self.name)()"
                  )
                }
              }
              public func invoke(
                _ decoder: inout some StructuredQueriesCore.QueryDecoder
              ) throws -> StructuredQueriesCore.QueryBinding {
                return String(
                  queryOutput: base.uuid()
                )
                .queryBinding
              }
            }
          }
          """#
        }
      }

      @Test func classComputedProperty() {
        assertMacro {
          """
          class Engine {
            @DatabaseFunction
            var now: Date {
              Date()
            }
          }
          """
        } expansion: {
          #"""
          class Engine {
            var now: Date {
              Date()
            }

            #if DEBUG
            func __macro_local_17nowIsolationProbefMu_() {
            }
            #endif

            nonisolated var $now: __macro_local_3nowfMu_ {
              #if DEBUG
              #sourceLocation(file: "Test.swift", line: 2)
              #StructuredQueriesIsolationCheck(property: __macro_local_17nowIsolationProbefMu_)
              #sourceLocation()
              #endif
              return __macro_local_3nowfMu_(self)
            }

            nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
              public typealias Input = ()
              public typealias Output = Date
              public typealias QueryValue = Output
              public var name: String {
                "now"
              }
              public var argumentCount: Int? {
                0
              }
              public var isDeterministic: Bool {
                false
              }
              private weak var base: Engine?
              public init(_ base: Engine) {
                self.base = base
              }
              public func invoke(
                _ decoder: inout some StructuredQueriesCore.QueryDecoder
              ) throws -> StructuredQueriesCore.QueryBinding {
                guard let base else {
                  throw StructuredQueriesSQLiteCore._DatabaseFunctionDeallocated(
                    """
                    Failed to invoke 'now'; 'Engine' was deallocated
                    """
                  )
                }
                return Date(
                  queryOutput: base.now
                )
                .queryBinding
              }
              public var queryFragment: StructuredQueriesCore.QueryFragment {
                "\(quote: self.name)()"
              }
            }
          }
          """#
        }
      }
    }
  }
}
