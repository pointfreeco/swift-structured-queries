extension Table {
  /// An insert statement for a table row.
  ///
  /// A convenience overload that takes a single row.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - row: A row to insert.
  ///   - doUpdate: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  /// - Returns: An insert statement.
  public static func insert(
    or conflictResolution: ConflictResolution? = nil,
    _ row: Self,
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(or: conflictResolution, [row], onConflict: doUpdate)
  }

  /// An insert statement for table rows.
  ///
  /// This function can be used to create an insert statement for a number of Swift values for a
  /// ``Table`` conformance.
  ///
  /// For example:
  ///
  /// ```swift
  /// @Table
  /// struct Tag {
  ///   var name: String
  /// }
  ///
  /// let tags = [
  ///   Tag(name: "car"),
  ///   Tag(name: "kids"),
  ///   Tag(name: "someday"),
  ///   Tag(name: "optional"),
  /// ]
  ///
  /// Tag.insert(tags)
  /// // INSERT INTO "tags" ("name")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// To create an insert statement from column values instead of a full record, see
  /// ``insert(or:_:values:onConflict:)``.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - rows: Rows to insert. An empty array will return an empty query.
  ///   - doUpdate: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  /// - Returns: An insert statement.
  public static func insert(
    or conflictResolution: ConflictResolution? = nil,
    _ rows: [Self],
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(
      or: conflictResolution,
      values: { return rows },
      onConflict: doUpdate
    )
  }

  // NB: This overload allows for the builder to work with full table records.
  @_documentation(visibility: private)
  public static func insert(
    or conflictResolution: ConflictResolution? = nil,
    _ columns: (TableColumns) -> (TableColumns) = { $0 },
    @InsertValuesBuilder<Self> values rows: () -> [Self],
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in Self.TableColumns.allColumns {
      columnNames.append(column.name)
    }
    var values: [[QueryFragment]] = []
    for row in rows() {
      var value: [QueryFragment] = []
      for column in Self.TableColumns.allColumns {
        func open<Root, Value>(_ column: some TableColumnExpression<Root, Value>) -> QueryFragment {
          Value(queryOutput: (row as! Root)[keyPath: column.keyPath]).queryFragment
        }
        value.append(open(column))
      }
      values.append(value)
    }
    return Insert(
      conflictResolution: conflictResolution,
      columnNames: columnNames,
      conflictTargetColumnNames: [],
      values: .values(values),
      updates: doUpdate.map(Updates.init),
      returning: []
    )
  }

  /// An insert statement for table values.
  ///
  /// This function can be used to create an insert statement for a specified set of columns.
  ///
  /// For example:
  ///
  /// ```swift
  /// Reminder.insert {
  ///   ($0.remindersListID, $0.title, $0.isFlagged)
  /// } values: {
  ///   (list.id, "Groceries", false)
  ///   (list.id, "Haircut", true)
  /// }
  /// // INSERT INTO "reminders" ("remindersListID", "title", "isFlagged")
  /// // VALUES (42, 'Groceries', 0), (42, 'Haircut', 1)
  /// ```
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns values to be inserted.
  ///   - rows: A builder of row values for the given columns.
  ///   - doUpdate: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  /// - Returns: An insert statement.
  public static func insert<V1: QueryBindable, each V2: QueryBindable>(
    or conflictResolution: ConflictResolution? = nil,
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1.QueryOutput, repeat (each V2).QueryOutput)>
    values rows: () -> [(V1.QueryOutput, repeat (each V2).QueryOutput)],
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    _insert(
      or: conflictResolution,
      columns,
      values: rows,
      onConflict: doUpdate
    )
  }

  private static func _insert<each Value: QueryBindable>(
    or conflictResolution: ConflictResolution? = nil,
    _ columns: (TableColumns) -> (repeat TableColumn<Self, each Value>),
    @InsertValuesBuilder<(repeat (each Value).QueryOutput)>
    values rows: () -> [(repeat (each Value).QueryOutput)],
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in repeat each columns(Self.columns) {
      columnNames.append(column.name)
    }
    var values: [[QueryFragment]] = []
    for row in rows() {
      var value: [QueryFragment] = []
      for (columnType, column) in repeat ((each Value).self, each row) {
        value.append("\(columnType.init(queryOutput: column).queryFragment)")
      }
      values.append(value)
    }
    return Insert(
      conflictResolution: conflictResolution,
      columnNames: columnNames,
      conflictTargetColumnNames: [],
      values: .values(values),
      updates: doUpdate.map(Updates.init),
      returning: []
    )
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - doUpdate: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  /// - Returns: An insert statement.
  public static func insert<
    V1: QueryBindable,
    each V2: QueryBindable,
    C1: QueryExpression<V1>,
    each C2: QueryExpression,
    From,
    Joins
  >(
    or conflictResolution: ConflictResolution? = nil,
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> Select<(C1, repeat each C2), From, Joins>,
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self>
  where (repeat (each C2).QueryValue) == (repeat each V2) {
    _insert(
      or: conflictResolution,
      columns,
      select: selection,
      onConflict: doUpdate
    )
  }

  private static func _insert<
    each Value: QueryBindable,
    each ResultColumn: QueryExpression,
    From,
    Joins
  >(
    or conflictResolution: ConflictResolution? = nil,
    _ columns: (TableColumns) -> (repeat TableColumn<Self, each Value>),
    select selection: () -> Select<(repeat each ResultColumn), From, Joins>,
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self>
  where (repeat (each ResultColumn).QueryValue) == (repeat each Value) {
    var columnNames: [String] = []
    for column in repeat each columns(Self.columns) {
      columnNames.append(column.name)
    }
    return Insert(
      conflictResolution: conflictResolution,
      columnNames: columnNames,
      conflictTargetColumnNames: [],
      values: .select(selection().query),
      updates: doUpdate.map(Updates.init),
      returning: []
    )
  }

  /// An insert statement for a table's default values.
  ///
  /// For example:
  ///
  /// ```swift
  /// Reminder.insert()
  /// // INSERT INTO "reminders" DEFAULT VALUES
  /// ```
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - doUpdate: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  /// - Returns: An insert statement.
  public static func insert(
    or conflictResolution: ConflictResolution? = nil,
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    Insert(
      conflictResolution: conflictResolution,
      columnNames: [],
      conflictTargetColumnNames: [],
      values: .default,
      updates: doUpdate.map(Updates.init),
      returning: []
    )
  }
}

extension PrimaryKeyedTable {
  /// An insert statement for a table row draft.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - row: A draft to insert.
  ///   - doUpdate: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  /// - Returns: An insert statement.
  public static func insert(
    or conflictResolution: ConflictResolution? = nil,
    _ row: Draft,
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    Self.insert(
      or: conflictResolution,
      [row],
      onConflict: doUpdate
    )
  }

  /// An insert statement for table row drafts.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - rows: Rows to insert. An empty array will return an empty query.
  ///   - doUpdate: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  /// - Returns: An insert statement.
  public static func insert(
    or conflictResolution: ConflictResolution? = nil,
    _ rows: [Draft],
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    Self.insert(
      or: conflictResolution,
      values: { return rows },
      onConflict: doUpdate
    )
  }

  // NB: This overload allows for the builder to work with full table drafts.
  @_documentation(visibility: private)
  public static func insert(
    or conflictResolution: ConflictResolution? = nil,
    _ columns: (Draft.TableColumns) -> (Draft.TableColumns) = { $0 },
    @InsertValuesBuilder<Draft>
    values rows: () -> [Draft],
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in Draft.TableColumns.allColumns {
      columnNames.append(column.name)
    }
    var values: [[QueryFragment]] = []
    for row in rows() {
      var value: [QueryFragment] = []
      for column in Draft.TableColumns.allColumns {
        func open<Root, Value>(_ column: some TableColumnExpression<Root, Value>) -> QueryFragment {
          Value(queryOutput: (row as! Root)[keyPath: column.keyPath]).queryFragment
        }
        value.append(open(column))
      }
      values.append(value)
    }
    return Insert(
      conflictResolution: conflictResolution,
      columnNames: columnNames,
      conflictTargetColumnNames: [Self.columns.primaryKey.name],
      values: .values(values),
      updates: doUpdate.map(Updates.init),
      returning: []
    )
  }
}

private enum InsertValues {
  case `default`
  case values([[QueryFragment]])
  case select(QueryFragment)
}

/// An `INSERT` statement.
///
/// This type of statement is returned from ``Table/insert(or:_:values:onConflict:)`` and related
/// functions.
///
/// To learn more, see <doc:InsertStatements>.
public struct Insert<Into: Table, Returning> {
  var conflictResolution: ConflictResolution?
  var columnNames: [String]
  var conflictTargetColumnNames: [String]
  fileprivate var values: InsertValues
  var updates: Updates<Into>?
  var returning: [QueryFragment]

  /// Adds a returning clause to an insert statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  public func returning<each QueryValue: QueryRepresentable>(
    _ selection: (From.TableColumns) -> (repeat TableColumn<From, each QueryValue>)
  ) -> Insert<Into, (repeat each QueryValue)> {
    var returning: [QueryFragment] = []
    for resultColumn in repeat each selection(From.columns) {
      returning.append("\(quote: resultColumn.name)")
    }
    return Insert<Into, (repeat each QueryValue)>(
      conflictResolution: conflictResolution,
      columnNames: columnNames,
      conflictTargetColumnNames: conflictTargetColumnNames,
      values: values,
      updates: updates,
      returning: returning
    )
  }

  // NB: This overload allows for 'returning(\.self)'.
  /// Adds a returning clause to an insert statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  @_documentation(visibility: private)
  public func returning(
    _ selection: (Into.TableColumns) -> Into.TableColumns
  ) -> Insert<Into, Into> {
    var returning: [QueryFragment] = []
    for resultColumn in From.TableColumns.allColumns {
      returning.append("\(quote: resultColumn.name)")
    }
    return Insert<Into, Into>(
      conflictResolution: conflictResolution,
      columnNames: columnNames,
      conflictTargetColumnNames: conflictTargetColumnNames,
      values: values,
      updates: updates,
      returning: returning
    )
  }
}

extension Insert: Statement {
  public typealias QueryValue = Returning
  public typealias From = Into

  public var query: QueryFragment {
    var query: QueryFragment = "INSERT"
    if let conflictResolution {
      query.append(" OR \(conflictResolution)")
    }
    query.append(" INTO \(quote: Into.tableName)")
    if let tableAlias = Into.tableAlias {
      query.append(" AS \(quote: tableAlias)")
    }
    if !columnNames.isEmpty {
      query.append(
        "\(.newlineOrSpace)(\(columnNames.map { "\(quote: $0)" }.joined(separator: ", ")))"
      )
    }
    switch values {
    case .default:
      query.append("\(.newlineOrSpace)DEFAULT VALUES")

    case let .select(select):
      query.append("\(.newlineOrSpace)\(select)")

    case .values(let values):
      guard !values.isEmpty else { return "" }
      query.append("\(.newlineOrSpace)VALUES\(.newlineOrSpace)")
      let values: [QueryFragment] = values.map {
        var value: QueryFragment = "("
        value.append($0.joined(separator: ", "))
        value.append(")")
        return value
      }
      query.append(values.joined(separator: ", "))
    }

    if let updates {
      query.append("\(.newlineOrSpace)ON CONFLICT ")
      if !conflictTargetColumnNames.isEmpty {
        query.append("(")
        query.append(conflictTargetColumnNames.map { "\(quote: $0)" }.joined(separator: ", "))
        query.append(") ")
      }
      query.append("DO ")
      query.append(updates.isEmpty ? "NOTHING" : "UPDATE \(bind: updates)")
    }
    if !returning.isEmpty {
      query.append("\(.newlineOrSpace)RETURNING \(returning.joined(separator: ", "))")
    }
    return query
  }
}

/// A convenience type alias for a non-`RETURNING ``Insert``.
public typealias InsertOf<Into: Table> = Insert<Into, ()>

/// A builder of insert statement values.
///
/// This result builder is used by ``Table/insert(or:_:values:onConflict:)`` to insert any number of
/// rows into a table.
@resultBuilder
public enum InsertValuesBuilder<Value> {
  public static func buildArray(_ components: [[Value]]) -> [Value] {
    components.flatMap(\.self)
  }

  public static func buildBlock(_ components: [Value]) -> [Value] {
    components
  }

  public static func buildEither(first component: [Value]) -> [Value] {
    component
  }

  public static func buildEither(second component: [Value]) -> [Value] {
    component
  }

  public static func buildExpression(_ expression: Value) -> [Value] {
    [expression]
  }

  public static func buildLimitedAvailability(_ component: [Value]) -> [Value] {
    component
  }

  public static func buildOptional(_ component: [Value]?) -> [Value] {
    component ?? []
  }

  public static func buildPartialBlock(first: [Value]) -> [Value] {
    first
  }

  public static func buildPartialBlock(accumulated: [Value], next: [Value]) -> [Value] {
    accumulated + next
  }
}
