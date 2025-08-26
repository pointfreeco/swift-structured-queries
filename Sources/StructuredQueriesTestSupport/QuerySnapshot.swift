import SnapshotTesting
import StructuredQueriesCore
import Testing

extension Snapshotting where Value: Statement {
  /// A snapshot strategy for comparing a query based on its SQL output.
  ///
  /// ```swift
  /// assertInlineSnapshot(
  ///   of: Reminder.select(\.title),
  ///   as: .sql
  /// ) {
  ///   """
  ///   SELECT "reminders"."title" FROM "reminders"
  ///   """
  /// }
  /// ```
  public static var sql: Snapshotting<Value, String> {
    SimplySnapshotting.lines.pullback(\.query.debugDescription)
  }
}

extension Snapshotting where Value: QueryExpression {
  /// A snapshot strategy for comparing a query based on its SQL output.
  ///
  /// ```swift
  /// assertInlineSnapshot(
  ///   of: Reminder.select(\.title),
  ///   as: .sql
  /// ) {
  ///   """
  ///   SELECT "reminders"."title" FROM "reminders"
  ///   """
  /// }
  public static var sql: Snapshotting<Value, String> {
    SimplySnapshotting.lines.pullback(\.queryFragment.debugDescription)
  }
}
