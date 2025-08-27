import StructuredQueriesCore

public protocol SQLiteType: QueryBindable {
  static var typeAffinity: SQLiteTypeAffinity { get }
}

public struct SQLiteTypeAffinity: RawRepresentable, Sendable {
  public static let blob = Self(rawValue: "BLOB")
  public static let integer = Self(rawValue: "INTEGER")
  public static let numeric = Self(rawValue: "NUMERIC")
  public static let real = Self(rawValue: "REAL")
  public static let text = Self(rawValue: "TEXT")

  public let rawValue: QueryFragment

  public init(rawValue: QueryFragment) {
    self.rawValue = rawValue
  }
}

extension SQLiteType where Self: BinaryInteger {
  public static var typeAffinity: SQLiteTypeAffinity { .integer }
}

extension Int: SQLiteType {}
extension Int8: SQLiteType {}
extension Int16: SQLiteType {}
extension Int32: SQLiteType {}
extension Int64: SQLiteType {}

extension UInt8: SQLiteType {}
extension UInt16: SQLiteType {}
extension UInt32: SQLiteType {}

extension SQLiteType where Self: FloatingPoint {
  public static var typeAffinity: SQLiteTypeAffinity { .real }
}

extension Double: SQLiteType {}
extension Float: SQLiteType {}

// Bool is not a native SQLite type. SQLite stores booleans as integers (0/1).
// Use explicit conversion: myBool ? 1 : 0, or use BoolAsInt wrapper.

extension String: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { .text }
}

extension [UInt8]: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { .blob }
}

extension Optional: SQLiteType where Wrapped: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { Wrapped.typeAffinity }
}

extension RawRepresentable where RawValue: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { RawValue.typeAffinity }
}