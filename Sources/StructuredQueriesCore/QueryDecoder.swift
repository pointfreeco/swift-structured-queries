import Foundation

/// A type that can decode values from a database connection into in-memory representations.
public protocol QueryDecoder {
  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: [UInt8].Type) throws -> [UInt8]?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Double.Type) throws -> Double?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Int64.Type) throws -> Int64?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: String.Type) throws -> String?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Bool.Type) throws -> Bool?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Int.Type) throws -> Int?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: Date.Type) throws -> Date?

  /// Decodes a single value of the given type from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode(_ columnType: UUID.Type) throws -> UUID?

  /// Decodes a single value of the given type starting from the current column.
  ///
  /// - Parameter columnType: The type to decode as.
  /// - Returns: A value of the requested type, or `nil` if the column is `NULL`.
  mutating func decode<T: QueryRepresentable>(_ columnType: T.Type) throws -> T.QueryOutput?
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
  ) throws -> T.QueryOutput? {
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
  ) throws -> (repeat (each T).QueryOutput) {
    try (repeat (each T)(decoder: &self).queryOutput)
  }

  @inlinable
  @inline(__always)
  public mutating func decode<T: QueryRepresentable<T>>(
    _ columnType: T.Type = T.self
  ) throws -> T? {
    try T?(decoder: &self)?.queryOutput
  }
}

public enum QueryDecodingError: Error {
  case missingRequiredColumn
}
