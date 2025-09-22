public protocol TableExpression<QueryValue>: QueryExpression where QueryValue: Table {
  var allColumns: [any QueryExpression] { get }
}

extension TableExpression {
  public var queryFragment: QueryFragment {
    precondition(
      allColumns.count == QueryValue.TableColumns.allColumns.count,
      "Number of selected columns does not match number of table columns"
    )
    return zip(allColumns, QueryValue.TableColumns.allColumns)
      .map { "\($0) AS \(quote: $1.name)" }
      .joined(separator: ", ")
  }
}

extension Table {
  public typealias Columns = Selection
}

extension QueryExpression {
  public var _allColumns: [any QueryExpression] {
    [self]
  }
}

extension QueryExpression where QueryValue: _OptionalProtocol, QueryValue.Wrapped: Table {
  public var _allColumns: [any QueryExpression] {
    guard let queryValue = self as? QueryValue else {
      return [self]
    }
    return queryValue._wrapped?._allColumns
      ?? Array(
        repeating: SQLQueryExpression("NULL") as any QueryExpression,
        count: QueryValue.Wrapped.TableColumns.allColumns.count
      )
  }
}
