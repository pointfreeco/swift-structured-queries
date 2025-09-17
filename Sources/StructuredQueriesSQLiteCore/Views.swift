extension Table where Self: _Selection {
  /// A `CREATE TEMPORARY VIEW` statement that executes after a database event.
  ///
  /// See <doc:Triggers> for more information.
  ///
  /// > Important: A name for the trigger is automatically derived from the arguments if one is not
  /// > provided. If you build your own trigger helper that call this function, then your helper
  /// > should also take `fileID`, `line` and `column` arguments and pass them to this function.
  ///
  /// - Parameters:
  ///   - name: The trigger's name. By default a unique name is generated depending using the table,
  ///     operation, and source location.
  ///   - ifNotExists: Adds an `IF NOT EXISTS` clause to the `CREATE TRIGGER` statement.
  ///   - operation: The trigger's operation.
  ///   - fileID: The source `#fileID` associated with the trigger.
  ///   - line: The source `#line` associated with the trigger.
  ///   - column: The source `#column` associated with the trigger.
  /// - Returns: A temporary trigger.
  public static func createTemporaryView<Selection: SelectStatement>(
    ifNotExists: Bool = false,
    select: () -> Selection
  ) -> DatabaseView<Self, Selection>
  where Selection.QueryValue == Columns.QueryValue {
    DatabaseView(ifNotExists: ifNotExists, select: select())
  }
}

public struct DatabaseView<View: Table & _Selection, Selection: SelectStatement>: Statement
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
    return query
  }
}
