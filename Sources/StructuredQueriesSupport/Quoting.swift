import Foundation

public enum QuoteDelimiter: String {
  case identifier = "\""
  case text = "'"
}

extension StringProtocol {
  package func quoted(_ delimiter: QuoteDelimiter = .identifier) -> String {
    let delimiter = delimiter.rawValue
    return delimiter + replacingOccurrences(of: delimiter, with: delimiter + delimiter) + delimiter
  }
}
