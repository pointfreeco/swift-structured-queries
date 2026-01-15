/// A collating sequence name.
///
/// Values of this type are supplied to ``QueryExpression/collate(_:)`` to describe how a string
/// should be compared in a query.
public struct Collation: QueryExpression, Sendable {
  public typealias QueryValue = Never

  /// Initializes a collating sequence name from a query fragment.
  ///
  /// ```swift
  /// extension Collation {
  ///   static let fr_FR = Self(rawValue: "fr_FR")
  /// }
  ///
  /// Reminder.order { $0.title.collate(.fr_FR) }
  /// // SELECT … FROM "reminders"
  /// // ORDER BY "reminders"."title" COLLATE "fr_FR"
  /// ```
  ///
  /// - Parameter rawValue: A query fragment of the sequence name.
  public init(rawValue: String) {
    self.queryFragment = "\(quote: rawValue)"
  }

  public let queryFragment: QueryFragment
}
