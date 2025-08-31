import Foundation

extension ScalarDatabaseFunction {
  public func install(_ db: OpaquePointer) {
    let body = Unmanaged.passRetained(ScalarDatabaseFunctionContext(self)).toOpaque()
    sqlite3_create_function_v2(
      db,
      name,
      Int32(argumentCount ?? -1),
      SQLITE_UTF8 | (isDeterministic ? SQLITE_DETERMINISTIC : 0),
      body,
      { context, argumentCount, arguments in
        do {
          let body = Unmanaged<ScalarDatabaseFunctionContext>
            .fromOpaque(sqlite3_user_data(context))
            .takeUnretainedValue()
          let arguments: [QueryBinding] = try (0..<argumentCount).map { idx in
            let value = arguments?[Int(idx)]
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
          let output = body(arguments)
          try output.result(db: context)
        } catch {
          sqlite3_result_error(context, error.localizedDescription, -1)
        }
      },
      nil,
      nil,
      { context in
        guard let context else { return }
        Unmanaged<ScalarDatabaseFunctionContext>.fromOpaque(context).release()
      }
    )
  }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private struct UnknownType: Error {}

private final class ScalarDatabaseFunctionContext {
  let body: ([QueryBinding]) -> QueryBinding
  init(_ function: some ScalarDatabaseFunction) {
    body = function.invoke
  }
  func callAsFunction(_ arguments: [QueryBinding]) -> QueryBinding {
    body(arguments)
  }
}

extension QueryBinding {
  fileprivate func result(db: OpaquePointer?) throws {
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
      throw error.underlyingError
    }
  }
}
