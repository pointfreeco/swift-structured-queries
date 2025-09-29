/// An expression of table columns.
///
/// Don't conform to this protocol directly. Instead, use the `@Table` and `@Selection` macros to
/// generate a conformance.
public protocol TableExpression<QueryValue>: QueryExpression where QueryValue: Table {
  var allColumns: [any QueryExpression] { get }
}

extension TableExpression {
  public var queryFragment: QueryFragment {
    if _isSelecting {
      return zip(allColumns, QueryValue.TableColumns.allColumns)
        .map { "\($0) AS \(quote: $1.name)" }
        .joined(separator: ", ")
    } else {
      return allColumns.map(\.queryFragment).joined(separator: ", ")
    }
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
