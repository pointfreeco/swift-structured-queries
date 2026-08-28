public import Foundation
public import StructuredQueriesCore

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

    public static func _queryFragment(jsonEncoding queryFragment: QueryFragment) -> QueryFragment {
      "datetime(\(queryFragment), 'unixepoch')"
    }

    public static func _queryFragment(jsonDecoding queryFragment: QueryFragment) -> QueryFragment {
      "unixepoch(\(queryFragment))"
    }
  }
}

extension Date? {
  public typealias UnixTimeRepresentation = Date.UnixTimeRepresentation?
}

extension Date.UnixTimeRepresentation: QueryBindable {
  public func encode(to encoder: inout some QueryEncoder) throws(QueryEncodingError) {
    try encoder.encode(Int64(queryOutput.timeIntervalSince1970))
  }
}

extension Date.UnixTimeRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws(QueryDecodingError) {
    try self.init(queryOutput: Date(timeIntervalSince1970: Double(Int64(decoder: &decoder))))
  }
}

extension Date.UnixTimeRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    Int.typeAffinity
  }
}
