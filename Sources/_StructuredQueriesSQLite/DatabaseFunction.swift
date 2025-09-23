import Foundation

extension ScalarDatabaseFunction {
  public func install(_ db: OpaquePointer) {
    let box = Unmanaged.passRetained(ScalarDatabaseFunctionBox(self)).toOpaque()
    sqlite3_create_function_v2(
      db,
      name,
      Int32(argumentCount ?? -1),
      SQLITE_UTF8 | (isDeterministic ? SQLITE_DETERMINISTIC : 0),
      box,
      { context, argumentCount, arguments in
        do {
          var decoder = SQLiteFunctionDecoder(argumentCount: argumentCount, arguments: arguments)
          try Unmanaged<ScalarDatabaseFunctionBox>
            .fromOpaque(sqlite3_user_data(context))
            .takeUnretainedValue()
            .function
            .invoke(&decoder)
            .result(db: context)
        } catch {
          QueryBinding.invalid(error).result(db: context)
        }
      },
      nil,
      nil,
      { context in
        guard let context else { return }
        Unmanaged<ScalarDatabaseFunctionBox>.fromOpaque(context).release()
      }
    )
  }
}

private final class ScalarDatabaseFunctionBox {
  let function: any ScalarDatabaseFunction
  init(_ function: some ScalarDatabaseFunction) {
    self.function = function
  }
}

extension QueryBinding {
  fileprivate func result(db: OpaquePointer?) {
    switch self {
    case .blob(let blob):
      sqlite3_result_blob(db, Array(blob), Int32(blob.count), SQLITE_TRANSIENT)
    case .bool(let bool):
      sqlite3_result_int64(db, bool ? 1 : 0)
    case .double(let double):
      sqlite3_result_double(db, double)
    case .date(let date):
      sqlite3_result_text(db, date.iso8601String, -1, SQLITE_TRANSIENT)
    case .int(let int):
      sqlite3_result_int64(db, int)
    case .null:
      sqlite3_result_null(db)
    case .text(let text):
      sqlite3_result_text(db, text, -1, SQLITE_TRANSIENT)
    case .uint(let uint) where uint <= UInt64(Int64.max):
      sqlite3_result_int64(db, Int64(uint))
    case .uint(let uint):
      sqlite3_result_error(db, "Unsigned integer \(uint) overflows Int64.max", -1)
    case .uuid(let uuid):
      sqlite3_result_text(db, uuid.uuidString.lowercased(), -1, SQLITE_TRANSIENT)
    case .invalid(let error):
      sqlite3_result_error(db, error.underlyingError.localizedDescription, -1)
    }
  }
}
