import Foundation

public struct _CodableJSONRepresentation<QueryOutput: Codable & Sendable>: QueryRepresentable {
  public var queryOutput: QueryOutput

  public init(queryOutput: QueryOutput) {
    self.queryOutput = queryOutput
  }

  public init(decoder: inout some QueryDecoder) throws {
    self.init(
      queryOutput: try jsonDecoder.decode(
        QueryOutput.self,
        from: Data(String(decoder: &decoder).utf8)
      )
    )
  }
}

extension Decodable where Self: Encodable {
  /// A query expression representing codable JSON.
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   @Column(as: [String].JSONRepresentation.self)
  ///   var notes: [String] = []
  /// }
  ///
  /// Item.insert { $0.notes } values: { ["First post", "An update"] }
  /// // INSERT INTO "items" ("notes") VALUES ('["First post","An update"]')
  /// ```
  public typealias JSONRepresentation = _CodableJSONRepresentation<Self>
}

extension Optional where Wrapped: Codable {
  @_documentation(visibility: private)
  public typealias JSONRepresentation = _CodableJSONRepresentation<Wrapped>?
}

extension _CodableJSONRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    do {
      return try .text(String(decoding: jsonEncoder.encode(queryOutput), as: UTF8.self))
    } catch {
      return .invalid(error)
    }
  }
}

extension _CodableJSONRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}

private let jsonDecoder: JSONDecoder = {
  var decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .custom {
    try $0.singleValueContainer().decode(String.self).iso8601
  }
  return decoder
}()

private let jsonEncoder: JSONEncoder = {
  var encoder = JSONEncoder()
  #if DEBUG
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  #endif
  return encoder
}()
