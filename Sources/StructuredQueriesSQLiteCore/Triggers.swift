import Foundation

extension Table {
  /// A `CREATE TEMPORARY TRIGGER` statement that executes after a database event.
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
      when: .after,
      fileID: fileID,
      line: line,
      column: column
    )
  }

  /// A `CREATE TEMPORARY TRIGGER` statement that executes before a database event.
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
  public static func createTemporaryTrigger(
    _ name: String? = nil,
    ifNotExists: Bool = false,
    before operation: TemporaryTrigger<Self>.Operation,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) -> TemporaryTrigger<Self> {
    TemporaryTrigger(
      name: name,
      ifNotExists: ifNotExists,
      operation: operation,
      when: .before,
      fileID: fileID,
      line: line,
      column: column
    )
  }

  /// A `CREATE TEMPORARY TRIGGER` statement that executes instead of a database view event.
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
  public static func createTemporaryTrigger(
    _ name: String? = nil,
    ifNotExists: Bool = false,
    insteadOf operation: TemporaryTrigger<Self>.Operation,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) -> TemporaryTrigger<Self> {
    TemporaryTrigger(
      name: name,
      ifNotExists: ifNotExists,
      operation: operation,
      when: .insteadOf,
      fileID: fileID,
      line: line,
      column: column
    )
  }
}

/// A `CREATE TEMPORARY TRIGGER` statement.
///
/// This type of statement is returned from the
/// `[Table.createTemporaryTrigger]<doc:Table/createTemporaryTrigger(_:ifNotExists:after:fileID:line:column:)>`
/// family of functions.
///
/// To learn more, see <doc:Triggers>.
public struct TemporaryTrigger<On: Table>: Sendable, Statement {
  public typealias From = Never
  public typealias Joins = ()
  public typealias QueryValue = ()

  fileprivate enum When: QueryFragment {
    case before = "BEFORE"
    case after = "AFTER"
    case insteadOf = "INSTEAD OF"
  }

  /// The database event used in a trigger.
  ///
  /// To learn more, see <doc:Triggers>.
  public struct Operation: Sendable, QueryExpression {
    public typealias QueryValue = ()

    public enum _Old: AliasName { public static var aliasName: String { "old" } }
    public enum _New: AliasName { public static var aliasName: String { "new" } }

    public typealias Old = TableAlias<On, _Old>.TableColumns
    public typealias New = TableAlias<On, _New>.TableColumns

    /// An `INSERT` trigger operation.
    ///
    /// - Parameters:
    ///   - perform: A statement to perform for each triggered row.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `INSERT` trigger operation.
    public static func insert(
      @QueryFragmentBuilder<any Statement>
      forEachRow perform: (_ new: New) -> [QueryFragment],
      when condition: ((_ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self(
        kind: .insert(operations: perform(On.as(_New.self).columns)),
        when: condition?(On.as(_New.self).columns).queryFragment
      )
    }

    /// An `INSERT` trigger operation that applies additional updates to the associated rows.
    ///
    /// - Parameters:
    ///   - updates: The updates to apply to associated rows.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `INSERT` trigger operation.
    @_disfavoredOverload
    public static func insert(
      touch updates: (inout Updates<On>) -> Void,
      when condition: ((_ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self.insert(
        forEachRow: { new in
          On
            .where { $0.rowid.eq(new.rowid) }
            .update { updates(&$0) }
        },
        when: condition
      )
    }

    /// An `INSERT` trigger operation that updates a datetime column for the associated rows.
    ///
    /// - Parameters:
    ///   - dateColumn: A key path to a datetime column.
    ///   - dateFunction: A database function that returns the current datetime, _e.g._,
    ///     `#sql("datetime('subsec'))"`.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `INSERT` trigger operation.
    @_disfavoredOverload
    public static func insert<D: _OptionalPromotable<Date?>>(
      touch dateColumn: KeyPath<On.TableColumns, TableColumn<On, D>>,
      date dateFunction: any QueryExpression<D> = SQLQueryExpression<D>("datetime('subsec')"),
      when condition: ((_ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self.insert(
        touch: { $0[dynamicMember: dateColumn] = dateFunction },
        when: condition
      )
    }

    /// An `UPDATE` trigger operation.
    ///
    /// - Parameters:
    ///   - perform: A statement to perform for each triggered row.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `UPDATE` trigger operation.
    public static func update(
      @QueryFragmentBuilder<any Statement>
      forEachRow perform: (_ old: Old, _ new: New) -> [QueryFragment],
      when condition: ((_ old: Old, _ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      update(
        of: { _ in },
        forEachRow: perform,
        when: condition
      )
    }

    /// An `UPDATE` trigger operation.
    ///
    /// - Parameters:
    ///   - columns: Updated columns to scope the operation to.
    ///   - perform: A statement to perform for each triggered row.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `UPDATE` trigger operation.
    public static func update<each Column: _TableColumnExpression>(
      of columns: (On.TableColumns) -> (repeat each Column),
      @QueryFragmentBuilder<any Statement>
      forEachRow perform: (_ old: Old, _ new: New) -> [QueryFragment],
      when condition: ((_ old: Old, _ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      var columnNames: [String] = []
      for column in repeat each columns(On.columns) {
        columnNames.append(contentsOf: column._names)
      }
      return Self(
        kind: .update(
          operations: perform(On.as(_Old.self).columns, On.as(_New.self).columns),
          columnNames: columnNames
        ),
        when: condition?(On.as(_Old.self).columns, On.as(_New.self).columns).queryFragment
      )
    }

    /// An `UPDATE` trigger operation that applies additional updates to the associated rows.
    ///
    /// - Parameters:
    ///   - updates: The updates to apply to associated rows.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `UPDATE` trigger operation.
    @_disfavoredOverload
    public static func update(
      touch updates: (inout Updates<On>) -> Void,
      when condition: ((_ old: Old, _ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self.update(
        forEachRow: { _, new in
          On
            .where { $0.rowid.eq(new.rowid) }
            .update { updates(&$0) }
        },
        when: condition
      )
    }

    /// An `UPDATE` trigger operation that updates a datetime column for the associated rows.
    ///
    /// - Parameters:
    ///   - dateColumn: A key path to a datetime column.
    ///   - dateFunction: A database function that returns the current datetime, _e.g._,
    ///     `#sql("datetime('subsec'))"`.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `UPDATE` trigger operation.
    @_disfavoredOverload
    public static func update<D: _OptionalPromotable<Date?>>(
      touch dateColumn: KeyPath<On.TableColumns, TableColumn<On, D>>,
      date dateFunction: any QueryExpression<D> = SQLQueryExpression<D>("datetime('subsec')"),
      when condition: ((_ old: Old, _ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self.update(
        touch: { $0[dynamicMember: dateColumn] = dateFunction },
        when: condition
      )
    }

    /// An `UPDATE` trigger operation that applies additional updates to the associated rows.
    ///
    /// - Parameters:
    ///   - columns: Updated columns to scope the operation to.
    ///   - updates: The updates to apply to associated rows.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `UPDATE` trigger operation.
    @_disfavoredOverload
    public static func update<each Column: _TableColumnExpression>(
      of columns: (On.TableColumns) -> (repeat each Column),
      touch updates: (inout Updates<On>) -> Void,
      when condition: ((_ old: Old, _ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self.update(
        of: columns,
        forEachRow: { _, new in
          On
            .where { $0.rowid.eq(new.rowid) }
            .update { updates(&$0) }
        },
        when: condition
      )
    }

    /// An `UPDATE` trigger operation that updates a datetime column for the associated rows.
    ///
    /// - Parameters:
    ///   - columns: Updated columns to scope the operation to.
    ///   - dateColumn: A key path to a datetime column.
    ///   - dateFunction: A database function that returns the current datetime, _e.g._,
    ///     `#sql("datetime('subsec'))"`.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: An `UPDATE` trigger operation.
    @_disfavoredOverload
    public static func update<each Column: _TableColumnExpression, D: _OptionalPromotable<Date?>>(
      of columns: (On.TableColumns) -> (repeat each Column),
      touch dateColumn: KeyPath<On.TableColumns, TableColumn<On, D>>,
      date dateFunction: any QueryExpression<D> = SQLQueryExpression<D>("datetime('subsec')"),
      when condition: ((_ old: Old, _ new: New) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self.update(
        of: columns,
        touch: { $0[dynamicMember: dateColumn] = dateFunction },
        when: condition
      )
    }

    /// A `DELETE` trigger operation.
    ///
    /// - Parameters:
    ///   - perform: A statement to perform for each triggered row.
    ///   - condition: A predicate that must be satisfied to perform the given statement.
    /// - Returns: A `DELETE` trigger operation.
    public static func delete(
      @QueryFragmentBuilder<any Statement>
      forEachRow perform: (_ old: Old) -> [QueryFragment],
      when condition: ((_ old: Old) -> any QueryExpression<Bool>)? = nil
    ) -> Self {
      Self(
        kind: .delete(operations: perform(On.as(_Old.self).columns)),
        when: condition?(On.as(_Old.self).columns).queryFragment
      )
    }

    private enum Kind {
      case insert(operations: [QueryFragment])
      case update(operations: [QueryFragment], columnNames: [String])
      case delete(operations: [QueryFragment])
    }

    private let kind: Kind
    private let when: QueryFragment?

    public var queryFragment: QueryFragment {
      var query: QueryFragment = ""
      let statements: [QueryFragment]
      switch kind {
      case .insert(let begin):
        query.append("INSERT")
        statements = begin
      case .update(let begin, let columnNames):
        query.append("UPDATE")
        if !columnNames.isEmpty {
          query.append(
            " OF \(columnNames.map { QueryFragment(quote: $0) }.joined(separator: ", "))"
          )
        }
        statements = begin
      case .delete(let begin):
        query.append("DELETE")
        statements = begin
      }
      query.append(" ON \(On.self)\(.newlineOrSpace)FOR EACH ROW")
      if let when {
        query.append(" WHEN \(when)")
      }
      query.append(" BEGIN")
      for statement in statements {
        query.append("\(.newlineOrSpace)\(statement.indented());")
      }
      query.append("\(.newlineOrSpace)END")
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
  fileprivate let when: When
  fileprivate let fileID: StaticString
  fileprivate let line: UInt
  fileprivate let column: UInt

  /// Returns a `DROP TRIGGER` statement for this trigger.
  ///
  /// - Parameter ifExists: Adds an `IF EXISTS` condition to the `DROP TRIGGER`.
  /// - Returns: A `DROP TRIGGER` statement for this trigger.
  public func drop(ifExists: Bool = false) -> some Statement<()> {
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
    query.append("\(.newlineOrSpace)\(triggerName.indented())")
    query.append("\(.newlineOrSpace)\(when.rawValue) \(operation)")
    return query.compiled(statementType: "CREATE TEMPORARY TRIGGER")
  }

  private var triggerName: QueryFragment {
    guard let name else {
      return "\(quote: "\(operation.description)_on_\(On.tableName)@\(fileID):\(line):\(column)")"
    }
    return "\(quote: name)"
  }
}
