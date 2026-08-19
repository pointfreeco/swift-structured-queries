public import StructuredQueriesCore

/// A collating sequence implemented in Swift with a name and comparison function.
///
/// Values of this type can be installed in a database connection and referenced from a query. Use
/// the [`@DatabaseCollations`](<doc:CustomCollations>) macro to define them with leading dot
/// syntax:
///
/// ```swift
/// @DatabaseCollations
/// extension Collation where Self == CustomCollation {
///   static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
///     CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
///   }
/// }
///
/// db.install(.caseInsensitive)
/// Reminder.order { $0.title.collate(.caseInsensitive) }
/// ```
public struct CustomCollation: Collation, Sendable {
  /// The name of the collating sequence.
  public let name: String

  /// The function that compares two text values from the database.
  public let body: @Sendable (String, String) -> CollationOrder

  /// Initializes a collating sequence from a name and comparison function.
  ///
  /// - Parameters:
  ///   - name: The name of the collating sequence.
  ///   - body: A function that compares two text values from the database.
  public init(
    _ name: String,
    _ body: @escaping @Sendable (String, String) -> CollationOrder
  ) {
    self.name = name
    self.body = body
  }
}
