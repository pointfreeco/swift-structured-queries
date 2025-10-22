extension Table {
  /// A `CREATE TEMPORARY VIEW` statement.
  ///
  /// See <doc:Views> for more information.
  ///
  /// - Parameters:
  ///   - ifNotExists: Adds an `IF NOT EXISTS` clause to the `CREATE VIEW` statement.
  ///   - select: A statement describing the contents of the view.
  /// - Returns: A temporary trigger.
  public static func createTemporaryView<Selection: PartialSelectStatement>(
    ifNotExists: Bool = false,
    as select: Selection
  ) -> TemporaryView<Self, Selection>
  where Selection.QueryValue == Columns.QueryValue {
    TemporaryView(ifNotExists: ifNotExists, select: select)
  }
}

/// A `CREATE TEMPORARY VIEW` statement.
///
/// This type of statement is returned from ``Table/createTemporaryView(ifNotExists:as:)``.
///
/// To learn more, see <doc:Views>.
public struct TemporaryView<View: Table, Selection: PartialSelectStatement>: Statement
where Selection.QueryValue == View {
  public typealias QueryValue = ()
  public typealias From = Never

  fileprivate let ifNotExists: Bool
  fileprivate let select: Selection

  /// Returns a `DROP VIEW` statement for this trigger.
  ///
  /// - Parameter ifExists: Adds an `IF EXISTS` condition to the `DROP VIEW`.
  /// - Returns: A `DROP VIEW` statement for this trigger.
  public func drop(ifExists: Bool = false) -> some Statement<()> {
    var query: QueryFragment = "DROP VIEW"
    if ifExists {
      query.append(" IF EXISTS")
    }
    query.append(" ")
    if let schemaName = View.schemaName {
      query.append("\(quote: schemaName).")
    }
    query.append(View.tableFragment)
    return SQLQueryExpression(query)
  }

  public var query: QueryFragment {
    var query: QueryFragment = "CREATE TEMPORARY VIEW"
    if ifNotExists {
      query.append(" IF NOT EXISTS")
    }
    query.append(.newlineOrSpace)
    if let schemaName = View.schemaName {
      query.append("\(quote: schemaName).")
    }
    query.append(View.tableFragment)
    let columnNames: [QueryFragment] = View.TableColumns.allColumns
      .map { "\(quote: $0.name)" }
    query.append("\(.newlineOrSpace)(\(columnNames.joined(separator: ", ")))")
    query.append("\(.newlineOrSpace)AS")
    query.append("\(.newlineOrSpace)\(select)")
    return query.compiled(statementType: "CREATE TEMPORARY VIEW")
  }
}
