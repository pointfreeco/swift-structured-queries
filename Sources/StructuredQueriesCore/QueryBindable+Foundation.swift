public import Foundation

extension Data: QueryBindable {
  public var queryBinding: QueryBinding {
    .blob([UInt8](self))
  }

  public init(decoder: inout some QueryDecoder) throws(QueryDecodingError) {
    try self.init([UInt8](decoder: &decoder))
  }
}

extension URL: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(absoluteString)
  }

  public init(decoder: inout some QueryDecoder) throws(QueryDecodingError) {
    guard let url = Self(string: try String(decoder: &decoder))
    else { throw .dataCorrupted }
    self = url
  }
}
