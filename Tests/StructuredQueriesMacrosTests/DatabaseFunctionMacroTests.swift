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
          return __macro_local_11currentDatefMu_(currentDate)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: self.body()
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: self.body()
            )
            .sqliteValue
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
          return __macro_local_14jsonCapitalizefMu_(jsonCapitalize)
        }

        nonisolated struct __macro_local_14jsonCapitalizefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = [String].JSONRepresentation
          public typealias Output = [String].JSONRepresentation
          public let name = "jsonCapitalize"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth([String].JSONRepresentation.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let strings = try decoder.decode(_requireQueryRepresentable([String].JSONRepresentation.self))
            guard let strings else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            return try [String].JSONRepresentation(
              queryOutput: self.body(strings)
            )
            .sqliteValue
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
          return __macro_local_8fortyTwofMu_(fortyTwo)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Int(
              queryOutput: self.body()
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let format = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let format else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            return try Date?(
              queryOutput: self.body(format)
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let format = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let format else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            return try Date?(
              queryOutput: self.body(format)
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let format = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let format else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            return try Date?(
              queryOutput: self.body(format)
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let format = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let format else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            return try Date?(
              queryOutput: self.body(format)
            )
            .sqliteValue
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
          return __macro_local_6concatfMu_(concat)
        }

        nonisolated struct __macro_local_6concatfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (String, String)
          public typealias Output = String
          public let name = "concat"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String.self)
            argumentCount += _columnWidth(String.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let first = try decoder.decode(_requireQueryRepresentable(String.self))
            let second = try decoder.decode(_requireQueryRepresentable(String.self))
            guard let first else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            guard let second else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            return try String(
              queryOutput: self.body(first, second)
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
        }

        nonisolated struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String?
          public typealias Output = Date?
          public let name = "currentDate"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(String?.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let format = try decoder.decode(_requireQueryRepresentable(String?.self))
            guard let format else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            return try Date?(
              queryOutput: self.body(format)
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: try self.body()
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: try self.body()
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: self.body()
            )
            .sqliteValue
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
          return __macro_local_11currentDatefMu_(currentDate)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: self.body()
            )
            .sqliteValue
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
          #if DEBUG
          #sourceLocation(file: "Test.swift", line: 2)
          #StructuredQueriesIsolationCheck(function: currentDate)
          #sourceLocation()
          #endif
          return __macro_local_11currentDatefMu_(currentDate)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: self.body()
            )
            .sqliteValue
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
          return __macro_local_7defaultfMu_(`default`)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Int(
              queryOutput: self.body()
            )
            .sqliteValue
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
          return __macro_local_4voidfMu_(void)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            self.body()
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
          return __macro_local_4voidfMu_(void)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            try self.body()
            return .null
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
          return __macro_local_3minfMu_(min)
        }

        nonisolated struct __macro_local_3minfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Int, Int)
          public typealias Output = Swift.Void
          public let name = "min"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(Int.self)
            argumentCount += _columnWidth(Int.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let x = try decoder.decode(_requireQueryRepresentable(Int.self))
            let y = try decoder.decode(_requireQueryRepresentable(Int.self))
            guard let x else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            guard let y else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            self.body(x, y)
            return .null
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
          return __macro_local_3minfMu_(min)
        }

        nonisolated struct __macro_local_3minfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Int, Int)
          public typealias Output = Swift.Void
          public let name = "min"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(Int.self)
            argumentCount += _columnWidth(Int.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let x = try decoder.decode(_requireQueryRepresentable(Int.self))
            let y = try decoder.decode(_requireQueryRepresentable(Int.self))
            guard let x else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            guard let y else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            self.body(x, y)
            return .null
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
          return __macro_local_7isValidfMu_(isValid)
        }

        nonisolated struct __macro_local_7isValidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (Reminder, Bool)
          public typealias Output = Bool
          public let name = "isValid"
          public var argumentCount: Int? {
            var argumentCount = 0
            argumentCount += _columnWidth(Reminder.self)
            argumentCount += _columnWidth(Bool.self)
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
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            let reminder = try decoder.decode(_requireQueryRepresentable(Reminder.self))
            let override = try decoder.decode(_requireQueryRepresentable(Bool.self))
            guard let reminder else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            guard let override else {
              throw StructuredQueriesCore.QueryDecodingError.valueNotFound
            }
            return try Bool(
              queryOutput: self.body(reminder, override)
            )
            .sqliteValue
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
          return __macro_local_3nowfMu_ {
            now
          }
        }

        nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
          public typealias Input = ()
          public typealias Output = Date
          public typealias QueryValue = Output
          public let name = "now"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: self.body()
            )
            .sqliteValue
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
          return __macro_local_3nowfMu_ {
            now
          }
        }

        nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
          public typealias Input = ()
          public typealias Output = Date
          public typealias QueryValue = Output
          public let name = "now"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: self.body()
            )
            .sqliteValue
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
          return __macro_local_3nowfMu_ {
            try now
          }
        }

        nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
          public typealias Input = ()
          public typealias Output = Date
          public typealias QueryValue = Output
          public let name = "now"
          public var argumentCount: Int? {
            0
          }
          public let isDeterministic = false
          public let body: () throws -> Date
          public init(_ body: @escaping () throws -> Date) {
            self.body = body
          }
          public func invoke(
            _ decoder: inout some StructuredQueriesCore.QueryDecoder
          ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
            return try Date(
              queryOutput: try self.body()
            )
            .sqliteValue
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
            return __macro_local_3nowfMu_ {
              now
            }
          }

          nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
            public typealias Input = ()
            public typealias Output = Date
            public typealias QueryValue = Output
            public let name = "now"
            public var argumentCount: Int? {
              0
            }
            public let isDeterministic = false
            public let body: () -> Date
            public init(_ body: @escaping () -> Date) {
              self.body = body
            }
            public func invoke(
              _ decoder: inout some StructuredQueriesCore.QueryDecoder
            ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
              return try Date(
                queryOutput: self.body()
              )
              .sqliteValue
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
            return __macro_local_3sumfMu_ {
              sum($0)
            }
          }

          nonisolated struct __macro_local_3sumfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = Int
            public typealias Output = Int
            public let name = "sum"
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(Int.self)
              return argumentCount
            }
            public let isDeterministic = false
            public let body: (_ xs: any Sequence<Int>) -> Int
            public init(_ body: @escaping (_ xs: any Sequence<Int>) -> Int) {
              self.body = body
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
            ) throws(StructuredQueriesCore.QueryDecodingError) -> Int {
              let xs = try decoder.decode(_requireQueryRepresentable(Int.self))
              guard let xs else {
                throw StructuredQueriesCore.QueryDecodingError.valueNotFound
              }
              return xs
            }
            public func invoke(_ arguments: some Sequence<Int>) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
              return try Int(queryOutput: self.body(arguments)).sqliteValue
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
            return __macro_local_3sumfMu_ {
              sum(of: $0)
            }
          }

          nonisolated struct __macro_local_3sumfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = Int
            public typealias Output = Int
            public let name = "sum"
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(Int.self)
              return argumentCount
            }
            public let isDeterministic = false
            public let body: (_ xs: any Sequence<Int>) -> Int
            public init(_ body: @escaping (_ xs: any Sequence<Int>) -> Int) {
              self.body = body
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
            ) throws(StructuredQueriesCore.QueryDecodingError) -> Int {
              let xs = try decoder.decode(_requireQueryRepresentable(Int.self))
              guard let xs else {
                throw StructuredQueriesCore.QueryDecodingError.valueNotFound
              }
              return xs
            }
            public func invoke(_ arguments: some Sequence<Int>) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
              return try Int(queryOutput: self.body(arguments)).sqliteValue
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
            return __macro_local_6joinedfMu_ {
              joined($0)
            }
          }

          nonisolated struct __macro_local_6joinedfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = (String, separator: String)
            public typealias Output = String?
            public let name = "joined"
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(String.self)
              argumentCount += _columnWidth(String.self)
              return argumentCount
            }
            public let isDeterministic = false
            public let body: (_ arguments: any Sequence<(String, separator: String)>) -> String?
            public init(_ body: @escaping (_ arguments: any Sequence<(String, separator: String)>) -> String?) {
              self.body = body
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
            ) throws(StructuredQueriesCore.QueryDecodingError) -> (String, separator: String) {
              let p0 = try decoder.decode(_requireQueryRepresentable(String.self))
              let separator = try decoder.decode(_requireQueryRepresentable(String.self))
              guard let p0 else {
                throw StructuredQueriesCore.QueryDecodingError.valueNotFound
              }
              guard let separator else {
                throw StructuredQueriesCore.QueryDecodingError.valueNotFound
              }
              return (p0, separator)
            }
            public func invoke(_ arguments: some Sequence<(String, separator: String)>) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
              return try String?(queryOutput: self.body(arguments)).sqliteValue
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
            return __macro_local_6joinedfMu_ {
              joined($0)
            }
          }

          nonisolated struct __macro_local_6joinedfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = [String].JSONRepresentation
            public typealias Output = [String].JSONRepresentation
            public let name = "joined"
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth([String].JSONRepresentation.self)
              return argumentCount
            }
            public let isDeterministic = false
            public let body: (_ arrays: any Sequence<[String]>) -> [String]
            public init(_ body: @escaping (_ arrays: any Sequence<[String]>) -> [String]) {
              self.body = body
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
            ) throws(StructuredQueriesCore.QueryDecodingError) -> [String] {
              let arrays = try decoder.decode(_requireQueryRepresentable([String].JSONRepresentation.self))
              guard let arrays else {
                throw StructuredQueriesCore.QueryDecodingError.valueNotFound
              }
              return arrays
            }
            public func invoke(_ arguments: some Sequence<[String]>) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
              return try [String].JSONRepresentation(queryOutput: self.body(arguments)).sqliteValue
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
            return __macro_local_5printfMu_ {
              print($0)
            }
          }

          nonisolated struct __macro_local_5printfMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = Int
            public typealias Output = Swift.Void
            public let name = "print"
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(Int.self)
              return argumentCount
            }
            public let isDeterministic = false
            public let body: (_ xs: any Sequence<Int>) -> Swift.Void
            public init(_ body: @escaping (_ xs: any Sequence<Int>) -> Swift.Void) {
              self.body = body
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
            ) throws(StructuredQueriesCore.QueryDecodingError) -> Int {
              let xs = try decoder.decode(_requireQueryRepresentable(Int.self))
              guard let xs else {
                throw StructuredQueriesCore.QueryDecodingError.valueNotFound
              }
              return xs
            }
            public func invoke(_ arguments: some Sequence<Int>) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
              self.body(arguments)
              return .null
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
            return __macro_local_16validatePositivefMu_ {
              try validatePositive($0)
            }
          }

          nonisolated struct __macro_local_16validatePositivefMu_: StructuredQueriesSQLiteCore.AggregateDatabaseFunction {
            public typealias Input = Int
            public typealias Output = Swift.Void
            public let name = "validatePositive"
            public var argumentCount: Int? {
              var argumentCount = 0
              argumentCount += _columnWidth(Int.self)
              return argumentCount
            }
            public let isDeterministic = false
            public let body: (_ xs: any Sequence<Int>) throws -> Swift.Void
            public init(_ body: @escaping (_ xs: any Sequence<Int>) throws -> Swift.Void) {
              self.body = body
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
            ) throws(StructuredQueriesCore.QueryDecodingError) -> Int {
              let xs = try decoder.decode(_requireQueryRepresentable(Int.self))
              guard let xs else {
                throw StructuredQueriesCore.QueryDecodingError.valueNotFound
              }
              return xs
            }
            public func invoke(_ arguments: some Sequence<Int>) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
              try self.body(arguments)
              return .null
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
              return __macro_local_4uuidfMu_({ [weak self] in
                  guard let self else {
                    throw StructuredQueriesSQLiteCore._DatabaseFunctionDeallocated()
                  }
                  return self.uuid()
                })
            }

            nonisolated struct __macro_local_4uuidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = ()
              public typealias Output = String
              public let name = "uuid"
              public var argumentCount: Int? {
                0
              }
              public let isDeterministic = false
              public let body: () throws -> String
              public init(_ body: @escaping () throws -> String) {
                self.body = body
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
              ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
                return try String(
                  queryOutput: try self.body()
                )
                .sqliteValue
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
              return __macro_local_6concatfMu_({ [weak self] arg0, arg1 in
                  guard let self else {
                    throw StructuredQueriesSQLiteCore._DatabaseFunctionDeallocated()
                  }
                  return self.concat(first: arg0, second: arg1)
                })
            }

            nonisolated struct __macro_local_6concatfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = (String, String)
              public typealias Output = String
              public let name = "concat"
              public var argumentCount: Int? {
                var argumentCount = 0
                argumentCount += _columnWidth(String.self)
                argumentCount += _columnWidth(String.self)
                return argumentCount
              }
              public let isDeterministic = false
              public let body: (String, String) throws -> String
              public init(_ body: @escaping (String, String) throws -> String) {
                self.body = body
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
              ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
                let first = try decoder.decode(_requireQueryRepresentable(String.self))
                let second = try decoder.decode(_requireQueryRepresentable(String.self))
                guard let first else {
                  throw StructuredQueriesCore.QueryDecodingError.valueNotFound
                }
                guard let second else {
                  throw StructuredQueriesCore.QueryDecodingError.valueNotFound
                }
                return try String(
                  queryOutput: try self.body(first, second)
                )
                .sqliteValue
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
              return __macro_local_6doublefMu_({ [weak self] arg0 in
                  guard let self else {
                    throw StructuredQueriesSQLiteCore._DatabaseFunctionDeallocated()
                  }
                  return self.double(arg0)
                })
            }

            nonisolated struct __macro_local_6doublefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = Int
              public typealias Output = Int
              public let name = "double"
              public var argumentCount: Int? {
                var argumentCount = 0
                argumentCount += _columnWidth(Int.self)
                return argumentCount
              }
              public let isDeterministic = false
              public let body: (Int) throws -> Int
              public init(_ body: @escaping (Int) throws -> Int) {
                self.body = body
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
              ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
                let value = try decoder.decode(_requireQueryRepresentable(Int.self))
                guard let value else {
                  throw StructuredQueriesCore.QueryDecodingError.valueNotFound
                }
                return try Int(
                  queryOutput: try self.body(value)
                )
                .sqliteValue
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
              return __macro_local_4uuidfMu_(uuid)
            }

            nonisolated struct __macro_local_4uuidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = ()
              public typealias Output = String
              public let name = "uuid"
              public var argumentCount: Int? {
                0
              }
              public let isDeterministic = false
              public let body: () -> String
              public init(_ body: @escaping () -> String) {
                self.body = body
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
              ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
                return try String(
                  queryOutput: self.body()
                )
                .sqliteValue
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
              return __macro_local_4uuidfMu_(uuid)
            }

            nonisolated struct __macro_local_4uuidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
              public typealias Input = ()
              public typealias Output = String
              public let name = "uuid"
              public var argumentCount: Int? {
                0
              }
              public let isDeterministic = false
              public let body: () -> String
              public init(_ body: @escaping () -> String) {
                self.body = body
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
              ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
                return try String(
                  queryOutput: self.body()
                )
                .sqliteValue
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
              return __macro_local_3nowfMu_({ [weak self] in
                  guard let self else {
                    throw StructuredQueriesSQLiteCore._DatabaseFunctionDeallocated()
                  }
                  return self.now
                })
            }

            nonisolated struct __macro_local_3nowfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction, StructuredQueriesCore.QueryExpression {
              public typealias Input = ()
              public typealias Output = Date
              public typealias QueryValue = Output
              public let name = "now"
              public var argumentCount: Int? {
                0
              }
              public let isDeterministic = false
              public let body: () throws -> Date
              public init(_ body: @escaping () throws -> Date) {
                self.body = body
              }
              public func invoke(
                _ decoder: inout some StructuredQueriesCore.QueryDecoder
              ) throws -> StructuredQueriesSQLiteCore.SQLiteValue {
                return try Date(
                  queryOutput: try self.body()
                )
                .sqliteValue
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
