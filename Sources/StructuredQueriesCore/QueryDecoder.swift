public import Foundation

/// A type that can decode values from a database connection into in-memory representations.
public protocol QueryDecoder {
  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: [UInt8].Type) throws(QueryDecodingError) -> [UInt8]?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Double.Type) throws(QueryDecodingError) -> Double?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Int64.Type) throws(QueryDecodingError) -> Int64?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: UInt64.Type) throws(QueryDecodingError) -> UInt64?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: String.Type) throws(QueryDecodingError) -> String?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Bool.Type) throws(QueryDecodingError) -> Bool?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Int.Type) throws(QueryDecodingError) -> Int?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Date.Type) throws(QueryDecodingError) -> Date?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: UUID.Type) throws(QueryDecodingError) -> UUID?

  /// Decodes a single value of the given type starting from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode<T: QueryRepresentable>(
    _ columnType: T.Type
  ) throws(QueryDecodingError) -> T.QueryOutput?

  /// Decodes a single value for the given table column starting from the current column.
  ///
  /// - Parameter column: The table column to decode.
  /// - Returns: A value of the column's type, or `nil` if the column is `NULL`.
  mutating func decode<Column: _TableColumnExpression>(
    _ column: Column
  ) throws(QueryDecodingError) -> Column.Value.QueryOutput?
}

extension QueryDecoder {
  /// Decodes a single value of the given type starting from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  @inlinable
  @inline(__always)
  public mutating func decode<T: QueryRepresentable>(
    _ columnType: T.Type
  ) throws(QueryDecodingError) -> T.QueryOutput? {
    try T?(decoder: &self)?.queryOutput
  }

  /// Decodes a single tuple of the given type starting from the current column.
  ///
  /// - Parameter columnTypes: The types to decode as.
  /// - Returns: A tuple of the requested types.
  @inlinable
  @inline(__always)
  public mutating func decodeColumns<each T: QueryRepresentable>(
    _ columnTypes: (repeat each T).Type
  ) throws(QueryDecodingError) -> (repeat (each T).QueryOutput) {
    try (repeat (each T)(decoder: &self).queryOutput)
  }

  @inlinable
  @inline(__always)
  public mutating func decode<Column: _TableColumnExpression>(
    _ column: Column
  ) throws(QueryDecodingError) -> Column.Value.QueryOutput? {
    try Column.Value?(decoder: &self)?.queryOutput
  }

  @_disfavoredOverload
  @inlinable
  @inline(__always)
  public mutating func decode<Column: _TableColumnExpression, Value>(
    _ column: Column
  ) throws(QueryDecodingError) -> Value.QueryOutput?
  where Column.Value == Value? {
    try decode(column) ?? nil
  }
}

public enum QueryDecodingError: Error {
  /// A column's value was corrupted or otherwise invalid.
  case dataCorrupted

  /// A required column was `NULL`.
  case missingRequiredColumn  // TODO: Rename to 'valueNotFound' for more general decoding.

  /// Some other error occurred while decoding a column.
  case other(any Error)

  /// A column's value could not be decoded as the given type.
  case typeMismatch(Any.Type)
}
