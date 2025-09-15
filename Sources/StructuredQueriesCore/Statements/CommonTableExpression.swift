/// Creates a common table expression that can be used to factor subqueries, or create hierarchical
/// or recursive queries of trees and graphs.
public struct With<QueryValue>: Statement, Sendable {
  public typealias From = Never

  var ctes: [CommonTableExpressionClause]
  var statement: QueryFragment

  @_disfavoredOverload
  public init(
    @CommonTableExpressionBuilder _ ctes: () -> [CommonTableExpressionClause],
    query statement: () -> some Statement<QueryValue>
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
    QueryValue == (S.From, repeat each J)
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

/// Defines an alias for a common table selection that uses a selection and not a table
public struct As {
    let alias: String
    let queryFragment: QueryFragment

    public init(
        _ alias: String,
        @CommonSelectionExpressionBuilder _ queryFragment: () -> QueryFragment
    ) {
        self.alias = alias
        self.queryFragment = queryFragment()
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

  public static func buildExpression(
    _ expression: As
  ) -> CommonTableExpressionClause {
    CommonTableExpressionClause(tableName: "\(QueryFragment(quote: expression.alias))", select: expression.queryFragment)
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

/// A builder of common selection expressions.
///
/// This result builder is used by ``Add/init(_::)`` to insert one common selection with an alias
@resultBuilder
public enum CommonSelectionExpressionBuilder {
    public static func buildExpression<Selection: _Selection>(
      _ expression: some PartialSelectStatement<Selection>
    ) -> QueryFragment {
        expression.query
    }

  public static func buildBlock(
    _ component: QueryFragment
  ) -> QueryFragment {
    component
  }
}
