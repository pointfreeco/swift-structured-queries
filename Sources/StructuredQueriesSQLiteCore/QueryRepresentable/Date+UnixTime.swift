import Foundation

extension Date {
  /// A query expression representing a date as the integer number of seconds past the unix epoch.
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   @Column(as: Date.UnixTimeRepresentation.self)
  ///   var date: Date
  /// }
  ///
  /// Item.insert { $0.date } values: { Date() }
  /// // INSERT INTO "items" ("date") VALUES (1517212800)
  /// ```
  public struct UnixTimeRepresentation: QueryRepresentable {
    public var queryOutput: Date

    public init(queryOutput: Date) {
      self.queryOutput = queryOutput
    }
  }
}

extension Date? {
  public typealias UnixTimeRepresentation = Date.UnixTimeRepresentation?
}

extension Date.UnixTimeRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    .int(Int64(queryOutput.timeIntervalSince1970))
  }
}

extension Date.UnixTimeRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(queryOutput: Date(timeIntervalSince1970: Double(decoder: &decoder)))
  }
}

extension Date.UnixTimeRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    Int.typeAffinity
  }
}
