/// A type that builds SQL `CASE` expressions.
///
/// ```swift
/// RemindersList
///   .group(by: \.id)
///   .leftJoin(Reminder.all) { $0.id == $1.remindersListID }
///   .select {
///     (
///       $0.title,
///       Case()
///         .when(!$1.isCompleted, then: $1.title)
///         .groupConcat()
///     )
///   }
/// // SELECT
/// //   "remindersLists"."title",
/// //   group_concat(
/// //     CASE
/// //       WHEN (NOT "reminders"."isCompleted") THEN "reminders"."title"
/// //     END
/// //   )
/// // FROM "remindersLists"
/// // LEFT JOIN "reminders" ON "remindersLists"."id" = "reminders"."remindersListID"
/// // GROUP BY "remindersLists"."id"
/// ```
public struct Case<Base, QueryValue: _OptionalPromotable> {
  var base: QueryFragment?

  /// Creates a SQL `CASE` expression builder.
  ///
  /// - Parameter base: A "base" expression to test against for each `WHEN`.
  public init(
    _ base: some QueryExpression<Base>
  ) {
    self.base = base.queryFragment
  }

  /// Creates a SQL `CASE` expression builder.
  public init() where Base == Bool {}

  /// Adds a `WHEN` clause to a `CASE` expression.
  ///
  /// - Parameters:
  ///   - condition: A condition to test.
  ///   - expression: A return value should the condition pass.
  /// - Returns: A `CASE` expression builder.
  public func when(
    _ condition: some QueryExpression<Base>,
    then expression: some QueryExpression<QueryValue>
  ) -> Cases<Base, QueryValue?> {
    Cases(
      base: base,
      cases: [
        When(predicate: condition.queryFragment, expression: expression.queryFragment).queryFragment
      ]
    )
  }

  /// Adds a `WHEN` clause to a `CASE` expression.
  ///
  /// - Parameters:
  ///   - condition: A condition to test.
  ///   - expression: A return value should the condition pass.
  /// - Returns: A `CASE` expression builder.
  public func when(
    _ condition: some QueryExpression<Base>,
    then expression: some QueryExpression<QueryValue._Optionalized>
  ) -> Cases<Base, QueryValue._Optionalized> {
    Cases(
      base: base,
      cases: [
        When(predicate: condition.queryFragment, expression: expression.queryFragment).queryFragment
      ]
    )
  }
}

/// A `CASE` expression builder.
public struct Cases<Base, QueryValue: _OptionalProtocol>: QueryExpression {
  var base: QueryFragment?
  var cases: [QueryFragment]

  /// Adds a `WHEN` clause to a `CASE` expression.
  ///
  /// - Parameters:
  ///   - condition: A condition to test.
  ///   - expression: A return value should the condition pass.
  /// - Returns: A `CASE` expression builder.
  public func when(
    _ condition: some QueryExpression<Base>,
    then expression: some QueryExpression<QueryValue>
  ) -> Cases {
    var cases = self
    cases.cases.append(
      When(predicate: condition.queryFragment, expression: expression.queryFragment).queryFragment
    )
    return cases
  }

  /// Adds a `WHEN` clause to a `CASE` expression.
  ///
  /// - Parameters:
  ///   - condition: A condition to test.
  ///   - expression: A return value should the condition pass.
  /// - Returns: A `CASE` expression builder.
  public func when(
    _ condition: some QueryExpression<Base>,
    then expression: some QueryExpression<QueryValue.Wrapped>
  ) -> Cases {
    var cases = self
    cases.cases.append(
      When(predicate: condition.queryFragment, expression: expression.queryFragment).queryFragment
    )
    return cases
  }

  /// Terminates a `CASE` expression with an `ELSE` clause.
  ///
  /// - Parameter expression: A return value should every `WHEN` condition fail.
  /// - Returns: A `CASE` expression.
  public func `else`(
    _ expression: some QueryExpression<QueryValue.Wrapped>
  ) -> some QueryExpression<QueryValue.Wrapped> {
    var cases = self
    cases.cases.append("ELSE \(expression)")
    return SQLQueryExpression(cases.queryFragment)
  }

  public var queryFragment: QueryFragment {
    var query: QueryFragment = "CASE"
    if let base {
      query.append(" \(base)")
    }
    query.append(" \(cases.joined(separator: " ")) END")
    return query
  }
}

private struct When: QueryExpression {
  typealias QueryValue = Never

  let predicate: QueryFragment
  let expression: QueryFragment

  public var queryFragment: QueryFragment {
    "WHEN \(predicate) THEN \(expression)"
  }
}
