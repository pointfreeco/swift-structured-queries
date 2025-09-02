import Foundation

extension Data: QueryBindable {
  public var queryBinding: QueryBinding {
    .blob([UInt8](self))
  }

  public init?(queryBinding: QueryBinding) {
    guard case .blob(let bytes) = queryBinding else { return nil }
    self.init(bytes)
  }

  public init(decoder: inout some QueryDecoder) throws {
    try self.init([UInt8](decoder: &decoder))
  }
}

extension URL: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(absoluteString)
  }

  public init?(queryBinding: QueryBinding) {
    guard case .text(let string) = queryBinding else { return nil }
    self.init(string: string)
  }

  public init(decoder: inout some QueryDecoder) throws {
    guard let url = Self(string: try String(decoder: &decoder)) else {
      throw InvalidURL()
    }
    self = url
  }
}

private struct InvalidURL: Error {}
