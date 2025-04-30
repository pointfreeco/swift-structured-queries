/// A type that can decode itself from a query.
public protocol QueryDecodable: _OptionalPromotable {
  /// Creates a new instance by decoding from the given decoder.
  ///
  /// This initializer throws an error if reading from the decoder fails, or if the data read is
  /// corrupted or otherwise invalid.
  ///
  /// - Parameter decoder: The decoder to read data from.
  init(decoder: inout some QueryDecoder) throws
}

extension [UInt8]: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    guard let result = try decoder.decode([UInt8].self)
    else { throw QueryDecodingError.missingRequiredColumn }
    self = result
  }
}

extension Double: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    guard let result = try decoder.decode(Double.self)
    else { throw QueryDecodingError.missingRequiredColumn }
    self = result
  }
}

extension Int64: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    guard let result = try decoder.decode(Int64.self)
    else { throw QueryDecodingError.missingRequiredColumn }
    self = result
  }
}

extension String: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    guard let result = try decoder.decode(String.self)
    else { throw QueryDecodingError.missingRequiredColumn }
    self = result
  }
}

extension Bool: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    self = try Int(decoder: &decoder) != 0
  }
}

extension Float: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(Double(decoder: &decoder))
  }
}

extension Int: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    let n = try Int64(decoder: &decoder)
    guard (Int64(Int.min)...Int64(Int.max)).contains(n) else { throw OverflowError() }
    self.init(n)
  }
}

extension Int8: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    let n = try Int64(decoder: &decoder)
    guard (Int64(Int8.min)...Int64(Int8.max)).contains(n) else { throw OverflowError() }
    self.init(n)
  }
}

extension Int16: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    let n = try Int64(decoder: &decoder)
    guard (Int64(Int16.min)...Int64(Int16.max)).contains(n) else { throw OverflowError() }
    self.init(n)
  }
}

extension Int32: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    let n = try Int64(decoder: &decoder)
    guard (Int64(Int32.min)...Int64(Int32.max)).contains(n) else { throw OverflowError() }
    self.init(n)
  }
}

extension UInt: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    let n = try Int64(decoder: &decoder)
    guard n >= 0 else { throw OverflowError() }
    self.init(n)
  }
}

extension UInt8: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    let n = try Int64(decoder: &decoder)
    guard (Int64(UInt8.min)...Int64(UInt8.max)).contains(n) else { throw OverflowError() }
    self.init(n)
  }
}

extension UInt16: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    let n = try Int64(decoder: &decoder)
    guard (Int64(UInt16.min)...Int64(UInt16.max)).contains(n) else { throw OverflowError() }
    self.init(n)
  }
}

extension UInt32: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    let n = try Int64(decoder: &decoder)
    guard (Int64(UInt32.min)...Int64(UInt32.max)).contains(n) else { throw OverflowError() }
    self.init(n)
  }
}

extension UInt64: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(Int64(decoder: &decoder))
  }
}

extension QueryDecodable where Self: LosslessStringConvertible {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    guard let losslessStringConvertible = try Self(String(decoder: &decoder))
    else {
      throw DataCorruptedError()
    }
    self = losslessStringConvertible
  }
}

extension QueryDecodable where Self: RawRepresentable, RawValue: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    guard let rawRepresentable = try Self(rawValue: RawValue(decoder: &decoder))
    else {
      throw DataCorruptedError()
    }
    self = rawRepresentable
  }
}

@usableFromInline
struct DataCorruptedError: Error {
  @usableFromInline
  init() {}
}

@usableFromInline
struct OverflowError: Error {
  @usableFromInline
  init() {}
}
