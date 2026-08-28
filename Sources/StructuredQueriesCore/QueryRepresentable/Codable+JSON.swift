import Foundation

public struct _CodableJSONRepresentation<QueryOutput: Codable>: Codable, QueryRepresentable {
  public var queryOutput: QueryOutput

  public init(queryOutput: QueryOutput) {
    self.queryOutput = queryOutput
  }

  public static func _queryFragment(jsonEncoding queryFragment: QueryFragment) -> QueryFragment {
    "json(\(queryFragment))"
  }
}

extension _CodableJSONRepresentation: Equatable where QueryOutput: Equatable {}
extension _CodableJSONRepresentation: Hashable where QueryOutput: Hashable {}
extension _CodableJSONRepresentation: Sendable where QueryOutput: Sendable {}

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
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    let json: Data
    do {
      json = try jsonEncoder.encode(queryOutput)
    } catch {
      throw .other(error)
    }
    try encoder.encode(String(decoding: json, as: UTF8.self))
  }
}

extension _CodableJSONRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws(QueryDecodingError) {
    let json = try String(decoder: &decoder)
    do {
      self.init(queryOutput: try jsonDecoder.decode(QueryOutput.self, from: Data(json.utf8)))
    } catch {
      throw .other(error)
    }
  }
}
