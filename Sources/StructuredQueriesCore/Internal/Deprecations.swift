import Foundation

// NB: Deprecated after 0.3.0:

extension Date {
  @available(
    *,
    deprecated,
    message: "ISO-8601 text is the default representation and is no longer explicitly needed."
  )
  public struct ISO8601Representation: QueryRepresentable {
    public var queryOutput: Date

    public var iso8601String: String {
      queryOutput.iso8601String
    }

    public init(queryOutput: Date) {
      self.queryOutput = queryOutput
    }

    public init(iso8601String: String) throws {
      try self.init(queryOutput: Date(iso8601String: iso8601String))
    }
  }
}

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date? {
  public typealias ISO8601Representation = Date.ISO8601Representation?
}

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date.ISO8601Representation: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(queryOutput.iso8601String)
  }
}

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date.ISO8601Representation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(queryOutput: Date(iso8601String: String(decoder: &decoder)))
  }
}

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date.ISO8601Representation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID {
  public struct LowercasedRepresentation: QueryRepresentable {
    public var queryOutput: UUID

    public init(queryOutput: UUID) {
      self.queryOutput = queryOutput
    }
  }
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID? {
  public typealias LowercasedRepresentation = UUID.LowercasedRepresentation?
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID.LowercasedRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(queryOutput.uuidString.lowercased())
  }
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID.LowercasedRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    guard let uuid = try UUID(uuidString: String(decoder: &decoder)) else {
      throw InvalidString()
    }
    self.init(queryOutput: uuid)
  }

  private struct InvalidString: Error {}
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID.LowercasedRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}

// NB: Deprecated after 0.1.1:

@available(*, deprecated, message: "Use 'MyCodableType.JSONRepresentation', instead.")
public typealias JSONRepresentation<Value: Codable> = _CodableJSONRepresentation<Value>
