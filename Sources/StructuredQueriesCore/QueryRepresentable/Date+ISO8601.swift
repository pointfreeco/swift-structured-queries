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

    public init(queryOutput: Date) {
      self.queryOutput = queryOutput
    }
  }
}

extension Date.ISO8601Representation: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(queryOutput.iso8601String)
  }
}

extension Date.ISO8601Representation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(queryOutput: String(decoder: &decoder).iso8601)
  }
}

extension Date {
  fileprivate var iso8601String: String {
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

extension String {
  var iso8601: Date {
    get throws {
      if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
        do {
          return try Date(
            queryOutput,
            strategy: .iso8601.currentTimestamp(includingFractionalSeconds: true)
          )
        } catch {
          return try Date(
            queryOutput,
            strategy: .iso8601.currentTimestamp(includingFractionalSeconds: false)
          )
        }
      } else {
        guard
          let date = DateFormatter.iso8601(includingFractionalSeconds: true).date(from: self)
            ?? DateFormatter.iso8601(includingFractionalSeconds: false).date(from: self)
        else {
          struct InvalidDate: Error { let string: String }
          throw InvalidDate(string: self)
        }
        return date
      }
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
