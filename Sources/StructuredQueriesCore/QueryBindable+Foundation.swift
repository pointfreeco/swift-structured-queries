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

private struct InvalidURL: Error {}
