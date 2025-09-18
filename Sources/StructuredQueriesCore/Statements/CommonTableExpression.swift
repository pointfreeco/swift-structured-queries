/// Creates a common table expression that can be used to factor subqueries, or create hierarchical
/// or recursive queries of trees and graphs.
public struct With<Base: Statement>: Statement, Sendable {
  public typealias QueryValue = Base.QueryValue
  public typealias From = Never

  var ctes: [CommonTableExpressionClause]
  var statement: QueryFragment

  @_disfavoredOverload
  public init(
    @CommonTableExpressionBuilder _ ctes: () -> [CommonTableExpressionClause],
    query statement: () -> Base
  ) {
    self.ctes = ctes()
    self.statement = statement().query
  }

  public init<S: SelectStatement, each J: Table>(
    @CommonTableExpressionBuilder _ ctes: () -> [CommonTableExpressionClause],
    query statement: () -> S
  )
  where
    S.QueryValue == (),
    S.Joins == (repeat each J),
    Base == Select<(S.From, repeat each J), S.From, (repeat each J)>
  {
    self.ctes = ctes()
    self.statement = statement().query
  }

  @_disfavoredOverload
  public init<S: SelectStatement>(
    @CommonTableExpressionBuilder _ ctes: () -> [CommonTableExpressionClause],
    query statement: () -> S
  )
  where
    S.QueryValue == (),
    S.Joins == (),
    Base == Select<S.From, S.From, ()>
  {
    self.ctes = ctes()
    self.statement = statement().query
  }

  public var query: QueryFragment {
    guard !statement.isEmpty else { return "" }
    let cteFragments = ctes.compactMap(\.queryFragment.presence)
    guard !cteFragments.isEmpty else { return "" }
    var query: QueryFragment = "WITH "
    query.append(
      "\(cteFragments.joined(separator: ", "))\(.newlineOrSpace)\(statement)"
    )
    return query
  }
}

extension With: PartialSelectStatement where Base: PartialSelectStatement {}

extension QueryFragment {
  fileprivate var presence: Self? { isEmpty ? nil : self }
}

public struct CommonTableExpressionClause: QueryExpression, Sendable {
  public typealias QueryValue = ()
  let tableName: QueryFragment
  let select: QueryFragment
  public var queryFragment: QueryFragment {
    guard !select.isEmpty else { return "" }
    return "\(tableName) AS (\(.newline)\(select.indented())\(.newline))"
  }
}

/// A builder of common table expressions.
///
/// This result builder is used by ``With/init(_:query:)`` to insert any number of common table
/// expressions into a `WITH` statement.
@resultBuilder
public enum CommonTableExpressionBuilder {
  public static func buildExpression<CTETable: Table>(
    _ expression: some PartialSelectStatement<CTETable>
  ) -> CommonTableExpressionClause {
    CommonTableExpressionClause(tableName: "\(CTETable.self)", select: expression.query)
  }

  public static func buildBlock(
    _ component: CommonTableExpressionClause
  ) -> [CommonTableExpressionClause] {
    [component]
  }

  public static func buildPartialBlock(
    first: CommonTableExpressionClause
  ) -> [CommonTableExpressionClause] {
    [first]
  }

  public static func buildPartialBlock(
    accumulated: [CommonTableExpressionClause],
    next: CommonTableExpressionClause
  ) -> [CommonTableExpressionClause] {
    accumulated + [next]
  }
}
