public import Foundation
public import StructuredQueriesCore

extension UUID {
  /// A query expression representing a UUID as an uppercased string.
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   @Column(as: UUID.UppercasedRepresentation.self)
  ///   let id: UUID
  /// }
  ///
  /// Item.insert { $0.id } values: { UUID() }
  /// // INSERT INTO "items" ("id") VALUES ('DEADBEEF-DEAD-BEEF-DEAD-DEADBEEFDEAD')
  /// ```
  public struct UppercasedRepresentation: QueryRepresentable {
    public var queryOutput: UUID

    public init(queryOutput: UUID) {
      self.queryOutput = queryOutput
    }
  }
}

extension UUID? {
  public typealias UppercasedRepresentation = UUID.UppercasedRepresentation?
}

extension UUID.UppercasedRepresentation: QueryBindable {
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(queryOutput.uuidString)
  }
}

extension UUID.UppercasedRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws(QueryDecodingError) {
    guard let uuid = try UUID(uuidString: String(decoder: &decoder))
    else { throw .dataCorrupted }
    self.init(queryOutput: uuid)
  }
}

extension UUID.UppercasedRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}
