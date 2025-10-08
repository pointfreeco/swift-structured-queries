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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: self.body()
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "current_date"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: self.body()
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_14jsonCapitalizefMu_(jsonCapitalize)
        }

        nonisolated struct __macro_local_14jsonCapitalizefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = [String].JSONRepresentation
          public typealias Output = [String].JSONRepresentation
          public let name = "jsonCapitalize"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += [String].JSONRepresentation._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: ([String]) -> [String]
          public init(_ body: @escaping ([String]) -> [String]) {
            self.body = body
          }
          public func callAsFunction(_ strings: some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation>) -> some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(strings))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let strings = try decoder.decode([String].JSONRepresentation.self)
            guard let strings else {
              throw InvalidInvocation()
            }
            return [String].JSONRepresentation(
              queryOutput: self.body(strings)
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
          __macro_local_8fortyTwofMu_(fortyTwo)
        }

        nonisolated struct __macro_local_8fortyTwofMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Int
          public let name = "fortyTwo"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = true
          public let body: () -> Int
          public init(_ body: @escaping () -> Int) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Int> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Int(
              queryOutput: self.body()
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += String._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (String) -> Date?
          public init(_ body: @escaping (String) -> Date?) {
            self.body = body
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String>) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(String.self)
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: self.body(format)
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += String._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (String) -> Date?
          public init(_ body: @escaping (String) -> Date?) {
            self.body = body
          }
          public func callAsFunction(format: some StructuredQueriesCore.QueryExpression<String>) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(String.self)
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: self.body(format)
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += String._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (String) -> Date?
          public init(_ body: @escaping (String) -> Date?) {
            self.body = body
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(String.self)
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: self.body(format)
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += String._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (String) -> Date?
          public init(_ body: @escaping (String) -> Date?) {
            self.body = body
          }
          public func callAsFunction(format: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(String.self)
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: self.body(format)
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
          __macro_local_6concatfMu_(concat)
        }

        nonisolated struct __macro_local_6concatfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (String, String)
          public typealias Output = String
          public let name = "concat"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += String._columnWidth
            argumentCount += String._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (String, String) -> String
          public init(_ body: @escaping (String, String) -> String) {
            self.body = body
          }
          public func callAsFunction(first: some StructuredQueriesCore.QueryExpression<String> = "", second: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<String> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(first), \(second))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let first = try decoder.decode(String.self)
            let second = try decoder.decode(String.self)
            guard let first else {
              throw InvalidInvocation()
            }
            guard let second else {
              throw InvalidInvocation()
            }
            return String(
              queryOutput: self.body(first, second)
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
        ╰─ 🛑 '@DatabaseFunction' must be applied to functions
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String?
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += String?._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (String?) -> Date?
          public init(_ body: @escaping (String?) -> Date?) {
            self.body = body
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String?> = String?.none) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(format))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let format = try decoder.decode(String?.self)
            guard let format else {
              throw InvalidInvocation()
            }
            return Date?(
              queryOutput: self.body(format)
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () throws -> Date
          public init(_ body: @escaping () throws -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            do {
              return Date(
                queryOutput: try self.body()
              )
              .queryBinding
            } catch {
              return .invalid(error)
            }
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () throws(MyError) -> Date
          public init(_ body: @escaping () throws(MyError) -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            do {
              return Date(
                queryOutput: try self.body()
              )
              .queryBinding
            } catch {
              return .invalid(error)
            }
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        public nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: self.body()
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: self.body()
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_11currentDatefMu_(currentDate)
        }

        @available(*, unavailable) nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Date(
              queryOutput: self.body()
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_7defaultfMu_(`default`)
        }

        public nonisolated struct __macro_local_7defaultfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Int
          public let name = "default"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Int
          public init(_ body: @escaping () -> Int) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Int> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            return Int(
              queryOutput: self.body()
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_4voidfMu_(void)
        }

        public nonisolated struct __macro_local_4voidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Swift.Void
          public let name = "void"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Swift.Void
          public init(_ body: @escaping () -> Swift.Void) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Swift.Void> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            self.body()
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
          __macro_local_4voidfMu_(void)
        }

        public nonisolated struct __macro_local_4voidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Swift.Void
          public let name = "void"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () throws -> Swift.Void
          public init(_ body: @escaping () throws -> Swift.Void) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Swift.Void> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)()"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            do {
              try self.body()
              return .null
            } catch {
              return .invalid(error)
            }
          }
          private struct InvalidInvocation: Error {
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
          __macro_local_3minfMu_(min)
        }

        nonisolated struct __macro_local_3minfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Int, Int)
          public typealias Output = Swift.Void
          public let name = "min"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += Int._columnWidth
            argumentCount += Int._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (Int, Int) -> Swift.Void
          public init(_ body: @escaping (Int, Int) -> Swift.Void) {
            self.body = body
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
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let x = try decoder.decode(Int.self)
            let y = try decoder.decode(Int.self)
            guard let x else {
              throw InvalidInvocation()
            }
            guard let y else {
              throw InvalidInvocation()
            }
            self.body(x, y)
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
          __macro_local_3minfMu_(min)
        }

        nonisolated struct __macro_local_3minfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Int, Int)
          public typealias Output = Swift.Void
          public let name = "min"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += Int._columnWidth
            argumentCount += Int._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (Int, Int) -> Swift.Void
          public init(_ body: @escaping (Int, Int) -> Swift.Void) {
            self.body = body
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
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let x = try decoder.decode(Int.self)
            let y = try decoder.decode(Int.self)
            guard let x else {
              throw InvalidInvocation()
            }
            guard let y else {
              throw InvalidInvocation()
            }
            self.body(x, y)
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
          __macro_local_7isValidfMu_(isValid)
        }

        nonisolated struct __macro_local_7isValidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Reminder, Bool)
          public typealias Output = Bool
          public let name = "isValid"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += Reminder._columnWidth
            argumentCount += Bool._columnWidth
            return argumentCount
          }
          public let isDeterministic = false
          public let body: (Reminder, Bool) -> Bool
          public init(_ body: @escaping (Reminder, Bool) -> Bool) {
            self.body = body
          }
          public func callAsFunction(_ reminder: some StructuredQueriesCore.QueryExpression<Reminder>, _ override: some StructuredQueriesCore.QueryExpression<Bool> = false) -> some StructuredQueriesCore.QueryExpression<Bool> {
            StructuredQueriesCore.$_isSelecting.withValue(false) {
              StructuredQueriesCore.SQLQueryExpression(
                "\(quote: self.name)(\(reminder), \(override))"
              )
            }
          }
          public func invoke(
            _ decoder: inout some QueryDecoder
          ) throws -> StructuredQueriesCore.QueryBinding {
            let reminder = try decoder.decode(Reminder.self)
            let override = try decoder.decode(Bool.self)
            guard let reminder else {
              throw InvalidInvocation()
            }
            guard let override else {
              throw InvalidInvocation()
            }
            return Bool(
              queryOutput: self.body(reminder, override)
            )
            .queryBinding
          }
          private struct InvalidInvocation: Error {
          }
        }
        """#
      }
    }
  }
}
