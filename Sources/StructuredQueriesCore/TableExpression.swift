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

  public static var _columnWidth: Int {
    QueryValue._columnWidth
  }

  public var _allColumns: [any QueryExpression] {
    allColumns
  }
}

extension Table {
  public typealias Columns = Selection
}
