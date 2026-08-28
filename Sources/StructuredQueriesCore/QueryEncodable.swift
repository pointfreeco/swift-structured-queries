public import Foundation

/// A type that can encode itself to a query encoder.
///
/// This protocol is the encoding counterpart to ``QueryDecodable``: single-column values,
/// multi-column selections, and entire table rows all describe themselves to a ``QueryEncoder``
/// through it.
public protocol QueryEncodable {
  /// Encodes this value to the given encoder.
  ///
  /// - Parameter encoder: The encoder to write to.
  func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError)
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
