public import Foundation
public import StructuredQueriesCore

extension UUID {
  /// A query expression representing a UUID as bytes.
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   @Column(as: UUID.BytesRepresentation.self)
  ///   let id: UUID
  /// }
  ///
  /// Item.insert { $0.id } values: { UUID() }
  /// // INSERT INTO "items" ("id") VALUES (<blob>)
  /// ```
  public struct BytesRepresentation: QueryRepresentable {
    public static func _queryFragment(jsonEncoding queryFragment: QueryFragment) -> QueryFragment {
      """
      CASE WHEN \(queryFragment) IS NULL THEN NULL ELSE lower(printf('%s-%s-%s-%s-%s', \
      substr(hex(\(queryFragment)), 1, 8), \
      substr(hex(\(queryFragment)), 9, 4), \
      substr(hex(\(queryFragment)), 13, 4), \
      substr(hex(\(queryFragment)), 17, 4), \
      substr(hex(\(queryFragment)), 21, 12))) END
      """
    }

    public var queryOutput: UUID

    public init(queryOutput: UUID) {
      self.queryOutput = queryOutput
    }
  }
}

extension UUID? {
  public typealias BytesRepresentation = UUID.BytesRepresentation?
}

extension UUID.BytesRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    .blob(withUnsafeBytes(of: queryOutput.uuid, [UInt8].init))
  }
}

extension UUID.BytesRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    let queryOutput = try [UInt8](decoder: &decoder)
    guard queryOutput.count == 16 else {
      throw InvalidBytes()
    }
    self.init(
      queryOutput: queryOutput.withUnsafeBytes {
        UUID(uuid: $0.load(as: uuid_t.self))
      }
    )
  }

  private struct InvalidBytes: Error {}
}

extension UUID.BytesRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    [UInt8].typeAffinity
  }
}
