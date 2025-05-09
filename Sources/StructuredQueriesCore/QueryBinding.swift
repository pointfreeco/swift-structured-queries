import Foundation
import StructuredQueriesSupport

/// A type that enumerates the values that can be bound to the parameters of a SQL statement.
public enum QueryBinding: Hashable, Sendable {
  /// A value that should be bound to a statement as bytes.
  case blob([UInt8])

  /// A value that should be bound to a statement as a double.
  case double(Double)

  /// A value that should be bound to a statement as a date.
  case date(Date)

  /// A value that should be bound to a statement as an integer.
  case int(Int64)

  /// A value that should be bound to a statement as `NULL`.
  case null

  /// A value that should be bound to a statement as a string.
  case text(String)

  /// A value that should be bound to a statement as a unique identifier.
  case uuid(UUID)

  /// An error describing why a value cannot be bound to a statement.
  case invalid(QueryBindingError)

  @_disfavoredOverload
  public static func invalid(_ error: any Error) -> Self {
    .invalid(QueryBindingError(underlyingError: error))
  }
}

/// A type that wraps errors encountered when trying to bind a value to a statement.
public struct QueryBindingError: Error, Hashable {
  public let underlyingError: any Error
  public init(underlyingError: any Error) {
    self.underlyingError = underlyingError
  }
  public static func == (lhs: Self, rhs: Self) -> Bool { true }
  public func hash(into hasher: inout Hasher) {}
}

extension QueryBinding: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case let .blob(data):
      return String(decoding: data, as: UTF8.self)
        .debugDescription
        .dropLast()
        .dropFirst()
        .quoted(.text)
    case let .date(date):
      return date.iso8601String.quoted(.text)
    case let .double(value):
      return "\(value)"
    case let .int(value):
      return "\(value)"
    case .null:
      return "NULL"
    case let .text(string):
      return string.quoted(.text)
    case let .uuid(uuid):
      return uuid.uuidString.lowercased().quoted(.text)
    case let .invalid(error):
      return "<invalid: \(error.underlyingError.localizedDescription)>"
    }
  }
}
