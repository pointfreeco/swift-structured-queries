import Foundation

extension Date {
  /// A query expression representing a date as an ISO-8601-formatted string (in RFC 3339 format).
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   @Column(as: Date.ISO8601Representation.self)
  ///   var date: Date
  /// }
  ///
  /// Item.insert { $0.date } values: { Date() }
  /// // INSERT INTO "items" ("date") VALUES ('2018-01-29 00:08:00.000')
  /// ```
  public struct ISO8601Representation: QueryRepresentable {
    public var queryOutput: Date

    public var iso8601String: String {
      queryOutput.iso8601String
    }

    public init(queryOutput: Date) {
      self.queryOutput = queryOutput
    }

    public init(iso8601String: String) throws {
      try self.init(queryOutput: Date(iso8601String: iso8601String))
    }
  }
}

extension Date? {
  public typealias ISO8601Representation = Date.ISO8601Representation?
}

extension Date.ISO8601Representation: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(queryOutput.iso8601String)
  }
}

extension Date.ISO8601Representation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(queryOutput: Date(iso8601String: String(decoder: &decoder)))
  }
}

extension Date {
  package var iso8601String: String {
    if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
      return formatted(.iso8601.currentTimestamp(includingFractionalSeconds: true))
    } else {
      return DateFormatter.iso8601(includingFractionalSeconds: true).string(from: self)
    }
  }
}

extension DateFormatter {
  fileprivate static func iso8601(includingFractionalSeconds: Bool) -> DateFormatter {
    includingFractionalSeconds ? iso8601Fractional : iso8601Whole
  }

  fileprivate static let iso8601Fractional: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()

  fileprivate static let iso8601Whole: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()
}

extension Date {
  @usableFromInline
  package init(iso8601String: String) throws {
    if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
      do {
        try self.init(
          iso8601String.queryOutput,
          strategy: .iso8601.currentTimestamp(includingFractionalSeconds: true)
        )
      } catch {
        try self.init(
          iso8601String.queryOutput,
          strategy: .iso8601.currentTimestamp(includingFractionalSeconds: false)
        )
      }
    } else {
      guard
        let date = DateFormatter.iso8601(includingFractionalSeconds: true).date(from: iso8601String)
          ?? DateFormatter.iso8601(includingFractionalSeconds: false).date(from: iso8601String)
      else {
        struct InvalidDate: Error { let string: String }
        throw InvalidDate(string: iso8601String)
      }
      self = date
    }
  }
}

extension Date.ISO8601Representation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Date.ISO8601FormatStyle {
  fileprivate func currentTimestamp(includingFractionalSeconds: Bool) -> Self {
    year().month().day()
      .dateTimeSeparator(.space)
      .time(includingFractionalSeconds: includingFractionalSeconds)
  }
}
