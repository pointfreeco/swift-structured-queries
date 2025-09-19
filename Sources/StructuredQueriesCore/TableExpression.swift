public protocol TableExpression<QueryValue>: QueryExpression where QueryValue: Table {
  var allColumns: [any QueryExpression] { get }
}

extension TableExpression {
  public var queryFragment: QueryFragment {
    zip(allColumns, QueryValue.TableColumns.allColumns)
      .map { "\($0) AS \(quote: $1.name)" }
      .joined(separator: ", ")
  }
}

extension Table {
  public typealias Columns = Selection
}
