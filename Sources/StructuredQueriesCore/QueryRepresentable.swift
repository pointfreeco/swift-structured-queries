import Foundation

/// A type that can be represented in a query and decoded to a Swift type.
///
/// Many types conform to this protocol, including simple value types that can be decoded from a
/// result column, like `Int` and `String`, as well as ``Table`` values, which are decoded from one
/// or more result columns depending on the type.
///
/// This protocol can also be used to create a compile-time distinction between multiple query
/// representations of a single Swift type. For example, in SQLite there are three distinct
/// representations of date and time values, including ISO-8601-formatted strings, integer second
/// offsets from the Unix epoch, or double Julian day numbers. This library defaults to ISO-8601
/// text, but provides `UnixTimeRepresentation` to represent a date as an integer, and
/// `JulianDayRepresentation` to represent a date as a floating point number.
public protocol QueryRepresentable<QueryOutput>: QueryDecodable {
  /// The Swift type this value is ultimately decoded to.
  associatedtype QueryOutput

  /// Wraps a value in this representation.
  ///
  /// - Parameter queryOutput: The value.
  init(queryOutput: QueryOutput)

  /// Unwraps a value from this representation.
  var queryOutput: QueryOutput { get }

  /// A query fragment that prepares a stored expression for decoding.
  ///
  /// Result columns in a `SELECT` or `RETURNING` clause are rendered through this function. The
  /// default implementation returns the fragment unchanged.
  ///
  /// - Parameter queryFragment: A fragment representing a stored expression.
  /// - Returns: A fragment that can be decoded by this representation.
  static func queryFragment(decoding queryFragment: QueryFragment) -> QueryFragment

  static func _queryFragment(jsonEncoding queryFragment: QueryFragment) -> QueryFragment

  static func _queryFragment(jsonDecoding queryFragment: QueryFragment) -> QueryFragment
}

extension QueryRepresentable {
  @inlinable
  @inline(__always)
  public static func queryFragment(decoding queryFragment: QueryFragment) -> QueryFragment {
    queryFragment
  }

  @inlinable
  @inline(__always)
  public static func _queryFragment(jsonEncoding queryFragment: QueryFragment) -> QueryFragment {
    queryFragment
  }

  @inlinable
  @inline(__always)
  public static func _queryFragment(jsonDecoding queryFragment: QueryFragment) -> QueryFragment {
    queryFragment
  }
}

extension QueryRepresentable where Self: QueryDecodable, Self == QueryOutput {
  @inlinable
  @inline(__always)
  public init(queryOutput: QueryOutput) {
    self = queryOutput
  }

  @inlinable
  @inline(__always)
  public var queryOutput: QueryOutput {
    self
  }
}

extension [UInt8]: QueryRepresentable {}

extension Bool: QueryRepresentable {
  public static func _queryFragment(jsonEncoding queryFragment: QueryFragment) -> QueryFragment {
    "json(CASE \(queryFragment) WHEN 0 THEN 'false' WHEN 1 THEN 'true' END)"
  }
}

extension Double: QueryRepresentable {}

extension Float: QueryRepresentable {}

extension Int: QueryRepresentable {}

extension Int8: QueryRepresentable {}

extension Int16: QueryRepresentable {}

extension Int32: QueryRepresentable {}

extension Int64: QueryRepresentable {}

extension String: QueryRepresentable {}

extension UInt8: QueryRepresentable {}

extension UInt16: QueryRepresentable {}

extension UInt32: QueryRepresentable {}
