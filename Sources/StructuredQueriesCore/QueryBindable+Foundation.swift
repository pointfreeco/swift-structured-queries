import Foundation

extension Data: QueryBindable {
  public var queryBinding: QueryBinding {
    .blob([UInt8](self))
  }

  public init(decoder: inout some QueryDecoder) throws {
    try self.init([UInt8](decoder: &decoder))
  }
}

extension URL: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(absoluteString)
  }

  public init(decoder: inout some QueryDecoder) throws {
    guard let url = Self(string: try String(decoder: &decoder)) else {
      throw InvalidURL()
    }
    self = url
  }
}

extension Decimal: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(description)
  }

  public init(decoder: inout some QueryDecoder) throws {
    let string = try String(decoder: &decoder)
    guard let decimal = Decimal(string: string) else {
      throw InvalidDecimal()
    }
    self = decimal
  }
}

private struct InvalidURL: Error {}

private struct InvalidDecimal: Error {}
