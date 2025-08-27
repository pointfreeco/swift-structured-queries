import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct CustomFunctionTests {
    @Test func customDate() {
      @Dependency(\.defaultDatabase) var database
      __$dateTime.install(database.handle)
      assertQuery(
        Values(_$dateTime())
      ) {
        """
        SELECT "dateTime"(NULL)
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(1970-01-01T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
    }
  }
}










// ---
import Foundation
import SQLite3

// @CustomFunction  // @DatabaseFunction ? @ScalarFunction (_vs._ @AggregateFunction?)
func dateTime(_ format: String? = nil) -> Date {
  Date(timeIntervalSince1970: 0)
}

// Macro expansion:
@available(macOS 14, *)
func _$dateTime(
  _ format: some QueryExpression<String?> = String?.none
) -> some QueryExpression<Date> {
  __$dateTime(format)
}

@available(macOS 14, *)
var __$dateTime: CustomFunction<String?, Date, Never> {
  CustomFunction("dateTime", isDeterministic: false, body: dateTime(_:))
}

//struct DateTime: DatabaseFunction {
//  typealias Input = String?
////
//  typealias Output = Date
////
//  typealias Failure = Never
////
//  typealias Result = SQLQueryExpression<Date>
//
//  let name = "dateTime"
//  let isDeterministic = false
//  func callAsFunction(
//    _ input: some QueryExpression<String?> = String?.none
//  ) -> Result {
//    SQLQueryExpression("\(quote: name)(\(input))")
//  }
//}
// ---
//protocol DatabaseFunction<Input, Output, Failure> {
//  associatedtype Input
//  associatedtype Output: QueryBindable where Output.QueryValue == Result.QueryValue
//  associatedtype Failure: Error
//  associatedtype Result: QueryExpression
//  var name: String { get }
//  var isDeterministic: Bool { get }
//  func callAsFunction(_ input: some QueryExpression<Input>) throws(Failure) -> Result
//}
// ---
// Library code:
@available(macOS 14, *)
struct CustomFunction<each Input: QueryBindable, Output: QueryBindable, Failure: Error> {
  let name: String
  let isDeterministic: Bool
  let body: (repeat each Input) throws(Failure) -> Output

  init(
    _ name: String,
    isDeterministic: Bool,
    body: @escaping (repeat each Input) throws(Failure) -> Output
  ) {
    self.name = name
    self.isDeterministic = isDeterministic
    self.body = body
  }

  func callAsFunction<each T>(_ input: repeat each T) -> SQLQueryExpression<Output>
  where repeat each T: QueryExpression<each Input> {
    var arguments: [QueryFragment] = []
    for input in repeat each input {
      arguments.append(input.queryFragment)
    }
    return SQLQueryExpression("\(quote: name)(\(arguments.joined(separator: ", ")))")
  }

  fileprivate var anyBody: AnyBody {
    AnyBody { argv in
      var iterator = argv.makeIterator()
      func next<Element: QueryBindable>() throws -> Element {
        guard let queryBinding = iterator.next(), let element = Element(queryBinding: queryBinding)
        else {
          throw QueryDecodingError.missingRequiredColumn  // FIXME: New error case
        }
        return element
      }
      return try body(repeat { _ in try next() }((each Input).self)).queryBinding
    }
  }

  func install(_ db: OpaquePointer) {
    // TODO: Should this be `-1`?
    var count: Int32 = 0
    for _ in repeat (each Input).self {
      count += 1
    }
    let body = Unmanaged.passRetained(anyBody).toOpaque()
    sqlite3_create_function_v2(
      db,
      name,
      count,
      SQLITE_UTF8 | (isDeterministic ? SQLITE_DETERMINISTIC : 0),
      body,
      { ctx, argc, argv in
        do {
          let body = Unmanaged<AnyBody>
            .fromOpaque(sqlite3_user_data(ctx))
            .takeUnretainedValue()
          let arguments: [QueryBinding] = try (0..<argc).map { idx in
            let value = argv?[Int(idx)]
            switch sqlite3_value_type(value) {
            case SQLITE_BLOB:
              if let blob = sqlite3_value_blob(value) {
                let count = Int(sqlite3_value_bytes(value))
                let buffer = UnsafeRawBufferPointer(start: blob, count: count)
                return .blob(Array(buffer))
              } else {
                return .blob([])
              }
            case SQLITE_FLOAT:
              return .double(sqlite3_value_double(value))
            case SQLITE_INTEGER:
              return .int(sqlite3_value_int64(value))
            case SQLITE_NULL:
              return .null
            case SQLITE_TEXT:
              return .text(String(cString: UnsafePointer(sqlite3_value_text(value))))
            default:
              throw UnknownType()
            }
          }
          let output = try body(arguments)
          try output.result(db: ctx)
        } catch {
          // TODO: Debug description? Localized?
          sqlite3_result_error(ctx, "\(error)", -1)
        }
      },
      nil,
      nil,
      { ctx in
        guard let ctx else { return }
        Unmanaged<AnyObject>.fromOpaque(ctx).release()
      }
    )
  }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private struct UnknownType: Error {}

private final class AnyBody {
  let body: ([QueryBinding]) throws -> QueryBinding
  init(body: @escaping ([QueryBinding]) throws -> QueryBinding) {
    self.body = body
  }
  func callAsFunction(_ arguments: [QueryBinding]) throws -> QueryBinding {
    try body(arguments)
  }
}

private extension QueryBinding {
  func result(db: OpaquePointer?) throws {
    switch self {
    case .blob(let value):
      sqlite3_result_blob(db, Array(value), Int32(value.count), SQLITE_TRANSIENT)
    case .double(let value):
      sqlite3_result_double(db, value)
    case .date(let value):
      sqlite3_result_text(db, value.iso8601String, -1, SQLITE_TRANSIENT)
    case .int(let value):
      sqlite3_result_int64(db, value)
    case .null:
      sqlite3_result_null(db)
    case .text(let value):
      sqlite3_result_text(db, value, -1, SQLITE_TRANSIENT)
    case .uuid(let value):
      sqlite3_result_text(db, value.uuidString.lowercased(), -1, SQLITE_TRANSIENT)
    case .invalid(let error):
      throw error
    }
  }
}
