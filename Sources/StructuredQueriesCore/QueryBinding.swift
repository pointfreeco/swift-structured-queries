import Foundation

/// A type that represents values that can be bound to the parameters of a SQL statement.
public protocol QueryBinding: Hashable, Sendable {
  /// A textual representation of this binding suitable for debugging.
  var debugDescription: String { get }
}

/// A result builder for constructing QueryBinding values conditionally.
@resultBuilder
public enum QueryBindingBuilder {
  public static func buildBlock<B: QueryBinding>(_ component: B) -> B {
    component
  }
  
  public static func buildEither<First: QueryBinding, Second: QueryBinding>(
    first component: First
  ) -> ConditionalQueryBinding<First, Second> {
    .first(component)
  }
  
  public static func buildEither<First: QueryBinding, Second: QueryBinding>(
    second component: Second
  ) -> ConditionalQueryBinding<First, Second> {
    .second(component)
  }
}

/// A binding that represents one of two possible binding types, determined at runtime.
public enum ConditionalQueryBinding<First: QueryBinding, Second: QueryBinding>: QueryBinding {
  case first(First)
  case second(Second)
  
  /// Returns the underlying binding as an existential type.
  public var underlyingBinding: any QueryBinding {
    switch self {
    case .first(let binding):
      return binding
    case .second(let binding):
      return binding
    }
  }
  
  public var debugDescription: String {
    switch self {
    case .first(let binding):
      return binding.debugDescription
    case .second(let binding):
      return binding.debugDescription
    }
  }
  
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.first(let l), .first(let r)):
      return l == r
    case (.second(let l), .second(let r)):
      return l == r
    default:
      return false
    }
  }
  
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .first(let binding):
      hasher.combine(0)
      hasher.combine(binding)
    case .second(let binding):
      hasher.combine(1)
      hasher.combine(binding)
    }
  }
}

// MARK: - Standard Binding Types

/// A binding that represents bytes/blob data.
public struct BlobBinding: QueryBinding, Hashable, Sendable {
  public let value: [UInt8]
  
  public init(_ value: [UInt8]) {
    self.value = value
  }
  
  public var debugDescription: String {
    String(decoding: value, as: UTF8.self)
      .debugDescription
      .dropLast()
      .dropFirst()
      .quoted(.text)
  }
}

/// A binding that represents a boolean value.
public struct BoolBinding: QueryBinding, Hashable, Sendable {
  public let value: Bool
  
  public init(_ value: Bool) {
    self.value = value
  }
  
  public var debugDescription: String {
    value ? "1" : "0"
  }
}

/// A binding that represents a double-precision floating point value.
public struct DoubleBinding: QueryBinding, Hashable, Sendable {
  public let value: Double
  
  public init(_ value: Double) {
    self.value = value
  }
  
  public var debugDescription: String {
    "\(value)"
  }
}

/// A binding that represents a date value.
public struct DateBinding: QueryBinding, Hashable, Sendable {
  public let value: Date
  
  public init(_ value: Date) {
    self.value = value
  }
  
  public var debugDescription: String {
    value.iso8601String.quoted(.text)
  }
}

/// A binding that represents an integer value.
public struct IntBinding: QueryBinding, Hashable, Sendable {
  public let value: Int64
  
  public init(_ value: Int64) {
    self.value = value
  }
  
  public var debugDescription: String {
    "\(value)"
  }
}

/// A binding that represents a NULL value.
public struct NullBinding: QueryBinding, Hashable, Sendable {
  public init() {}
  
  public var debugDescription: String {
    "NULL"
  }
}

/// A binding that represents a text/string value.
public struct TextBinding: QueryBinding, Hashable, Sendable {
  public let value: String
  
  public init(_ value: String) {
    self.value = value
  }
  
  public var debugDescription: String {
    value.quoted(.text)
  }
}

/// A binding that represents a UUID value.
public struct UUIDBinding: QueryBinding, Hashable, Sendable {
  public let value: UUID
  
  public init(_ value: UUID) {
    self.value = value
  }
  
  public var debugDescription: String {
    value.uuidString.lowercased().quoted(.text)
  }
}

/// A binding that represents a UInt64 value.
/// This type handles potential overflow when converting to Int64 for database storage.
public struct UInt64Binding: QueryBinding, Hashable, Sendable {
  public let value: UInt64
  
  public init(_ value: UInt64) {
    self.value = value
  }
  
  /// Returns true if the value would overflow when converting to Int64.
  public var overflows: Bool {
    value > UInt64(Int64.max)
  }
  
  /// Returns the value as Int64 if it doesn't overflow, otherwise nil.
  public var int64Value: Int64? {
    overflows ? nil : Int64(value)
  }
  
  public var debugDescription: String {
    if overflows {
      return "<invalid: UInt64 overflow>"
    } else {
      return "\(value)"
    }
  }
}

/// A binding that represents an invalid value with an associated error.
public struct InvalidBinding: QueryBinding, Hashable, Sendable {
  public let error: QueryBindingError
  
  public init(_ error: QueryBindingError) {
    self.error = error
  }
  
  @_disfavoredOverload
  public init(_ error: any Error) {
    self.error = QueryBindingError(underlyingError: error)
  }
  
  public var debugDescription: String {
    "<invalid: \(error.underlyingError.localizedDescription)>"
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

// MARK: - Convenience Factory Methods

// These provide backward compatibility and ergonomic API similar to the old enum

extension QueryBinding where Self == BlobBinding {
  /// Creates a blob binding.
  public static func blob(_ value: [UInt8]) -> BlobBinding {
    BlobBinding(value)
  }
}

extension QueryBinding where Self == BoolBinding {
  /// Creates a boolean binding.
  public static func bool(_ value: Bool) -> BoolBinding {
    BoolBinding(value)
  }
}

extension QueryBinding where Self == DoubleBinding {
  /// Creates a double binding.
  public static func double(_ value: Double) -> DoubleBinding {
    DoubleBinding(value)
  }
}

extension QueryBinding where Self == DateBinding {
  /// Creates a date binding.
  public static func date(_ value: Date) -> DateBinding {
    DateBinding(value)
  }
}

extension QueryBinding where Self == IntBinding {
  /// Creates an integer binding.
  public static func int(_ value: Int64) -> IntBinding {
    IntBinding(value)
  }
}

extension QueryBinding where Self == NullBinding {
  /// Creates a null binding.
  public static var null: NullBinding {
    NullBinding()
  }
}

extension QueryBinding where Self == TextBinding {
  /// Creates a text binding.
  public static func text(_ value: String) -> TextBinding {
    TextBinding(value)
  }
}

extension QueryBinding where Self == UUIDBinding {
  /// Creates a UUID binding.
  public static func uuid(_ value: UUID) -> UUIDBinding {
    UUIDBinding(value)
  }
}

extension QueryBinding where Self == UInt64Binding {
  /// Creates a UInt64 binding.
  public static func uint64(_ value: UInt64) -> UInt64Binding {
    UInt64Binding(value)
  }
}

extension QueryBinding where Self == InvalidBinding {
  /// Creates an invalid binding with an error.
  public static func invalid(_ error: QueryBindingError) -> InvalidBinding {
    InvalidBinding(error)
  }
  
  /// Creates an invalid binding with an error.
  @_disfavoredOverload
  public static func invalid(_ error: any Error) -> InvalidBinding {
    InvalidBinding(error)
  }
}
