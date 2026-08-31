/// A type representing a collating sequence.
///
/// Values of this type are supplied to `collate(_:)` to describe how text should be compared in a
/// query.
///
/// Collating sequences that are already known to the database can be described using
/// ``NamedCollation``:
///
/// ```swift
/// extension Collation where Self == NamedCollation {
///   static var fr_FR: Self { Self("fr_FR") }
/// }
///
/// Reminder.order { $0.title.collate(.fr_FR) }
/// // SELECT … FROM "reminders"
/// // ORDER BY "reminders"."title" COLLATE "fr_FR"
/// ```
///
/// Collating sequences implemented in Swift can be defined using the `@DatabaseCollation` macro,
/// which generates a conformance to this protocol.
public protocol Collation: QueryExpression<Never> {
  /// The name of the collating sequence.
  var name: String { get }
}

extension Collation {
  public var queryFragment: QueryFragment {
    "\(quote: name)"
  }
}

/// A collating sequence that is referenced by name.
///
/// Use this type to describe collating sequences that are already known to the database, either
/// built into it or registered with it by some other means:
///
/// ```swift
/// extension Collation where Self == NamedCollation {
///   static var fr_FR: Self { Self("fr_FR") }
/// }
/// ```
public struct NamedCollation: Collation, Sendable {
  public let name: String

  /// Initializes a collating sequence from its name.
  ///
  /// - Parameter name: The name of the collating sequence.
  public init(_ name: String) {
    self.name = name
  }

  /// Initializes a collating sequence from the name of another collating sequence.
  ///
  /// Useful for giving a collating sequence defined in Swift leading dot syntax:
  ///
  /// ```swift
  /// @DatabaseCollation
  /// func localized(_ lhs: String, _ rhs: String) -> CollationOrder {
  ///   CollationOrder(lhs.localizedCompare(rhs))
  /// }
  ///
  /// extension Collation where Self == NamedCollation {
  ///   static var localized: Self { Self($localized) }
  /// }
  ///
  /// Reminder.order { $0.title.collate(.localized) }
  /// ```
  ///
  /// - Parameter collation: A collating sequence.
  public init(_ collation: some Collation) {
    self.name = collation.name
  }
}

extension QueryExpression where QueryValue: _OptionalPromotable<String?> {
  /// Returns an expression of this expression that is compared using the given collating sequence.
  ///
  /// ```swift
  /// Reminder.order { $0.title.collate(.nocase) }
  /// // SELECT … FROM "reminders"
  /// // ORDER BY "reminders"."title" COLLATE "NOCASE"
  /// ```
  ///
  /// - Parameter collation: A collating sequence.
  /// - Returns: An expression that is compared using the given collating sequence.
  public func collate(_ collation: some Collation) -> some QueryExpression<QueryValue> {
    SQLQueryExpression("\(self) COLLATE \(collation)")
  }
}

/// The relative ordering of two values compared by a collating sequence.
public enum CollationOrder: Hashable, Sendable {
  /// The first value is ordered before the second value.
  case ascending

  /// The two values are ordered the same.
  case same

  /// The first value is ordered after the second value.
  case descending

  /// Initializes an order from two comparable values.
  ///
  /// - Parameters:
  ///   - lhs: The first value.
  ///   - rhs: The second value.
  public init<T: Comparable>(_ lhs: T, _ rhs: T) {
    self = lhs < rhs ? .ascending : rhs < lhs ? .descending : .same
  }
}
