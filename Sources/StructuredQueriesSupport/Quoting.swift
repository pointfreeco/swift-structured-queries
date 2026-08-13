public enum QuoteDelimiter {
  case identifier
  case text

  @usableFromInline
  var ascii: UInt8 {
    switch self {
    case .identifier: UInt8(ascii: "\"")
    case .text: UInt8(ascii: "'")
    }
  }
}

extension StringProtocol {
  @inlinable
  package func quoted(_ delimiter: QuoteDelimiter = .identifier) -> String {
    let ascii = delimiter.ascii
    let scalar = Unicode.Scalar(ascii)
    var quoted = ""
    quoted.reserveCapacity(utf8.count + 2)
    quoted.unicodeScalars.append(scalar)
    var chunkStart = utf8.startIndex
    while let index = utf8[chunkStart...].firstIndex(of: ascii) {
      let after = utf8.index(after: index)
      quoted.append(contentsOf: self[chunkStart..<after])
      quoted.unicodeScalars.append(scalar)
      chunkStart = after
    }
    quoted.append(contentsOf: self[chunkStart...])
    quoted.unicodeScalars.append(scalar)
    return quoted
  }
}
