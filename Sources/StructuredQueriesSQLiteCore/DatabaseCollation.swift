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
  ///   - lhs: The UTF-8 bytes of the first value. Only valid for the duration of the call.
  ///   - rhs: The UTF-8 bytes of the second value. Only valid for the duration of the call.
  /// - Returns: The ordering of the first value relative to the second.
  func compare(_ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer) -> CollationOrder
}
