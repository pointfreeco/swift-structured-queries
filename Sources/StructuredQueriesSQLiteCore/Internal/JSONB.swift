#if compiler(>=6.2)
  /// A decoder of SQLite's binary JSON format.
  ///
  /// Transcodes a JSONB blob (see <https://sqlite.org/jsonb.html>) to equivalent JSON text,
  /// suitable for feeding to a `JSONDecoder`.
  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  package enum JSONB {
    package struct DecodingError: Error {
      package let debugDescription: String

      init(_ debugDescription: String) {
        self.debugDescription = debugDescription
      }
    }

    package static func json(from blob: Span<UInt8>) throws -> [UInt8] {
      var json: [UInt8] = []
      json.reserveCapacity(blob.count + blob.count / 4)
      var index = 0
      try transcodeElement(blob, at: &index, into: &json)
      guard index == blob.count else {
        throw DecodingError("Unexpected trailing bytes after JSONB element")
      }
      return json
    }

    private static func transcodeElement(
      _ blob: Span<UInt8>,
      at index: inout Int,
      into json: inout [UInt8]
    ) throws {
      guard index < blob.count else {
        throw DecodingError("Unexpected end of JSONB blob")
      }
      let header = blob[index]
      let elementType = header & 0x0f
      var payloadSize = Int(header >> 4)
      index += 1
      if payloadSize > 11 {
        let sizeWidth = 1 << (payloadSize - 12)
        guard blob.count - index >= sizeWidth else {
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
      guard payloadSize <= blob.count - index else {
        throw DecodingError("JSONB payload exceeds blob size")
      }
      let payloadEnd = index + payloadSize

      switch elementType {
      case 0:  // NULL
        index = payloadEnd
        json.append(contentsOf: "null".utf8)
      case 1:  // TRUE
        index = payloadEnd
        json.append(contentsOf: "true".utf8)
      case 2:  // FALSE
        index = payloadEnd
        json.append(contentsOf: "false".utf8)
      case 3, 5:  // INT, FLOAT: Canonical JSON number text.
        appendPayload(blob.extracting(index..<payloadEnd), to: &json)
        index = payloadEnd
      case 4:  // INT5: JSON5 integer text (hexadecimal, leading '+').
        try appendInt5(string(blob.extracting(index..<payloadEnd)), to: &json)
        index = payloadEnd
      case 6:  // FLOAT5: JSON5 real text ('.5', '5.', '+1.5', 'Infinity', 'NaN').
        try appendFloat5(string(blob.extracting(index..<payloadEnd)), to: &json)
        index = payloadEnd
      case 7, 10:  // TEXT, TEXTRAW: Unescaped text: add JSON escapes.
        appendEscaped(blob.extracting(index..<payloadEnd), to: &json)
        index = payloadEnd
      case 8:  // TEXTJ: JSON-escaped text: emit as is.
        json.append(UInt8(ascii: "\""))
        appendPayload(blob.extracting(index..<payloadEnd), to: &json)
        json.append(UInt8(ascii: "\""))
        index = payloadEnd
      case 9:  // TEXT5: JSON5-escaped text: translate to JSON escapes.
        try appendText5(string(blob.extracting(index..<payloadEnd)), to: &json)
        index = payloadEnd
      case 11:  // ARRAY
        json.append(UInt8(ascii: "["))
        var isFirst = true
        while index < payloadEnd {
          if !isFirst {
            json.append(UInt8(ascii: ","))
          }
          isFirst = false
          try transcodeElement(blob, at: &index, into: &json)
        }
        guard index == payloadEnd else {
          throw DecodingError("Corrupt JSONB array payload")
        }
        json.append(UInt8(ascii: "]"))
      case 12:  // OBJECT
        json.append(UInt8(ascii: "{"))
        var isFirst = true
        while index < payloadEnd {
          if !isFirst {
            json.append(UInt8(ascii: ","))
          }
          isFirst = false
          guard (7...10).contains(blob[index] & 0x0f) else {
            throw DecodingError("JSONB object key is not text")
          }
          try transcodeElement(blob, at: &index, into: &json)
          json.append(UInt8(ascii: ":"))
          guard index < payloadEnd else {
            throw DecodingError("JSONB object key has no value")
          }
          try transcodeElement(blob, at: &index, into: &json)
        }
        guard index == payloadEnd else {
          throw DecodingError("Corrupt JSONB object payload")
        }
        json.append(UInt8(ascii: "}"))
      default:
        throw DecodingError("Reserved JSONB element type \(elementType)")
      }
    }

    private static func appendPayload(_ payload: Span<UInt8>, to json: inout [UInt8]) {
      payload.withUnsafeBufferPointer { json.append(contentsOf: $0) }
    }

    private static func string(_ payload: Span<UInt8>) -> String {
      payload.withUnsafeBufferPointer { String(decoding: $0, as: UTF8.self) }
    }

    /// Appends a raw string payload as quoted, escaped JSON text.
    ///
    /// Escape-free runs are appended in bulk, so a payload that needs no escaping (which is
    /// guaranteed for `TEXT` elements, and common for `TEXTRAW`) is copied in a single append.
    private static func appendEscaped(_ payload: Span<UInt8>, to json: inout [UInt8]) {
      json.append(UInt8(ascii: "\""))
      var runStart = 0
      var index = 0
      while index < payload.count {
        let byte = payload[index]
        if byte < 0x20 || byte == UInt8(ascii: "\"") || byte == UInt8(ascii: "\\") {
          appendPayload(payload.extracting(runStart..<index), to: &json)
          switch byte {
          case UInt8(ascii: "\""), UInt8(ascii: "\\"):
            json.append(UInt8(ascii: "\\"))
            json.append(byte)
          case 0x08:
            json.append(contentsOf: #"\b"#.utf8)
          case 0x09:
            json.append(contentsOf: #"\t"#.utf8)
          case 0x0a:
            json.append(contentsOf: #"\n"#.utf8)
          case 0x0c:
            json.append(contentsOf: #"\f"#.utf8)
          case 0x0d:
            json.append(contentsOf: #"\r"#.utf8)
          default:
            appendUnicodeEscape(UInt32(byte), to: &json)
          }
          runStart = index + 1
        }
        index += 1
      }
      appendPayload(payload.extracting(runStart..<payload.count), to: &json)
      json.append(UInt8(ascii: "\""))
    }

    private static func appendInt5(_ text: String, to json: inout [UInt8]) throws {
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
        json.append(contentsOf: "\(sign)\(value)".utf8)
      } else {
        json.append(contentsOf: "\(sign)\(digits)".utf8)
      }
    }

    private static func appendFloat5(_ text: String, to json: inout [UInt8]) throws {
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
        json.append(contentsOf: "\(sign)9e999".utf8)
      case "NaN":
        json.append(contentsOf: "null".utf8)
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
        json.append(contentsOf: "\(sign)\(normalized)".utf8)
      }
    }

    private static func appendText5(_ text: String, to json: inout [UInt8]) throws {
      json.append(UInt8(ascii: "\""))
      var characters = text.makeIterator()
      while let character = characters.next() {
        guard character == "\\" else {
          json.append(contentsOf: String(character).utf8)
          continue
        }
        guard let escaped = characters.next() else {
          throw DecodingError("Dangling escape in JSONB TEXT5 payload")
        }
        switch escaped {
        case "\"", "\\", "/", "b", "f", "n", "r", "t", "u":
          json.append(UInt8(ascii: "\\"))
          json.append(contentsOf: String(escaped).utf8)
        case "'":
          json.append(UInt8(ascii: "'"))
        case "0":
          json.append(contentsOf: #"\u0000"#.utf8)
        case "v":
          json.append(contentsOf: #"\u000b"#.utf8)
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
      json.append(UInt8(ascii: "\""))
    }

    private static func appendUnicodeEscape(_ value: UInt32, to json: inout [UInt8]) {
      let hex = String(value, radix: 16)
      json.append(contentsOf: "\\u".utf8)
      json.append(contentsOf: repeatElement(UInt8(ascii: "0"), count: 4 - hex.count))
      json.append(contentsOf: hex.utf8)
    }
  }
#endif
