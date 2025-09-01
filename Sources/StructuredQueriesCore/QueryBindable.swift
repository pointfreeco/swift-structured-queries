import Foundation

/// A type representing a value that can be bound to a parameter of a SQL statement.
public protocol QueryBindable: QueryRepresentable, QueryExpression where QueryValue: QueryBindable {
  /// The Swift data type representation of the expression's SQL bindable data type.
  ///
  /// For example, a `TEXT` expression may be represented as a `String` query value.
  associatedtype QueryValue = Self

  /// A value that can be bound to a parameter of a SQL statement.
  var queryBinding: QueryBinding { get }

  /// Initializes a bindable type from a binding.
  init?(queryBinding: QueryBinding)
}

extension QueryBindable {
  public var queryFragment: QueryFragment { "\(queryBinding)" }

  public init?(queryBinding: QueryBinding) {
    guard let queryValue = QueryValue(queryBinding: queryBinding) else { return nil }
    self.init(queryBinding: queryValue.queryBinding)
  }
}

extension [UInt8]: QueryBindable, QueryExpression {
  public var queryBinding: QueryBinding { .blob(self) }
  public init?(queryBinding: QueryBinding) {
    guard case .blob(let value) = queryBinding else { return nil }
    self = value
  }
}

extension Bool: QueryBindable {
  public var queryBinding: QueryBinding { .int(self ? 1 : 0) }
}

extension Double: QueryBindable {
  public var queryBinding: QueryBinding { .double(self) }
  public init?(queryBinding: QueryBinding) {
    guard case .double(let value) = queryBinding else { return nil }
    self = value
  }
}

extension Date: QueryBindable {
  public var queryBinding: QueryBinding { .date(self) }
  public init?(queryBinding: QueryBinding) {
    guard case .date(let value) = queryBinding else { return nil }
    self = value
  }
}

extension Float: QueryBindable {
  public var queryBinding: QueryBinding { .double(Double(self)) }
}

extension Int: QueryBindable {
  public var queryBinding: QueryBinding { .int(Int64(self)) }
}

extension Int8: QueryBindable {
  public var queryBinding: QueryBinding { .int(Int64(self)) }
}

extension Int16: QueryBindable {
  public var queryBinding: QueryBinding { .int(Int64(self)) }
}

extension Int32: QueryBindable {
  public var queryBinding: QueryBinding { .int(Int64(self)) }
}

extension Int64: QueryBindable {
  public var queryBinding: QueryBinding { .int(self) }
  public init?(queryBinding: QueryBinding) {
    guard case .int(let value) = queryBinding else { return nil }
    self = value
  }
}

extension String: QueryBindable {
  public var queryBinding: QueryBinding { .text(self) }
  public init?(queryBinding: QueryBinding) {
    guard case let .text(value) = queryBinding else { return nil }
    self = value
  }
}

extension UInt8: QueryBindable {
  public var queryBinding: QueryBinding { .int(Int64(self)) }
}

extension UInt16: QueryBindable {
  public var queryBinding: QueryBinding { .int(Int64(self)) }
}

extension UInt32: QueryBindable {
  public var queryBinding: QueryBinding { .int(Int64(self)) }
}

extension UInt64: QueryBindable {
  public var queryBinding: QueryBinding {
    if self > UInt64(Int64.max) {
      return .invalid(OverflowError())
    } else {
      return .int(Int64(self))
    }
  }
}

extension UUID: QueryBindable {
  public var queryBinding: QueryBinding { .uuid(self) }
  public init?(queryBinding: QueryBinding) {
    guard case .uuid(let value) = queryBinding else { return nil }
    self = value
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

extension QueryBindable where Self: LosslessStringConvertible {
  public var queryBinding: QueryBinding { description.queryBinding }
}

extension QueryBindable where Self: RawRepresentable, RawValue: QueryBindable {
  public var queryBinding: QueryBinding { rawValue.queryBinding }
}
