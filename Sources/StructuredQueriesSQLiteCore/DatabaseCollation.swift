public import StructuredQueriesCore

/// A type representing a collating sequence that is implemented in Swift and installed in a
/// database.
///
/// Don't conform to this protocol directly. Instead, use the
/// [`@DatabaseCollation`](<doc:CustomCollations>) macro to generate a conformance.
public protocol DatabaseCollation: Collation {
  /// Compares two text values from the database.
  ///
  /// - Parameters:
  ///   - lhs: The first value.
  ///   - rhs: The second value.
  /// - Returns: The ordering of the first value relative to the second.
  func compare(_ lhs: String, _ rhs: String) throws -> CollationOrder
}

/// An error thrown when a database collation's owning object has been deallocated.
///
/// This is used internally by `@DatabaseCollation` when applied to class instance methods to break
/// retain cycles.
public struct _DatabaseCollationDeallocated: Error, Sendable {
  public init() {}
}
