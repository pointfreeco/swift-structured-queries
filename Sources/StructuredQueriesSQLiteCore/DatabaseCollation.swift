import IssueReporting
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
  func compare(_ lhs: String, _ rhs: String) -> CollationOrder
}
