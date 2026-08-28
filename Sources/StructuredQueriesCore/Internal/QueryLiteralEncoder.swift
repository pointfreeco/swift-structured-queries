import Foundation

extension QueryEncodable {
  package var _sqlLiteralDescription: String {
    var encoder = QueryLiteralEncoder()
    do {
      try encode(to: &encoder)
    } catch {
      switch error {
      case .dataCorrupted:
        return "<invalid: data corrupted>"
      case .other(let error):
        return "<invalid: \(error.localizedDescription)>"
      }
    }
    return encoder.literal
  }
}

struct QueryLiteralEncoder: QueryEncoder {
  var literal = "NULL"

  init() {}

  mutating func encode(_ value: [UInt8]) {
    literal = "X'"
    literal.reserveCapacity(value.count * 2 + 3)
    for byte in value {
      let hex = String(byte, radix: 16)
      if hex.count == 1 {
        literal.append("0")
      }
      literal.append(hex)
    }
    literal.append("'")
  }

  mutating func encode(_ value: Bool) {
    literal = value ? "1" : "0"
  }

  mutating func encode(_ value: Date) {
    literal = value.iso8601String.quoted(.text)
  }

  mutating func encode(_ value: Double) {
    literal = "\(value)"
  }

  mutating func encode(_ value: Int) {
    literal = "\(value)"
  }

  mutating func encode(_ value: Int64) {
    literal = "\(value)"
  }

  mutating func encode(_ value: String) {
    literal = value.quoted(.text)
  }

  mutating func encode(_ value: UInt64) {
    literal = "\(value)"
  }

  mutating func encode(_ value: UUID) {
    literal = value.uuidString.lowercased().quoted(.text)
  }

  mutating func encodeNull() {
    literal = "NULL"
  }
}
