package import Foundation

package let jsonDecoder: JSONDecoder = {
  var decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .custom {
    try Date(iso8601String: $0.singleValueContainer().decode(String.self))
  }
  return decoder
}()

package let jsonEncoder: JSONEncoder = {
  var encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .custom { date, encoder in
    var container = encoder.singleValueContainer()
    try container.encode(date.iso8601String)
  }
  #if DEBUG
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  #endif
  return encoder
}()
