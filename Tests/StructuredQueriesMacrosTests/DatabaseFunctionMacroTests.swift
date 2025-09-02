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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "current_date"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
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

        var $jsonCapitalize: __macro_local_14jsonCapitalizefMu_ {
          __macro_local_14jsonCapitalizefMu_(jsonCapitalize)
        }

        struct __macro_local_14jsonCapitalizefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = [String]
          public typealias Output = [String]
          public let name = "jsonCapitalize"
          public let argumentCount: Int? = 1
          public let isDeterministic = false
          public let body: ([String]) -> [String]
          public init(_ body: @escaping ([String]) -> [String]) {
            self.body = body
          }
          public func callAsFunction(_ strings: some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation>) -> some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)(\(strings))"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count, let strings = [String].JSONRepresentation(queryBinding: arguments[0]) else {
              return .invalid(InvalidInvocation())
            }
            return [String].JSONRepresentation(
              queryOutput: self.body(strings.queryOutput)
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

        var $fortyTwo: __macro_local_8fortyTwofMu_ {
          __macro_local_8fortyTwofMu_(fortyTwo)
        }

        struct __macro_local_8fortyTwofMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Int
          public let name = "fortyTwo"
          public let argumentCount: Int? = 0
          public let isDeterministic = true
          public let body: () -> Int
          public init(_ body: @escaping () -> Int) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Int> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public let argumentCount: Int? = 1
          public let isDeterministic = false
          public let body: (String) -> Date?
          public init(_ body: @escaping (String) -> Date?) {
            self.body = body
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String>) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)(\(format))"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count, let format = String(queryBinding: arguments[0]) else {
              return .invalid(InvalidInvocation())
            }
            return Date?(
              queryOutput: self.body(format.queryOutput)
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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public let argumentCount: Int? = 1
          public let isDeterministic = false
          public let body: (String) -> Date?
          public init(_ body: @escaping (String) -> Date?) {
            self.body = body
          }
          public func callAsFunction(format: some StructuredQueriesCore.QueryExpression<String>) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)(\(format))"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count, let format = String(queryBinding: arguments[0]) else {
              return .invalid(InvalidInvocation())
            }
            return Date?(
              queryOutput: self.body(format.queryOutput)
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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public let argumentCount: Int? = 1
          public let isDeterministic = false
          public let body: (String) -> Date?
          public init(_ body: @escaping (String) -> Date?) {
            self.body = body
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)(\(format))"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count, let format = String(queryBinding: arguments[0]) else {
              return .invalid(InvalidInvocation())
            }
            return Date?(
              queryOutput: self.body(format.queryOutput)
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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String
          public typealias Output = Date?
          public let name = "currentDate"
          public let argumentCount: Int? = 1
          public let isDeterministic = false
          public let body: (String) -> Date?
          public init(_ body: @escaping (String) -> Date?) {
            self.body = body
          }
          public func callAsFunction(format: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)(\(format))"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count, let format = String(queryBinding: arguments[0]) else {
              return .invalid(InvalidInvocation())
            }
            return Date?(
              queryOutput: self.body(format.queryOutput)
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

        var $concat: __macro_local_6concatfMu_ {
          __macro_local_6concatfMu_(concat)
        }

        struct __macro_local_6concatfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = (String, String)
          public typealias Output = String
          public let name = "concat"
          public let argumentCount: Int? = 2
          public let isDeterministic = false
          public let body: (String, String) -> String
          public init(_ body: @escaping (String, String) -> String) {
            self.body = body
          }
          public func callAsFunction(first: some StructuredQueriesCore.QueryExpression<String> = "", second: some StructuredQueriesCore.QueryExpression<String> = "") -> some StructuredQueriesCore.QueryExpression<String> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)(\(first), \(second))"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count, let first = String(queryBinding: arguments[0]), let second = String(queryBinding: arguments[1]) else {
              return .invalid(InvalidInvocation())
            }
            return String(
              queryOutput: self.body(first.queryOutput, second.queryOutput)
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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = String?
          public typealias Output = Date?
          public let name = "currentDate"
          public let argumentCount: Int? = 1
          public let isDeterministic = false
          public let body: (String?) -> Date?
          public init(_ body: @escaping (String?) -> Date?) {
            self.body = body
          }
          public func callAsFunction(_ format: some StructuredQueriesCore.QueryExpression<String?> = String?.none) -> some StructuredQueriesCore.QueryExpression<Date?> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)(\(format))"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count, let format = String?(queryBinding: arguments[0]) else {
              return .invalid(InvalidInvocation())
            }
            return Date?(
              queryOutput: self.body(format.queryOutput)
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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () throws -> Date
          public init(_ body: @escaping () throws -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
            do {
              return try Date(
                queryOutput: self.body()
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

        var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () throws(MyError) -> Date
          public init(_ body: @escaping () throws(MyError) -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
            do {
              return try Date(
                queryOutput: self.body()
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

        public var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        public struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
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

        static var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
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

        @available(*, unavailable) var $currentDate: __macro_local_11currentDatefMu_ {
          __macro_local_11currentDatefMu_(currentDate)
        }

        @available(*, unavailable) struct __macro_local_11currentDatefMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Date
          public let name = "currentDate"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () -> Date
          public init(_ body: @escaping () -> Date) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Date> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
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

        public var $default: __macro_local_7defaultfMu_ {
          __macro_local_7defaultfMu_(`default`)
        }

        public struct __macro_local_7defaultfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = Int
          public let name = "default"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () -> Int
          public init(_ body: @escaping () -> Int) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<Int> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
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

    @Test func returnTypeDiagnostic() {
      assertMacro {
        """
        @DatabaseFunction
        public func void() {
          print("...")
        }
        """
      } diagnostics: {
        """
        @DatabaseFunction
        public func void() {
                        ──┬
                          ╰─ 🛑 Missing required return type
                             ✏️ Insert '-> <#QueryBindable#>'
          print("...")
        }
        """
      } fixes: {
        """
        @DatabaseFunction
        public func void() -> <#QueryBindable#> {
          print("...")
        }
        """
      } expansion: {
        #"""
        public func void() -> <#QueryBindable#> {
          print("...")
        }

        public var $void: __macro_local_4voidfMu_ {
          __macro_local_4voidfMu_(void)
        }

        public struct __macro_local_4voidfMu_: StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
          public typealias Input = ()
          public typealias Output = <#QueryBindable#>
          public let name = "void"
          public let argumentCount: Int? = 0
          public let isDeterministic = false
          public let body: () -> <#QueryBindable#>
          public init(_ body: @escaping () -> <#QueryBindable#>) {
            self.body = body
          }
          public func callAsFunction() -> some StructuredQueriesCore.QueryExpression<<#QueryBindable#>> {
            StructuredQueriesCore.SQLQueryExpression(
              "\(quote: self.name)()"
            )
          }
          public func invoke(
            _ arguments: [StructuredQueriesCore.QueryBinding]
          ) -> StructuredQueriesCore.QueryBinding {
            guard self.argumentCount == nil || self.argumentCount == arguments.count else {
              return .invalid(InvalidInvocation())
            }
            return <#QueryBindable#>(
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
  }
}
