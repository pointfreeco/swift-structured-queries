extension QueryExpression where QueryValue: QueryBindable {
  public func cast<Other: SQLiteType>(
    as _: Other.Type = Other.self
  ) -> some QueryExpression<Other> {
    Cast(base: self)
  }
}

extension QueryExpression where QueryValue: QueryBindable & _OptionalProtocol {
  public func cast<Other: _OptionalPromotable & SQLiteType>(
    as _: Other.Type = Other.self
  ) -> some QueryExpression<Other._Optionalized>
  where Other._Optionalized: SQLiteType {
    Cast(base: self)
  }

  @available(
    *, deprecated, message: "Cast optional to non-optional produces invalid query expression"
  )
  public func cast<Other: SQLiteType>(
    as _: Other.Type = Other.self
  ) -> some QueryExpression<Other> {
    Cast(base: self)
  }
}

extension QueryExpression where QueryValue: SQLiteType {
  @available(*, deprecated, message: "Cast to same query value type always succeeds")
  public func cast(
    as _: QueryValue.Type = QueryValue.self
  ) -> some QueryExpression<QueryValue> {
    self
  }
}

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

extension Bool: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { Int.typeAffinity }
}

extension String: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { .text }
}

extension [UInt8]: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { .blob }
}

extension Optional: SQLiteType where Wrapped: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { Wrapped.typeAffinity }
}

private struct Cast<QueryValue: SQLiteType, Base: QueryExpression>: QueryExpression {
  let base: Base
  var queryFragment: QueryFragment {
    "CAST(\(base.queryFragment) AS \(QueryValue.typeAffinity.rawValue))"
  }
}

extension RawRepresentable where RawValue: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { RawValue.typeAffinity }
}

extension _CodableJSONRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}
