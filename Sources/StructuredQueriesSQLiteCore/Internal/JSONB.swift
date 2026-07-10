/// A decoder of SQLite's binary JSON format.
///
/// Transcodes a JSONB blob (see <https://sqlite.org/jsonb.html>) to an equivalent JSON string,
/// suitable for feeding to a `JSONDecoder`.
package enum JSONB {
  package struct DecodingError: Error {
    package let debugDescription: String

    init(_ debugDescription: String) {
      self.debugDescription = debugDescription
    }
  }

  package static func json(from blob: [UInt8]) throws -> String {
    var json = ""
    var index = blob.startIndex
    try transcodeElement(blob, at: &index, into: &json)
    guard index == blob.endIndex else {
      throw DecodingError("Unexpected trailing bytes after JSONB element")
    }
    return json
  }

  private static func transcodeElement(
    _ blob: [UInt8],
    at index: inout Int,
    into json: inout String
  ) throws {
    guard index < blob.endIndex else {
      throw DecodingError("Unexpected end of JSONB blob")
    }
    let header = blob[index]
    let elementType = header & 0x0f
    var payloadSize = Int(header >> 4)
    index += 1
    if payloadSize > 11 {
      let sizeWidth = 1 << (payloadSize - 12)
      guard blob.endIndex - index >= sizeWidth else {
        throw DecodingError("Unexpected end of JSONB header")
      }
      var size: UInt64 = 0
      for _ in 0..<sizeWidth {
        size = size << 8 | UInt64(blob[index])
        index += 1
      }
      guard let validatedSize = Int(exactly: size) else {
        throw DecodingError("JSONB payload size overflows")
      }
      payloadSize = validatedSize
    }
    guard payloadSize <= blob.endIndex - index else {
      throw DecodingError("JSONB payload exceeds blob size")
    }
    let payload = blob[index..<(index + payloadSize)]

    switch elementType {
    case 0:  // NULL
      index += payloadSize
      json.append("null")
    case 1:  // TRUE
      index += payloadSize
      json.append("true")
    case 2:  // FALSE
      index += payloadSize
      json.append("false")
    case 3:  // INT: Canonical JSON integer text.
      index += payloadSize
      json.append(String(decoding: payload, as: UTF8.self))
    case 4:  // INT5: JSON5 integer text (hexadecimal, leading '+').
      index += payloadSize
      try appendInt5(String(decoding: payload, as: UTF8.self), to: &json)
    case 5:  // FLOAT: Canonical JSON real text.
      index += payloadSize
      json.append(String(decoding: payload, as: UTF8.self))
    case 6:  // FLOAT5: JSON5 real text ('.5', '5.', '+1.5', 'Infinity', 'NaN').
      index += payloadSize
      try appendFloat5(String(decoding: payload, as: UTF8.self), to: &json)
    case 7, 10:  // TEXT, TEXTRAW: Unescaped text: add JSON escapes.
      index += payloadSize
      appendEscaped(String(decoding: payload, as: UTF8.self), to: &json)
    case 8:  // TEXTJ: JSON-escaped text: emit as is.
      index += payloadSize
      json.append("\"")
      json.append(String(decoding: payload, as: UTF8.self))
      json.append("\"")
    case 9:  // TEXT5: JSON5-escaped text: translate to JSON escapes.
      index += payloadSize
      try appendText5(String(decoding: payload, as: UTF8.self), to: &json)
    case 11:  // ARRAY
      let endIndex = index + payloadSize
      json.append("[")
      var isFirst = true
      while index < endIndex {
        if !isFirst {
          json.append(",")
        }
        isFirst = false
        try transcodeElement(blob, at: &index, into: &json)
      }
      guard index == endIndex else {
        throw DecodingError("Corrupt JSONB array payload")
      }
      json.append("]")
    case 12:  // OBJECT
      let endIndex = index + payloadSize
      json.append("{")
      var isFirst = true
      while index < endIndex {
        if !isFirst {
          json.append(",")
        }
        isFirst = false
        guard (7...10).contains(blob[index] & 0x0f) else {
          throw DecodingError("JSONB object key is not text")
        }
        try transcodeElement(blob, at: &index, into: &json)
        json.append(":")
        guard index < endIndex else {
          throw DecodingError("JSONB object key has no value")
        }
        try transcodeElement(blob, at: &index, into: &json)
      }
      guard index == endIndex else {
        throw DecodingError("Corrupt JSONB object payload")
      }
      json.append("}")
    default:
      throw DecodingError("Reserved JSONB element type \(elementType)")
    }
  }

  private static func appendInt5(_ text: String, to json: inout String) throws {
    var digits = text[...]
    var sign = ""
    if digits.first == "-" || digits.first == "+" {
      if digits.first == "-" {
        sign = "-"
      }
      digits = digits.dropFirst()
    }
    if digits.hasPrefix("0x") || digits.hasPrefix("0X") {
      guard let value = UInt64(digits.dropFirst(2), radix: 16) else {
        throw DecodingError("Invalid JSONB INT5 payload: \(text)")
      }
      json.append("\(sign)\(value)")
    } else {
      json.append("\(sign)\(digits)")
    }
  }

  private static func appendFloat5(_ text: String, to json: inout String) throws {
    var digits = text[...]
    var sign = ""
    if digits.first == "-" || digits.first == "+" {
      if digits.first == "-" {
        sign = "-"
      }
      digits = digits.dropFirst()
    }
    switch digits {
    case "Infinity":
      json.append("\(sign)9e999")
    case "NaN":
      json.append("null")
    default:
      var normalized = String(digits)
      if normalized.hasPrefix(".") {
        normalized = "0\(normalized)"
      }
      if let dot = normalized.firstIndex(of: "."),
        normalized.index(after: dot) == normalized.endIndex
          || !normalized[normalized.index(after: dot)].isNumber
      {
        normalized.insert("0", at: normalized.index(after: dot))
      }
      json.append("\(sign)\(normalized)")
    }
  }

  private static func appendText5(_ text: String, to json: inout String) throws {
    json.append("\"")
    var characters = text.makeIterator()
    while let character = characters.next() {
      guard character == "\\" else {
        json.append(character)
        continue
      }
      guard let escaped = characters.next() else {
        throw DecodingError("Dangling escape in JSONB TEXT5 payload")
      }
      switch escaped {
      case "\"", "\\", "/", "b", "f", "n", "r", "t", "u":
        json.append("\\")
        json.append(escaped)
      case "'":
        json.append("'")
      case "0":
        json.append("\\u0000")
      case "v":
        json.append("\\u000b")
      case "x":
        guard
          let hi = characters.next(),
          let lo = characters.next(),
          let value = UInt32("\(hi)\(lo)", radix: 16)
        else {
          throw DecodingError("Invalid '\\x' escape in JSONB TEXT5 payload")
        }
        appendUnicodeEscape(value, to: &json)
      case "\n", "\r", "\r\n", "\u{2028}", "\u{2029}":
        continue
      default:
        throw DecodingError("Invalid escape '\\\(escaped)' in JSONB TEXT5 payload")
      }
    }
    json.append("\"")
  }

  private static func appendEscaped(_ text: String, to json: inout String) {
    json.append("\"")
    for scalar in text.unicodeScalars {
      switch scalar {
      case "\"":
        json.append("\\\"")
      case "\\":
        json.append("\\\\")
      case "\u{08}":
        json.append("\\b")
      case "\u{0c}":
        json.append("\\f")
      case "\n":
        json.append("\\n")
      case "\r":
        json.append("\\r")
      case "\t":
        json.append("\\t")
      case let scalar where scalar.value < 0x20:
        appendUnicodeEscape(scalar.value, to: &json)
      default:
        json.unicodeScalars.append(scalar)
      }
    }
    json.append("\"")
  }

  private static func appendUnicodeEscape(_ value: UInt32, to json: inout String) {
    let hex = String(value, radix: 16)
    json.append("\\u")
    json.append(String(repeating: "0", count: 4 - hex.count))
    json.append(hex)
  }
}
