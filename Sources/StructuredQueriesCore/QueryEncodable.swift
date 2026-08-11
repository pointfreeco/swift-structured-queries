public import Foundation

/// A type that can encode itself to a query encoder.
///
/// This protocol is the encoding counterpart to ``QueryDecodable``: single-column values,
/// multi-column selections, and entire table rows all describe themselves to a ``QueryEncoder``
/// through it. A value pushes the same raw types its ``QueryDecodable`` conformance pulls.
public protocol QueryEncodable {
  /// Encodes this value to the given encoder.
  ///
  /// - Parameter encoder: The encoder to write to.
  func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError)
}

extension QueryBindable {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    switch queryBinding {
    case .blob(let value): try encoder.encode(value)
    case .bool(let value): try encoder.encode(value)
    case .date(let value): try encoder.encode(value)
    case .double(let value): try encoder.encode(value)
    case .int(let value): try encoder.encode(value)
    case .null: try encoder.encodeNull()
    case .text(let value): try encoder.encode(value)
    case .uint(let value): try encoder.encode(value)
    case .uuid(let value): try encoder.encode(value)
    case .invalid(let error): throw QueryEncodingError.other(error.underlyingError)
    }
  }
}

extension Bool {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension Double {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension Float {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(Double(self))
  }
}

extension Int {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension Int8 {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(Int64(self))
  }
}

extension Int16 {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(Int64(self))
  }
}

extension Int32 {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(Int64(self))
  }
}

extension Int64 {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension String {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension UInt8 {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(Int64(self))
  }
}

extension UInt16 {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(Int64(self))
  }
}

extension UInt32 {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(Int64(self))
  }
}

extension UInt64 {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension [UInt8] {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension Date {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension UUID {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(self)
  }
}

extension Data {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode([UInt8](self))
  }
}

extension URL {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(absoluteString)
  }
}

extension Optional: QueryEncodable where Wrapped: QueryEncodable & QueryExpression {
  @inlinable
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    guard let self else {
      for _ in 0..<Wrapped._columnWidth {
        try encoder.encodeNull()
      }
      return
    }
    try self.encode(to: &encoder)
  }
}

extension Table {
  // TODO: Remove and rely on `@Table`-generated code?
  public nonisolated func encode(
    to encoder: inout some QueryEncoder
  ) throws(QueryEncodingError) {
    func open<Root, Value>(
      _ column: some WritableTableColumnExpression<Root, Value>
    ) throws(QueryEncodingError) {
      try encoder.encode(column, (self as! Root)[keyPath: column.keyPath])
    }
    for column in Self.TableColumns.writableColumns {
      try open(column)
    }
  }
}

