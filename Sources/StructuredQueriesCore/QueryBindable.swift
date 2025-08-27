import Foundation

/// A type representing a value that can be bound to a parameter of a SQL statement.
public protocol QueryBindable: QueryRepresentable, QueryExpression where QueryValue: QueryBindable {
  /// The Swift data type representation of the expression's SQL bindable data type.
  ///
  /// For example, a `TEXT` expression may be represented as a `String` query value.
  associatedtype QueryValue = Self

  /// A value that can be bound to a parameter of a SQL statement.
    associatedtype Query: QueryBinding
    
    var queryBinding: Query { get }
}

extension QueryBindable {
  public var queryFragment: QueryFragment { "\(queryBinding)" }
}

extension [UInt8]: QueryBindable, QueryExpression {
  public var queryBinding: some QueryBinding { BlobBinding(self) }
}

// Bool is not universally supported across databases.
// SQLite stores booleans as integers (0/1).
// PostgreSQL has native boolean support.
// Database-specific modules should provide their own Bool support.

extension Double: QueryBindable {
  public var queryBinding: some QueryBinding { DoubleBinding(self) }
}

extension Date: QueryBindable {
  public var queryBinding: some QueryBinding { DateBinding(self) }
}

extension Float: QueryBindable {
  public var queryBinding: some QueryBinding { DoubleBinding(Double(self)) }
}

extension Int: QueryBindable {
  public var queryBinding: some QueryBinding { IntBinding(Int64(self)) }
}

extension Int8: QueryBindable {
  public var queryBinding: some QueryBinding { IntBinding(Int64(self)) }
}

extension Int16: QueryBindable {
  public var queryBinding: some QueryBinding { IntBinding(Int64(self)) }
}

extension Int32: QueryBindable {
  public var queryBinding: some QueryBinding { IntBinding(Int64(self)) }
}

extension Int64: QueryBindable {
  public var queryBinding: some QueryBinding { IntBinding(self) }
}

extension String: QueryBindable {
  public var queryBinding: some QueryBinding { TextBinding(self) }
}

extension UInt8: QueryBindable {
  public var queryBinding: some QueryBinding { IntBinding(Int64(self)) }
}

extension UInt16: QueryBindable {
  public var queryBinding: some QueryBinding { IntBinding(Int64(self)) }
}

extension UInt32: QueryBindable {
  public var queryBinding: some QueryBinding { IntBinding(Int64(self)) }
}

extension UInt64: QueryBindable {
  public var queryBinding: some QueryBinding {
    UInt64Binding(self)
  }
}

extension UUID: QueryBindable {
  public var queryBinding: some QueryBinding { UUIDBinding(self) }
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

extension QueryBindable where Self: LosslessStringConvertible {
  public var queryBinding: some QueryBinding { description.queryBinding }
}

extension QueryBindable where Self: RawRepresentable, RawValue: QueryBindable {
  public var queryBinding: some QueryBinding { rawValue.queryBinding }
}
