import Foundation
import StructuredQueries

#if canImport(Darwin)
  import SQLite3
#else
  import StructuredQueriesSQLite3
#endif

public struct Database {
  @usableFromInline
  let storage: Storage

  public init(_ ptr: OpaquePointer) {
    self.storage = .unowned(ptr)
  }

  public init(path: String = ":memory:") throws {
    var handle: OpaquePointer?
    let code = sqlite3_open_v2(
      path,
      &handle,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
      nil
    )
    guard code == SQLITE_OK, let handle else { throw SQLiteError(code: code) }
    self.storage = .owned(Storage.Autoreleasing(handle))
  }

  @inlinable
  public func execute(
    _ sql: String
  ) throws {
    guard sqlite3_exec(storage.handle, sql, nil, nil, nil) == SQLITE_OK
    else { throw SQLiteError(db: storage.handle) }
  }

  @inlinable
  public func execute(_ query: some Statement<()>) throws {
    _ = try execute(query) as [()]
  }

  @inlinable
  public func execute<QueryValue: QueryRepresentable>(
    _ query: some Statement<QueryValue>
  ) throws -> [QueryValue.QueryOutput] {
    let query = query.query
    guard !query.isEmpty else { return [] }
    return try withStatement(query) { statement in
      var results: [QueryValue.QueryOutput] = []
      var decoder = SQLiteQueryDecoder(statement: statement)
      loop: while true {
        let code = sqlite3_step(statement)
        switch code {
        case SQLITE_ROW:
          try results.append(decoder.decodeColumns(QueryValue.self))
          decoder.next()
        case SQLITE_DONE:
          break loop
        default:
          throw SQLiteError(db: storage.handle)
        }
      }
      return results
    }
  }

  @inlinable
  public func execute<each V: QueryRepresentable>(
    _ query: some Statement<(repeat each V)>
  ) throws -> [(repeat (each V).QueryOutput)] {
    let query = query.query
    guard !query.isEmpty else { return [] }
    return try withStatement(query) { statement in
      var results: [(repeat (each V).QueryOutput)] = []
      var decoder = SQLiteQueryDecoder(statement: statement)
      loop: while true {
        let code = sqlite3_step(statement)
        switch code {
        case SQLITE_ROW:
          try results.append(decoder.decodeColumns((repeat each V).self))
          decoder.next()
        case SQLITE_DONE:
          break loop
        default:
          throw SQLiteError(db: storage.handle)
        }
      }
      return results
    }
  }

  @inlinable
  public func execute<QueryValue>(
    _ query: some SelectStatementOf<QueryValue>
  ) throws -> [QueryValue.QueryOutput] {
    let query = query.query
    guard !query.isEmpty else { return [] }
    return try withStatement(query) { statement in
      var results: [QueryValue.QueryOutput] = []
      var decoder = SQLiteQueryDecoder(statement: statement)
      loop: while true {
        let code = sqlite3_step(statement)
        switch code {
        case SQLITE_ROW:
          try results.append(QueryValue(decoder: &decoder).queryOutput)
          decoder.next()
        case SQLITE_DONE:
          break loop
        default:
          throw SQLiteError(db: storage.handle)
        }
      }
      return results
    }
  }

  @inlinable
  public func execute<S: SelectStatement, each J: Table>(
    _ query: S
  ) throws -> [(S.From.QueryOutput, repeat (each J).QueryOutput)]
  where S.QueryValue == (), S.Joins == (repeat each J) {
    try execute(query.selectStar())
  }

  @usableFromInline
  func withStatement<R>(
    _ query: QueryFragment, body: (OpaquePointer) throws -> R
  ) throws -> R {
    let (sql, bindings) = query.prepare { _ in "?" }
    var statement: OpaquePointer?
    let code = sqlite3_prepare_v2(storage.handle, sql, -1, &statement, nil)
    guard code == SQLITE_OK, let statement
    else { throw SQLiteError(db: storage.handle) }
    defer { sqlite3_finalize(statement) }
    for (index, binding) in zip(Int32(1)..., bindings) {
      let result = try bindValue(binding, to: statement, at: index)
      guard result == SQLITE_OK else { throw SQLiteError(db: storage.handle) }
    }
    return try body(statement)
  }
  
  private func bindValue(_ binding: any QueryBinding, to statement: OpaquePointer, at index: Int32) throws -> Int32 {
    switch binding {
    case let blob as BlobBinding:
      return sqlite3_bind_blob(statement, index, Array(blob.value), Int32(blob.value.count), SQLITE_TRANSIENT)
    case let bool as BoolBinding:
      return sqlite3_bind_int64(statement, index, bool.value ? 1 : 0)
    case let date as DateBinding:
      return sqlite3_bind_text(statement, index, date.value.iso8601String, -1, SQLITE_TRANSIENT)
    case let double as DoubleBinding:
      return sqlite3_bind_double(statement, index, double.value)
    case let int as IntBinding:
      return sqlite3_bind_int64(statement, index, int.value)
    case is NullBinding:
      return sqlite3_bind_null(statement, index)
    case let text as TextBinding:
      return sqlite3_bind_text(statement, index, text.value, -1, SQLITE_TRANSIENT)
    case let uuid as UUIDBinding:
      return sqlite3_bind_text(statement, index, uuid.value.uuidString.lowercased(), -1, SQLITE_TRANSIENT)
    case let uint64 as UInt64Binding:
      if let int64Value = uint64.int64Value {
        return sqlite3_bind_int64(statement, index, int64Value)
      } else {
        throw OverflowError()
      }
    case let invalid as InvalidBinding:
      throw invalid.error.underlyingError
    case let conditional as ConditionalQueryBinding<TextBinding, InvalidBinding>:
      // Handle ConditionalQueryBinding by recursively processing the underlying binding
      return try bindValue(conditional.underlyingBinding, to: statement, at: index)
    default:
      // Check if it's an OptionalBinding
      let mirror = Mirror(reflecting: binding)
      if String(describing: type(of: binding)).contains("OptionalBinding") {
        // Try to extract the wrapped value
        if let wrappedValue = mirror.children.first(where: { $0.label == "wrapped" })?.value {
          if let wrappedBinding = wrappedValue as? (any QueryBinding)? {
            if let unwrapped = wrappedBinding {
              return try bindValue(unwrapped, to: statement, at: index)
            } else {
              return sqlite3_bind_null(statement, index)
            }
          }
        }
      }
      throw InvalidBindingError()
    }
  }

  @usableFromInline
  enum Storage {
    case owned(Autoreleasing)
    case unowned(OpaquePointer)

    @usableFromInline
    var handle: OpaquePointer {
      switch self {
      case .owned(let storage):
        return storage.handle
      case .unowned(let handle):
        return handle
      }
    }

    @usableFromInline
    final class Autoreleasing {
      fileprivate var handle: OpaquePointer

      init(_ handle: OpaquePointer) {
        self.handle = handle
      }

      deinit {
        sqlite3_close_v2(handle)
      }
    }
  }
}

private struct InvalidBindingError: Error {}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

@usableFromInline
struct SQLiteError: LocalizedError {
  let message: String

  @usableFromInline
  init(db handle: OpaquePointer?) {
    self.message = String(cString: sqlite3_errmsg(handle))
  }

  init(code: Int32) {
    self.message = String(cString: sqlite3_errstr(code))
  }

  @usableFromInline
  var errorDescription: String? {
    message
  }
}
