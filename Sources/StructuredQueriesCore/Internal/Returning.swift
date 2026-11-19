extension Table {
  /// Renders the result columns of a `RETURNING` clause for a statement that modifies this table.
  package static func _returning<each ResultColumn: QueryExpression>(
    _ selection: (TableColumns) -> (repeat each ResultColumn)
  ) -> [QueryFragment] {
    $_isSelecting.withValue(true) {
      var returning: [QueryFragment] = []
      for resultColumn in repeat each selection(columns) {
        returning.append(resultColumn.returningFragment(from: Self.self))
      }
      return returning
    }
  }
}

extension QueryExpression {
  fileprivate func returningFragment<From: Table>(from table: From.Type) -> QueryFragment {
    func open<Root, Value>(_ column: some TableColumnExpression<Root, Value>) -> QueryFragment? {
      Root.self == From.self ? column.returningFragment : nil
    }
    var columns: [QueryFragment] = []
    for column in _allColumns {
      guard
        let column = column as? any TableColumnExpression,
        let column = open(column)
      else {
        return queryFragment.returning(from: From.self)
      }
      columns.append(column)
    }
    guard !columns.isEmpty
    else { return queryFragment.returning(from: From.self) }
    return columns.joined(separator: ", ")
  }
}

extension QueryFragment {
  fileprivate func returning<From: Table>(from table: From.Type) -> QueryFragment {
    let schemaQualifier = From.schemaName.map { "\($0.quoted())." }
    guard From.tableAlias != nil || schemaQualifier != nil
    else { return self }
    var query = self
    let key = ObjectIdentifier(From.self)
    for index in query.segments.indices {
      guard
        case .identifier(var identifier) = query.segments[index],
        identifier.key == key
      else { continue }
      identifier.name = From.tableName
      query.segments[index] = .identifier(identifier)
      if let schemaQualifier,
        index > query.segments.startIndex,
        case .sql(let sql) = query.segments[index - 1],
        sql.hasSuffix(schemaQualifier)
      {
        query.segments[index - 1] = .sql(String(sql.dropLast(schemaQualifier.count)))
      }
    }
    return query
  }
}
