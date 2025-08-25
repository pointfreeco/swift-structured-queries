@_exported import StructuredQueriesCore

// ---
import Foundation

// @CustomFunction  // @DatabaseFunction ? @ScalarFunction (_vs._ @AggregateFunction?)
func dateTime(_ format: String? = nil) -> Date {
  Date()
}

// Macro expansion:
@available(macOS 14, *)
@_disfavoredOverload  // Or can/should this be applied the the above?
func dateTime(
  _ format: some QueryExpression<String?> = String?.none
) -> some QueryExpression<Date> {
  _$dateTime(format)
}

@available(macOS 14, *)
var _$dateTime: CustomFunction<String?, Date> {
  CustomFunction("dateTime", isDeterministic: false, body: dateTime(_:))
}
// ---

import SQLite3

@available(macOS 14, *)
struct CustomFunction<each Input, Output: QueryBindable> {
  let name: String
  let isDeterministic: Bool
//  private let body: Body

  init(
    _ name: String,
    isDeterministic: Bool,
    body: @escaping (repeat each Input) -> Output
  ) {
    self.name = name
    self.isDeterministic = isDeterministic
//    self.body = Body(body)
  }

  func callAsFunction<each T>(_ input: repeat each T) -> SQLQueryExpression<Output>
  where repeat each T: QueryExpression<each Input> {
    var arguments: [QueryFragment] = []
    for input in repeat each input {
      arguments.append(input.queryFragment)
    }
    return SQLQueryExpression("\(quote: name)(\(arguments.joined(separator: ", "))")
  }

//  func install(_ db: OpaquePointer) {
//    // TODO: Should this be `-1`?
//    var count: Int32 = 0
//    for _ in repeat (each Input).self {
//      count += 1
//    }
//    let body = Unmanaged.passRetained(body).toOpaque()
//    sqlite3_create_function_v2(
//      db,
//      name,
//      count,
//      SQLITE_UTF8 | (isDeterministic ? SQLITE_DETERMINISTIC : 0),
//      body,
//      { ctx, argc, argv in
////        let body = Unmanaged<Body>
////          .fromOpaque(sqlite3_user_data(ctx))
////          .takeUnretainedValue()
//      },
//      nil,
//      nil,
//      { ctx in
////        Unmanaged<AnyObject>.fromOpaque(body).release()
//      }
//    )
//  }
}


private final class Body {
  let body: ([Any]) -> Any
  init<each Input, Output: QueryBindable>(_ body: @escaping (repeat each Input) -> Output) {
    fatalError()
  }
}


