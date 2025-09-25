import Foundation

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
  public init?(queryBinding: QueryBinding) {
    guard
      case .text(let uuidString) = queryBinding,
      let uuid = UUID(uuidString: uuidString)
    else { return nil }
    self.init(queryOutput: uuid)
  }

  public var queryBinding: QueryBinding {
    .text(queryOutput.uuidString)
  }
}

extension UUID.UppercasedRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    guard let uuid = try UUID(uuidString: String(decoder: &decoder)) else {
      throw InvalidString()
    }
    self.init(queryOutput: uuid)
  }

  private struct InvalidString: Error {}
}

extension UUID.UppercasedRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}
