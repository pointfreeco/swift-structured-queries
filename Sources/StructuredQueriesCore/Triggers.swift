import Foundation

extension Table {
  /// A `CREATE TEMPORARY TRIGGER` statement.
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
  public static func createTemporaryTrigger(
    _ name: String? = nil,
    ifNotExists: Bool = false,
    after operation: TemporaryTrigger<Self>.Operation,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) -> TemporaryTrigger<Self> {
    TemporaryTrigger(
      name: name,
      ifNotExists: ifNotExists,
      operation: operation,
      fileID: fileID,
      line: line,
      column: column
    )
  }

  public static func createTemporaryTrigger(
    _ name: String? = nil,
    ifNotExists: Bool = false,
    afterUpdateTouch updates: (inout Updates<Self>) -> Void,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) -> TemporaryTrigger<Self> {
    TemporaryTrigger(
      name: name,
      ifNotExists: ifNotExists,
      operation: .update { _, _ in
        Self.update { updates(&$0) }
      },
      fileID: fileID,
      line: line,
      column: column
    )
  }

  // TODO: Touchable protocol with Date: Touchable, UUID: Touchable, ?
  public static func createTemporaryTrigger(
    _ name: String? = nil,
    ifNotExists: Bool = false,
    afterUpdateTouch date: KeyPath<TableColumns, TableColumn<Self, Date>>,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) -> TemporaryTrigger<Self> {
    TemporaryTrigger(
      name: name,
      ifNotExists: ifNotExists,
      operation: .update { _, _ in
        Self.update {
          $0[dynamicMember: date] = SQLQueryExpression("datetime('subsec')")
        }
      },
      fileID: fileID,
      line: line,
      column: column
    )
  }

  // TODO: createTemporaryTrigge(afterUpdate: { $0... }, touch: { $0... = })
  // TODO: createTemporaryTrigge(afterUpdate: \.self, touch: \.updatedAt)
}

public struct TemporaryTrigger<On: Table>: Statement {
  public typealias From = Never
  public typealias Joins = ()
  public typealias QueryValue = ()

  public struct Operation: QueryExpression {
    public typealias QueryValue = ()

    public enum _Old: AliasName { public static var aliasName: String { "old" } }
    public enum _New: AliasName { public static var aliasName: String { "new" } }

    public typealias Old = TableAlias<On, _Old>.TableColumns
    public typealias New = TableAlias<On, _New>.TableColumns
    
    /// An `AFTER INSERT` trigger operation.
    ///
    /// - Parameters:
    ///   - perform: A statement to perform for each triggered row.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `AFTER INSERT` trigger operation.
    public static func insert(
      forEachRow perform: (New) -> some Statement,
      when condition: ((New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self(
        kind: .insert(operation: perform(On.as(_New.self).columns).query),
        when: condition?(On.as(_New.self).columns).queryFragment
      )
    }

    /// An `AFTER UPDATE` trigger operation.
    ///
    /// - Parameters:
    ///   - perform: A statement to perform for each triggered row.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `AFTER UPDATE` trigger operation.
    public static func update(
      forEachRow perform: (Old, New) -> some Statement,
      when condition: ((Old, New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      update(
        of: { _ in },
        forEachRow: perform,
        when: condition
      )
    }

    /// An `AFTER UPDATE` trigger operation.
    ///
    /// - Parameters:
    ///   - columns: Updated columns to scope the operation to.
    ///   - perform: A statement to perform for each triggered row.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `AFTER UPDATE` trigger operation.
    public static func update<each Column>(
      of columns: (On.TableColumns) -> (repeat TableColumn<On, each Column>),
      forEachRow perform: (Old, New) -> some Statement,
      when condition: ((Old, New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      var columnNames: [String] = []
      for column in repeat each columns(On.columns) {
        columnNames.append(column.name)
      }
      return Self(
        kind: .update(
          operation: perform(On.as(_Old.self).columns, On.as(_New.self).columns).query,
          columnNames: columnNames
        ),
        when: condition?(On.as(_Old.self).columns, On.as(_New.self).columns).queryFragment
      )
    }

    /// An `AFTER DELETE` trigger operation.
    ///
    /// - Parameters:
    ///   - perform: A statement to perform for each triggered row.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `AFTER DELETE` trigger operation.
    public static func delete(
      forEachRow perform: (Old) -> some Statement,
      when condition: ((Old) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self(
        kind: .delete(operation: perform(On.as(_Old.self).columns).query),
        when: condition?(On.as(_Old.self).columns).queryFragment
      )
    }

    private enum Kind {
      case insert(operation: QueryFragment)
      case update(operation: QueryFragment, columnNames: [String])
      case delete(operation: QueryFragment)
    }

    private let kind: Kind
    private let when: QueryFragment?

    public var queryFragment: QueryFragment {
      var query: QueryFragment = "AFTER"
      let statement: QueryFragment
      switch kind {
      case .insert(let begin):
        query.append(" INSERT")
        statement = begin
      case .update(let begin, let columnNames):
        query.append(" UPDATE")
        if !columnNames.isEmpty {
          query.append(
            " OF \(columnNames.map { QueryFragment(quote: $0) }.joined(separator: ", "))"
          )
        }
        statement = begin
      case .delete(let begin):
        query.append(" DELETE")
        statement = begin
      }
      query.append(" ON \(On.self)\(.newlineOrSpace)FOR EACH ROW")
      if let when {
        query.append(" WHEN \(when)")
      }
      query.append(" BEGIN")
      query.append("\(.newlineOrSpace)\(statement.indented());\(.newlineOrSpace)END")
      return query
    }

    fileprivate var description: String {
      switch kind {
      case .insert: "after_insert"
      case .update: "after_update"
      case .delete: "after_delete"
      }
    }
  }

  fileprivate let name: String?
  fileprivate let ifNotExists: Bool
  fileprivate let operation: Operation
  fileprivate let fileID: StaticString
  fileprivate let line: UInt
  fileprivate let column: UInt

  /// Returns a `DROP TRIGGER` statement for this trigger.
  ///
  /// - Parameter ifExists: Adds an `IF EXISTS` condition to the `DROP TRIGGER`.
  /// - Returns: A `DROP TRIGGER` statement for this trigger.
  public func drop(ifExists: Bool = false) -> some Statement {
    var query: QueryFragment = "DROP TRIGGER"
    if ifExists {
      query.append(" IF EXISTS")
    }
    query.append(" \(triggerName)")
    return SQLQueryExpression(query)
  }

  public var query: QueryFragment {
    var query: QueryFragment = "CREATE TEMPORARY TRIGGER"
    if ifNotExists {
      query.append(" IF NOT EXISTS")
    }
    query.append("\(.newlineOrSpace)\(triggerName.indented())\(.newlineOrSpace)\(operation)")
    return "\(raw: query.debugDescription)"
  }

  private var triggerName: QueryFragment {
    guard let name else {
      return "\(quote: "\(operation.description)_on_\(On.tableName)@\(fileID):\(line):\(column)")"
    }
    return "\(quote: name)"
  }
}
