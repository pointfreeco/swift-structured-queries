import Foundation
import IssueReporting
public import StructuredQueriesCore

/// A type that enumerates the values that can be bound to the parameters of a SQLite statement.
///
/// Each case corresponds to one of SQLite's fundamental data types. Richer values are
/// materialized into these representations by the encoder that produces bindings: Booleans as
/// integers, dates as ISO-8601 text, UUIDs as lowercased text, and unsigned integers as integers
/// when they fit.
public enum SQLiteValue: Hashable, Sendable {
  /// A value that should be bound to a statement as bytes.
  case blob([UInt8])

  /// A value that should be bound to a statement as a double.
  case double(Double)

  /// A value that should be bound to a statement as an integer.
  case int(Int64)

  /// A value that should be bound to a statement as `NULL`.
  case null

  /// A value that should be bound to a statement as a string.
  case text(String)
}

extension SQLiteValue: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .blob(let blob):
      let hex = blob.reduce(into: "") {
        let hex = String($1, radix: 16)
        if hex.count == 1 {
          $0.append("0")
        }
        $0.append(hex)
      }
      return "X\(hex.quoted(.text))"
    case .double(let double):
      return "\(double)"
    case .int(let int):
      return "\(int)"
    case .null:
      return "NULL"
    case .text(let text):
      return text.quoted(.text)
    }
  }
}

extension QueryEncodable {
  package var _materializedValue: SQLiteValue {
    get throws(QueryEncodingError) {
      var encoder = SQLiteValueEncoder()
      try encode(to: &encoder)
      return encoder.binding
    }
  }
}

struct SQLiteValueEncoder: QueryEncoder {
  var binding: SQLiteValue = .null

  init() {}

  mutating func encode(_ value: [UInt8]) {
    binding = .blob(value)
  }

  mutating func encode(_ value: Bool) {
    binding = .int(value ? 1 : 0)
  }

  mutating func encode(_ value: Date) {
    binding = .text(value.iso8601String)
  }

  mutating func encode(_ value: Double) {
    binding = .double(value)
  }

  mutating func encode(_ value: Int) {
    binding = .int(Int64(value))
  }

  mutating func encode(_ value: Int64) {
    binding = .int(value)
  }

  mutating func encode(_ value: String) {
    binding = .text(value)
  }

  mutating func encode(_ value: UInt64) throws(QueryEncodingError) {
    guard value <= UInt64(Int64.max) else { throw .dataCorrupted }
    binding = .int(Int64(value))
  }

  mutating func encode(_ value: UUID) {
    binding = .text(value.uuidString.lowercased())
  }

  mutating func encodeNull() {
    binding = .null
  }
}

extension QueryBindable {
  /// A value that can be bound to a parameter of a SQL statement.
  ///
  /// This value is derived from ``QueryEncodable/encode(to:)``: the value describes its single
  /// column to an encoder that materializes SQLite's binding representation.
  public var sqliteValue: SQLiteValue {
    get throws(QueryEncodingError) {
      try _materializedValue
    }
  }
}

extension QueryFragment {
  package func compiled(statementType: String) -> Self {
    segments.reduce(into: QueryFragment()) {
      switch $1 {
      case .sql(let sql):
        $0.append("\(raw: sql)")
      case .binding(nil):
        $0.append("NULL")
      case .invalid, .identifier:
        $0.append(QueryFragment(segments: [$1]))
      case .binding(let value?):
        guard let binding = try? value._materializedValue else {
          $0.append(QueryFragment(binding: value))
          return
        }
        if case .text = binding {
          if value is Date || value is Date? {
            reportIssue(
              """
              Swift Date values should not be bound to a '\(statementType)' statement. Specify \
              dates using the '#sql' macro, instead. For example, the current date:

                  #sql("datetime()")

              Or a constant date:

                  #sql("'2018-01-29 00:08:00'")
              """
            )
          } else if value is UUID || value is UUID? {
            reportIssue(
              """
              Swift UUID values should not be bound to a '\(statementType)' statement. Specify \
              UUIDs using the '#sql' macro, instead. For example, a random UUID:

                  #sql("uuid()")

              Or a constant UUID:

                  #sql("'00000000-0000-0000-0000-000000000000'")
              """
            )
          }
        }
        switch binding {
        case .blob(let blob):
          let hex = blob.reduce(into: "") {
            let hex = String($1, radix: 16)
            if hex.count == 1 {
              $0.append("0")
            }
            $0.append(hex)
          }
          $0.append("X\(quote: hex, delimiter: .text)")
        case .double(let double):
          $0.append("\(raw: double)")
        case .int(let int):
          $0.append("\(raw: int)")
        case .null:
          $0.append("NULL")
        case .text(let string):
          $0.append("\(quote: string, delimiter: .text)")
        }
      }
    }
  }
}
