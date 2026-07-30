import Foundation
public import StructuredQueriesCore

public struct _CodableJSONBRepresentation<QueryOutput: Codable>: Codable, QueryRepresentable {
  public var queryOutput: QueryOutput

  public init(queryOutput: QueryOutput) {
    self.queryOutput = queryOutput
  }

  public static func queryFragment(decoding queryFragment: QueryFragment) -> QueryFragment {
    "json(\(queryFragment))"
  }
}

extension _CodableJSONBRepresentation: Equatable where QueryOutput: Equatable {}
extension _CodableJSONBRepresentation: Hashable where QueryOutput: Hashable {}
extension _CodableJSONBRepresentation: Sendable where QueryOutput: Sendable {}

extension Decodable where Self: Encodable {
  /// A query expression representing codable JSONB.
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   @Column(as: [String].JSONBRepresentation.self)
  ///   var notes: [String] = []
  /// }
  ///
  /// Item.insert { $0.notes } values: { ["First post", "An update"] }
  /// // INSERT INTO "items" ("notes") VALUES (jsonb('["First post","An update"]'))
  ///
  /// Item.all
  /// // SELECT json("items"."notes") FROM "items"
  /// ```
  public typealias JSONBRepresentation = _CodableJSONBRepresentation<Self>
}

extension Optional where Wrapped: Codable {
  @_documentation(visibility: private)
  public typealias JSONBRepresentation = _CodableJSONBRepresentation<Wrapped>?
}

extension _CodableJSONBRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    do {
      return try .text(String(decoding: jsonEncoder.encode(queryOutput), as: UTF8.self))
    } catch {
      return .invalid(error)
    }
  }

  public var queryFragment: QueryFragment {
    "jsonb(\(queryBinding))"
  }
}

extension _CodableJSONBRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    self.init(
      queryOutput: try jsonDecoder.decode(
        QueryOutput.self,
        from: Data(String(decoder: &decoder).utf8)
      )
    )
  }
}

extension _CodableJSONBRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { .blob }
}
