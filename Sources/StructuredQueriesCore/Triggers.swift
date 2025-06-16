import Foundation
import IssueReporting

extension Table {
  /// A `CREATE TEMPORARY TRIGGER` statement.
  ///
  /// > Important: TODO: explain how implicit names are handled and how trigger helpers should always take file/line/column. and put in name/file/line/column parameters.
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

  // TODO: write tests on these below:

  public static func createTemporaryTrigger(
    _ name: String? = nil,
    ifNotExists: Bool = false,
    afterUpdateTouch updates: (inout Updates<Self>) -> Void,
    fileID: StaticString = #fileID,
    line: UInt = #line,
    column: UInt = #column
  ) -> TemporaryTrigger<Self> {
    Self.createTemporaryTrigger(
      name,
      ifNotExists: ifNotExists,
      after: .update { _, new in
        Self
          .where { $0.rowid.eq(new.rowid) }
          .update { updates(&$0) }
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
    Self.createTemporaryTrigger(
      name,
      ifNotExists: ifNotExists,
      afterUpdateTouch: {
        $0[dynamicMember: date] = SQLQueryExpression("datetime('subsec')")
      },
      fileID: fileID,
      line: line,
      column: column
    )
  }


  // TODO: createTemporaryTrigger(afterUpdateTouch: \.updatedAt)
  // TODO: createTemporaryTrigger(afterUpdate: { $0... }, touch: { $0... = })
  // TODO: createTemporaryTrigger(afterUpdate: \.self, touch: \.updatedAt)
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
    return query.segments.reduce(into: QueryFragment()) {
      switch $1 {
      case .sql(let sql):
        $0.append("\(raw: sql)")
      case .binding(let binding):
        switch binding {
        case .blob(let blob):
          reportIssue(
            """
            Cannot bind bytes to a trigger statement. To hardcode a constant BLOB, use the '#sql' \
            macro.
            """
          )
          let hex = blob.reduce(into: "") {
            let hex = String($1, radix: 16)
            if hex.count == 1 {
              $0.append("0")
            }
            $0.append(hex)
          }
          $0.append("unhex(\(quote: hex, delimiter: .text))")
        case .double(let double):
          $0.append("\(raw: double)")
        case .date(let date):
          reportIssue(
            """
            Cannot bind a date to a trigger statement. Specify dates using the '#sql' macro, \
            instead. For example, the current date:

                #sql("datetime()")

            Or a constant date:

                #sql("'2018-01-29 00:08:00'")
            """
          )
          $0.append("\(quote: date.iso8601String, delimiter: .text)")
        case .int(let int):
          $0.append("\(raw: int)")
        case .null:
          $0.append("NULL")
        case .text(let string):
          $0.append("\(quote: string, delimiter: .text)")
        case .uuid(let uuid):
          reportIssue(
            """
            Cannot bind a UUID to a trigger statement. Specify UUIDs using the '#sql' macro, \
            instead. For example, a random UUID:

                #sql("uuid()")

            Or a constant UUID:

                #sql("'00000000-0000-0000-0000-000000000000'")
            """
          )
          $0.append("\(quote: uuid.uuidString.lowercased(), delimiter: .text)")
        case .invalid(let error):
          $0.append("\(.invalid(error.underlyingError))")
        }
      }
    }
  }

  private var triggerName: QueryFragment {
    guard let name else {
      return "\(quote: "\(operation.description)_on_\(On.tableName)@\(fileID):\(line):\(column)")"
    }
    return "\(quote: name)"
  }
}
