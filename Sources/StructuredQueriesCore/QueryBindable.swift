public import Foundation

/// A type representing a value that can be bound to a parameter of a SQL statement.
public protocol QueryBindable: QueryEncodable, QueryRepresentable, QueryExpression, Sendable
where QueryValue: QueryBindable {
  /// The Swift data type representation of the expression's SQL bindable data type.
  ///
  /// For example, a `TEXT` expression may be represented as a `String` query value.
  associatedtype QueryValue = Self
}

extension QueryBindable {
  public var queryFragment: QueryFragment {
    QueryFragment(binding: self)
  }
}

extension [UInt8]: QueryEncodable {}

extension [UInt8]: QueryBindable, QueryExpression {}

extension Bool: QueryBindable {}

extension Double: QueryBindable {}

extension Date: QueryBindable {}

extension Float: QueryBindable {}

extension Int: QueryBindable {}

extension Int8: QueryBindable {}

extension Int16: QueryBindable {}

extension Int32: QueryBindable {}

extension Int64: QueryBindable {}

extension String: QueryBindable {}

extension UInt8: QueryBindable {}

extension UInt16: QueryBindable {}

extension UInt32: QueryBindable {}

extension UInt64: QueryBindable {}

extension UUID: QueryBindable {
  public static func _queryFragment(jsonDecoding queryFragment: QueryFragment) -> QueryFragment {
    "(\(queryFragment) COLLATE NOCASE)"
  }
}

extension DefaultStringInterpolation {
  @_disfavoredOverload
  @available(
    *,
    deprecated,
    message: """
      String interpolation produces a debug description for a SQL expression. \
      Use '+' to concatenate SQL expressions, instead."
      """
  )
  public mutating func appendInterpolation(_ value: some QueryExpression) {
    self.appendInterpolation(value as Any)
  }

  @available(
    *,
    deprecated,
    message: """
      String interpolation produces a debug description for a SQL expression. \
      Use '+' to concatenate SQL expressions, instead."
      """
  )
  public mutating func appendInterpolation<T, V>(_ value: TableColumn<T, V>) {
    self.appendInterpolation(value as Any)
  }
}

extension QueryEncodable where Self: LosslessStringConvertible {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(description)
  }
}

extension QueryEncodable where Self: RawRepresentable, RawValue: QueryEncodable {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try rawValue.encode(to: &encoder)
  }
}
