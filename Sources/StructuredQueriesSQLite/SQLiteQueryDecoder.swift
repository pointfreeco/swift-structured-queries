import Foundation
import StructuredQueries

#if canImport(Darwin)
  import SQLite3
#else
  import StructuredQueriesSQLite3
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
    defer { currentIndex += 1 }
    guard sqlite3_column_type(statement, currentIndex) != SQLITE_NULL else { return nil }
    return [UInt8](
      UnsafeRawBufferPointer(
        start: sqlite3_column_blob(statement, currentIndex),
        count: Int(sqlite3_column_bytes(statement, currentIndex))
      )
    )
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
    defer { currentIndex += 1 }
    guard sqlite3_column_type(statement, currentIndex) != SQLITE_NULL else { return nil }
    return sqlite3_column_double(statement, currentIndex)
  }

  @inlinable
  mutating func decode(_ columnType: Int.Type) throws -> Int? {
    try decode(Int64.self).map(Int.init)
  }

  @inlinable
  mutating func decode(_ columnType: Int64.Type) throws -> Int64? {
    defer { currentIndex += 1 }
    guard sqlite3_column_type(statement, currentIndex) != SQLITE_NULL else { return nil }
    return sqlite3_column_int64(statement, currentIndex)
  }

  @inlinable
  mutating func decode(_ columnType: String.Type) throws -> String? {
    defer { currentIndex += 1 }
    guard sqlite3_column_type(statement, currentIndex) != SQLITE_NULL else { return nil }
    return String(cString: sqlite3_column_text(statement, currentIndex))
  }

  @usableFromInline
  mutating func decode(_ columnType: UUID.Type) throws -> UUID? {
    guard let uuidString = try decode(String.self) else { return nil }
    return UUID(uuidString: uuidString)
  }
}
