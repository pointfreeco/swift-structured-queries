import Foundation

extension Date {
  /// A query expression representing a date as double Julian day number.
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   @Column(as: Date.JulianDayRepresentation.self)
  ///   var date: Date
  /// }
  ///
  /// Item.insert { $0.date } values: { Date() }
  /// // INSERT INTO "items" ("date") VALUES (2458147.5)
  /// ```
  public struct JulianDayRepresentation: QueryRepresentable {
    public var queryOutput: Date

    public init(queryOutput: Date) {
      self.queryOutput = queryOutput
    }
  }
}

extension Date? {
  public typealias JulianDayRepresentation = Date.JulianDayRepresentation?
}

extension Date.JulianDayRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    .double(2440587.5 + queryOutput.timeIntervalSince1970 / 86400)
  }
}

extension Date.JulianDayRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(
      queryOutput: Date(timeIntervalSince1970: (Double(decoder: &decoder) - 2440587.5) * 86400)
    )
  }
}

extension Date.JulianDayRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    Double.typeAffinity
  }
}
