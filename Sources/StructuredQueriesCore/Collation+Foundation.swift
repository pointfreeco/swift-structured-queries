public import Foundation

extension CollationOrder {
  /// Initializes an order from a Foundation comparison result.
  ///
  /// Useful for collating sequences that delegate to Foundation's comparison APIs:
  ///
  /// ```swift
  /// @DatabaseCollation
  /// func localized(_ lhs: String, _ rhs: String) -> CollationOrder {
  ///   CollationOrder(lhs.localizedCompare(rhs))
  /// }
  /// ```
  ///
  /// - Parameter comparisonResult: A comparison result.
  public init(_ comparisonResult: ComparisonResult) {
    switch comparisonResult {
    case .orderedAscending: self = .ascending
    case .orderedDescending: self = .descending
    default: self = .same
    }
  }
}
