extension Table {
  public static func createTemporaryTrigger<Begin: Statement>(
    _ when: TemporaryTrigger<Self, Begin>.When,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) -> TemporaryTrigger<Self, Begin> {
    TemporaryTrigger(when: when, fileID: fileID, line: line, column: column)
  }
}

// TODO: 'RAISE'
public struct TemporaryTrigger<On: Table, Begin: Statement>: Statement {
  public typealias From = Never
  public typealias Joins = ()
  public typealias QueryValue = ()

  // TODO: 'WHEN expr'?
  public enum When: QueryExpression {
    public typealias QueryValue = ()

    public enum Operation: QueryExpression {
      public typealias QueryValue = ()

      public enum Old: AliasName { public static var aliasName: String { "old" } }
      public enum New: AliasName { public static var aliasName: String { "new" } }

      case insert(@Sendable (TableAlias<On, New>.TableColumns) -> Begin)
      // TODO: 'OF column-name, …'?
      case update(
        @Sendable (TableAlias<On, Old>.TableColumns, TableAlias<On, New>.TableColumns) -> Begin
      )
      case delete(@Sendable (TableAlias<On, Old>.TableColumns) -> Begin)

      var description: String {
        switch self {
        case .insert: "insert"
        case .update: "update"
        case .delete: "delete"
        }
      }

      public var queryFragment: QueryFragment {
        var query: QueryFragment
        var begin: QueryFragment
        switch self {
        case .insert(let statement):
          query = "INSERT"
          begin = statement(On.as(New.self).columns).query
        case .update(let statement):
          query = "UPDATE"
          begin = statement(On.as(Old.self).columns, On.as(New.self).columns).query
        case .delete(let statement):
          query = "DELETE"
          begin = statement(On.as(Old.self).columns).query
        }
        query.append(" ON \(On.self)\(.newlineOrSpace)FOR EACH ROW BEGIN")
        query.append("\(.newlineOrSpace)\(begin.indented());\(.newlineOrSpace)END")
        return query
      }
    }

    case before(Operation)
    case after(Operation)
    // TODO: 'insteadOf'?

    var description: String {
      switch self {
      case .before(let operation):
        "before_\(operation.description)"
      case .after(let operation):
        "after_\(operation.description)"
      }
    }

    public var queryFragment: QueryFragment {
      switch self {
      case .before(let operation):
        "BEFORE \(operation)"
      case .after(let operation):
        "AFTER \(operation)"
      }
    }
  }

  fileprivate let when: When
  let fileID: StaticString
  let line: UInt
  let column: UInt

  public var query: QueryFragment {
    let query: QueryFragment = """
      CREATE TEMPORARY TRIGGER\(.newlineOrSpace)\(triggerName.indented())\(.newlineOrSpace)\(when)
      """
    return "\(raw: query.debugDescription)"
  }

  private var triggerName: QueryFragment {
    "\(quote: "\(when.description)_on_\(On.tableName)@\(fileID):\(line):\(column)")"
  }
}
