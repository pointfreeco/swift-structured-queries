import Foundation

public struct _CodableJSONRepresentation<QueryOutput: Codable>: Codable, QueryRepresentable {
  public var queryOutput: QueryOutput

  public init(queryOutput: QueryOutput) {
    self.queryOutput = queryOutput
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
  public var queryBinding: QueryBinding {
    do {
      return try .text(String(decoding: jsonEncoder.encode(queryOutput), as: UTF8.self))
    } catch {
      return .invalid(error)
    }
  }
}

extension _CodableJSONRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    self.init(
      queryOutput: try jsonDecoder.decode(
        QueryOutput.self,
        from: Data(String(decoder: &decoder).utf8)
      )
    )
  }
}
