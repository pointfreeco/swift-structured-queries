import Foundation
import StructuredQueriesCore

/// A binding that represents a boolean value in SQLite.
///
/// SQLite stores booleans as INTEGER (0/1), so this binding
/// outputs the appropriate integer representation.
public struct BoolBinding: QueryBinding, Hashable, Sendable {
  public let value: Bool
  
  public init(_ value: Bool) {
    self.value = value
  }
  
  public var debugDescription: String {
    // SQLite stores booleans as integers
    value ? "1" : "0"
  }
}

extension QueryBinding where Self == BoolBinding {
  /// Creates a boolean binding.
  public static func bool(_ value: Bool) -> BoolBinding {
    BoolBinding(value)
  }
}

/// Bool conforms to QueryBindable in SQLite, using INTEGER storage
extension Bool: QueryBindable {
  public var queryBinding: some QueryBinding {
    BoolBinding(self)
  }
}
