/// A conflict resolution algorithm.
public struct ConflictResolution: QueryExpression, Hashable, Sendable {
  public typealias QueryValue = Never

  /// The `ABORT` conflict resolution algorithm.
  public static let abort = Self(queryFragment: "ABORT")

  /// The `FAIL` conflict resolution algorithm.
  public static let fail = Self(queryFragment: "FAIL")

  /// The `IGNORE` conflict resolution algorithm.
  public static let ignore = Self(queryFragment: "IGNORE")

  /// The `REPLACE` conflict resolution algorithm.
  public static let replace = Self(queryFragment: "REPLACE")

  /// The `ROLLBACK` conflict resolution algorithm.
  public static let rollback = Self(queryFragment: "ROLLBACK")

  public let queryFragment: QueryFragment
}
