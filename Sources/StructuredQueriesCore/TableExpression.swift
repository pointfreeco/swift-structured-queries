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
      let columnNames = QueryValue.TableColumns.allColumns.map(\.name)
      var columnNameCounts: [String: Int] = [:]
      for name in columnNames {
        columnNameCounts[name, default: 0] += 1
      }
      var columnNamesCount: [String: Int] = [:]
      let aliases = columnNames.map { name in
        var alias = name
        if columnNameCounts[name, default: 0] > 1 {
          let count = (columnNamesCount[name] ?? 0) + 1
          columnNamesCount[name] = count
          alias = "\(alias)_\(count)"
        }
        return alias
      }
      return zip(allColumns, aliases)
        .map { "\($0) AS \(quote: $1)" }
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
