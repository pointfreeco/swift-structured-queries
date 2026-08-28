public import Foundation

/// A type that can encode values to a database connection from in-memory representations.
public protocol QueryEncoder {
  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: [UInt8]) throws(QueryEncodingError)

  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: Bool) throws(QueryEncodingError)

  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: Date) throws(QueryEncodingError)

  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: Double) throws(QueryEncodingError)

  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: Int) throws(QueryEncodingError)

  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: Int64) throws(QueryEncodingError)

  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: String) throws(QueryEncodingError)

  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: UInt64) throws(QueryEncodingError)

  /// Encodes a single value.
  ///
  /// - Parameter value: The value to encode.
  mutating func encode(_ value: UUID) throws(QueryEncodingError)

  /// Encodes an absent value.
  ///
  /// Receives `nil` values, including once per column of an absent nested optional selection.
  mutating func encodeNull() throws(QueryEncodingError)

  /// Encodes a value for the given table column.
  ///
  /// The default implementation discards the column and encodes the value directly. Encoders
  /// for keyed formats can override this requirement to associate the value with the column's
  /// name.
  ///
  /// - Parameters:
  ///   - column: The table column being encoded.
  ///   - value: The row's value for the column.
  mutating func encode<Column: _TableColumnExpression>(
    _ column: @autoclosure () -> Column,
    _ value: Column.Value.QueryOutput
  ) throws(QueryEncodingError) where Column.Value: QueryEncodable
}

extension QueryEncoder {
  @inlinable
  public mutating func encode<Column: _TableColumnExpression>(
    _ column: @autoclosure () -> Column,
    _ value: Column.Value.QueryOutput
  ) throws(QueryEncodingError) where Column.Value: QueryEncodable {
    try Column.Value(queryOutput: value).encode(to: &self)
  }
}
/// An error that can be thrown while encoding a query value.
public enum QueryEncodingError: Error {
  /// A value was corrupted or otherwise invalid.
  case dataCorrupted

  /// Some other error occurred while encoding a column.
  case other(any Error)
}

@usableFromInline
package struct QueryFragmentsEncoder: QueryEncoder {
  @usableFromInline
  package var fragments: [QueryFragment] = []

  @usableFromInline
  package init() {}

  @inlinable
  package mutating func encode(_ value: [UInt8]) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encode(_ value: Bool) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encode(_ value: Date) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encode(_ value: Double) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encode(_ value: Int) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encode(_ value: Int64) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encode(_ value: String) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encode(_ value: UInt64) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encode(_ value: UUID) {
    fragments.append(QueryFragment(binding: value))
  }

  @inlinable
  package mutating func encodeNull() {
    fragments.append(QueryFragment(segments: [.binding(nil)]))
  }

  @inlinable
  package mutating func encode<Column: _TableColumnExpression>(
    _ column: @autoclosure () -> Column,
    _ value: Column.Value.QueryOutput
  ) throws(QueryEncodingError) where Column.Value: QueryEncodable {
    let value = Column.Value(queryOutput: value)
    if let bindable = value as? any QueryBindable {
      fragments.append(bindable.queryFragment)
    } else {
      try value.encode(to: &self)
    }
  }
}
