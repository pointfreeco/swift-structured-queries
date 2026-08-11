public import Foundation
public import StructuredQueriesCore

#if canImport(Darwin)
  public import SQLite3
#else
  public import _StructuredQueriesSQLite3
#endif

@usableFromInline
struct SQLiteQueryDecoder: QueryDecoder {
  @usableFromInline
  let statement: OpaquePointer

  @usableFromInline
  var currentIndex: Int32 = 0

  @usableFromInline
  init(statement: OpaquePointer) {
    self.statement = statement
  }

  @inlinable
  mutating func next() {
    currentIndex = 0
  }

  @inlinable
  mutating func decode(_ columnType: [UInt8].Type) throws -> [UInt8]? {
    precondition(sqlite3_column_count(statement) > currentIndex)
    switch sqlite3_column_type(statement, currentIndex) {
    case SQLITE_NULL:
      currentIndex += 1
      return nil
    case SQLITE_BLOB:
      defer { currentIndex += 1 }
      return [UInt8](
        UnsafeRawBufferPointer(
          start: sqlite3_column_blob(statement, currentIndex),
          count: Int(sqlite3_column_bytes(statement, currentIndex))
        )
      )
    default:
      throw QueryDecodingError.typeMismatch([UInt8].self)
    }
  }

  @inlinable
  mutating func decode(_ columnType: Bool.Type) throws -> Bool? {
    try decode(Int64.self).map { $0 != 0 }
  }

  @usableFromInline
  mutating func decode(_ columnType: Date.Type) throws -> Date? {
    guard let iso8601String = try decode(String.self) else { return nil }
    return try Date(iso8601String: iso8601String)
  }

  @inlinable
  mutating func decode(_ columnType: Double.Type) throws -> Double? {
    precondition(sqlite3_column_count(statement) > currentIndex)
    switch sqlite3_column_type(statement, currentIndex) {
    case SQLITE_NULL:
      currentIndex += 1
      return nil
    case SQLITE_FLOAT:
      defer { currentIndex += 1 }
      return sqlite3_column_double(statement, currentIndex)
    default:
      throw QueryDecodingError.typeMismatch(Double.self)
    }
  }

  @inlinable
  mutating func decode(_ columnType: Int.Type) throws -> Int? {
    try decode(Int64.self).map(Int.init)
  }

  @inlinable
  mutating func decode(_ columnType: Int64.Type) throws -> Int64? {
    precondition(sqlite3_column_count(statement) > currentIndex)
    switch sqlite3_column_type(statement, currentIndex) {
    case SQLITE_NULL:
      currentIndex += 1
      return nil
    case SQLITE_INTEGER:
      defer { currentIndex += 1 }
      return sqlite3_column_int64(statement, currentIndex)
    default:
      throw QueryDecodingError.typeMismatch(Int64.self)
    }
  }

  @inlinable
  mutating func decode(_ columnType: String.Type) throws -> String? {
    precondition(sqlite3_column_count(statement) > currentIndex)
    switch sqlite3_column_type(statement, currentIndex) {
    case SQLITE_NULL:
      currentIndex += 1
      return nil
    case SQLITE_TEXT:
      defer { currentIndex += 1 }
      return String(cString: sqlite3_column_text(statement, currentIndex))
    default:
      throw QueryDecodingError.typeMismatch(String.self)
    }
  }

  @inlinable
  mutating func decode(_ columnType: UInt64.Type) throws -> UInt64? {
    guard let n = try decode(Int64.self) else { return nil }
    guard n >= 0 else { throw UInt64OverflowError(signedInteger: n) }
    return UInt64(n)
  }

  @usableFromInline
  mutating func decode(_ columnType: UUID.Type) throws -> UUID? {
    guard let uuidString = try decode(String.self) else { return nil }
    return UUID(uuidString: uuidString)
  }
}
