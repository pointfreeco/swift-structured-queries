import IssueReporting

extension Table {
  /// Columns referencing the value that would have been inserted in an
  /// [insert statement](<doc:InsertStatements>) had there been no conflict.
  public typealias Excluded = TableAlias<Self, _ExcludedName>.TableColumns

  /// An insert statement for one or more table rows.
  ///
  /// This function can be used to create an insert statement from a ``Table`` value.
  ///
  /// ```swift
  /// let tag = Tag(title: "car")
  /// Tag.insert { tag }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car')
  /// ```
  ///
  /// It can also be used to insert multiple rows in a single statement.
  ///
  /// ```swift
  /// let tags = [
  ///   Tag(title: "car"),
  ///   Tag(title: "kids"),
  ///   Tag(title: "someday"),
  ///   Tag(title: "optional")
  /// ]
  /// Tag.insert { tags }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// The `values` trailing closure is a result builder that will insert any number of expressions,
  /// one after the other, and supports basic control flow statements.
  ///
  /// ```swift
  /// Tag.insert {
  ///   if vehicleOwner {
  ///     Tag(name: "car")
  ///   }
  ///   Tag(name: "kids")
  ///   Tag(name: "someday")
  ///   Tag(name: "optional")
  /// }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// - Parameters:
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    _insert(
      columnNames: TableColumns.writableColumns.map(\.name),
      values: .values(values()),
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for one or more table rows.
  ///
  /// This function can be used to create an insert statement from a ``Table`` value.
  ///
  /// ```swift
  /// let tag = Tag(title: "car")
  /// Tag.insert { tag }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car')
  /// ```
  ///
  /// It can also be used to insert multiple rows in a single statement.
  ///
  /// ```swift
  /// let tags = [
  ///   Tag(title: "car"),
  ///   Tag(title: "kids"),
  ///   Tag(title: "someday"),
  ///   Tag(title: "optional")
  /// ]
  /// Tag.insert { tags }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// The `values` trailing closure is a result builder that will insert any number of expressions,
  /// one after the other, and supports basic control flow statements.
  ///
  /// ```swift
  /// Tag.insert {
  ///   if vehicleOwner {
  ///     Tag(name: "car")
  ///   }
  ///   Tag(name: "kids")
  ///   Tag(name: "someday")
  ///   Tag(name: "optional")
  /// }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// - Parameters:
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: updateFilter
    )
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<T1, each T2>(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    withoutActuallyEscaping(updates) { updates in
      _insert(
        columnNames: TableColumns.writableColumns.map(\.name),
        values: .values(values()),
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<T1, each T2>(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>) -> Void,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: { row, _ in updates(&row) },
      where: updateFilter
    )
  }

  /// An insert statement for one or more table rows.
  ///
  /// This function can be used to create an insert statement for a specified set of columns.
  ///
  /// ```swift
  /// Tag.insert {
  ///   $0.title
  /// } values: {
  ///   "car"
  /// }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car')
  /// ```
  ///
  /// It can also be used to insert multiple rows in a single statement.
  ///
  /// ```swift
  /// let tags = ["car", "kids", "someday", "optional"]
  /// Tag.insert {
  ///   $0.title
  /// } values: {
  ///   tags
  /// }
  /// let tags = ["car", "kids", "someday", "optional"]
  /// Tag.insert { tags }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// The `values` trailing closure is a result builder that will insert any number of expressions,
  /// one after the other, and supports basic control flow statements.
  ///
  /// ```swift
  /// Tag.insert {
  ///   $0.title
  /// } values: {
  ///   if vehicleOwner {
  ///     "car"
  ///   }
  ///   "kids"
  ///   "someday"
  ///   "optional"
  /// }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// - Parameters:
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    _insert(
      columns,
      values: values,
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: updateFilter
    )
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2, T1, each T2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    withoutActuallyEscaping(updates) { updates in
      _insert(
        columns,
        values: values,
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2, T1, each T2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>) -> Void,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: { row, _ in updates(&row) },
      where: updateFilter
    )
  }

  private static func _insert<each Value, each ConflictTarget>(
    _ columns: (TableColumns) -> (repeat TableColumn<Self, each Value>),
    @InsertValuesBuilder<(repeat each Value)>
    values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (repeat TableColumn<Self, each ConflictTarget>)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in repeat each columns(Self.columns) {
      columnNames.append(column.name)
    }
    return _insert(
      columnNames: columnNames,
      values: .values(values()),
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<
    V1,
    each V2
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    _insert(
      columns,
      select: selection,
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<
    V1,
    each V2
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      select: selection,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: updateFilter
    )
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<
    V1,
    each V2,
    T1,
    each T2
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    withoutActuallyEscaping(updates) { updates in
      _insert(
        columns,
        select: selection,
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<
    V1,
    each V2,
    T1,
    each T2
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>) -> Void,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      select: selection,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: { row, _ in updates(&row) },
      where: updateFilter
    )
  }

  private static func _insert<
    each Value,
    each ConflictTarget
  >(
    _ columns: (TableColumns) -> (repeat TableColumn<Self, each Value>),
    select selection: () -> some PartialSelectStatement<(repeat each Value)>,
    onConflict conflictTargets: (TableColumns) -> (repeat TableColumn<Self, each ConflictTarget>)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in repeat each columns(Self.columns) {
      columnNames.append(column.name)
    }
    return _insert(
      columnNames: columnNames,
      values: .select(selection().query),
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
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
  /// - Returns: An insert statement.
  public static func insert() -> InsertOf<Self> {
    _insert(
      columnNames: [],
      values: .default,
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: nil,
      where: { _ in return [] }
    )
  }

  fileprivate static func _insert<each ConflictTarget>(
    columnNames: [String],
    values: InsertValues,
    onConflict conflictTargets: (TableColumns) -> (repeat TableColumn<Self, each ConflictTarget>)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var conflictTargetColumnNames: [String] = []
    if let conflictTargets = conflictTargets(Self.columns) {
      for column in repeat each conflictTargets {
        conflictTargetColumnNames.append(column.name)
      }
    }
    return Insert(
      conflictResolution: nil,
      columnNames: columnNames,
      conflictTargetColumnNames: conflictTargetColumnNames,
      conflictTargetFilter: targetFilter(Self.columns),
      values: values,
      updates: updates.map { updates in Updates { updates(&$0, Excluded.QueryValue.columns) } },
      updateFilter: updateFilter(Self.columns),
      returning: []
    )
  }
}

extension PrimaryKeyedTable {
  /// An upsert statement for given drafts.
  ///
  /// Generates an insert statement with an upsert clause. Useful for building forms that can both
  /// insert new records as well as update them.
  ///
  /// ```swift
  /// Reminder.upsert { draft }
  /// // INSERT INTO "reminders" ("id", …)
  /// // VALUES (1, …)
  /// // ON CONFLICT DO UPDATE SET "…" = "excluded"."…", …
  /// ```
  ///
  /// - Parameters:
  ///   - values: A builder of row values for the given columns.
  /// - Returns: An insert statement with an upsert clause.
  public static func upsert(
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]]
  ) -> InsertOf<Self> {
    Insert(
      conflictResolution: nil,
      columnNames: TableColumns.writableColumns.map(\.name),
      conflictTargetColumnNames: columns.primaryKey._names,
      conflictTargetFilter: [],
      values: .values(values()),
      updates: Updates { updates in
        for (column, excluded) in zip(Draft.TableColumns.writableColumns, Excluded.writableColumns)
        where !columns.primaryKey._names.contains(column.name) {
          updates.set(column, excluded.queryFragment)
        }
      },
      updateFilter: [],
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
/// This type of statement is returned from the
/// `[Table.insert]<doc:Table/insert(_:values:onConflict:where:doUpdate:where:)>` family of
/// functions.
///
/// To learn more, see <doc:InsertStatements>.
public struct Insert<Into: Table, Returning> {
  package var conflictResolution: QueryFragment?
  var columnNames: [String]
  var conflictTargetColumnNames: [String]
  var conflictTargetFilter: [QueryFragment]
  fileprivate var values: InsertValues
  var updates: Updates<Into>?
  var updateFilter: [QueryFragment]
  var returning: [QueryFragment]

  fileprivate init(
    conflictResolution: QueryFragment?,
    columnNames: [String],
    conflictTargetColumnNames: [String],
    conflictTargetFilter: [QueryFragment],
    values: InsertValues,
    updates: Updates<Into>?,
    updateFilter: [QueryFragment],
    returning: [QueryFragment]
  ) {
    self.conflictResolution = conflictResolution
    self.columnNames = columnNames
    self.conflictTargetColumnNames = conflictTargetColumnNames
    self.conflictTargetFilter = conflictTargetFilter
    self.values = values
    self.updates = updates
    self.updateFilter = updateFilter
    self.returning = returning
  }

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
      conflictTargetFilter: conflictTargetFilter,
      values: values,
      updates: updates,
      updateFilter: updateFilter,
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
      conflictTargetFilter: conflictTargetFilter,
      values: values,
      updates: updates,
      updateFilter: updateFilter,
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
    query.append(" INTO ")
    if let schemaName = Into.schemaName {
      query.append("\(quote: schemaName).")
    }
    query.append("\(quote: Into.tableName)")
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

    case .select(let select):
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

    var hasInvalidWhere = false
    if let updates {
      query.append("\(.newlineOrSpace)ON CONFLICT ")
      if !conflictTargetColumnNames.isEmpty {
        query.append("(")
        query.append(conflictTargetColumnNames.map { "\(quote: $0)" }.joined(separator: ", "))
        query.append(")\(.newlineOrSpace)")
        if !conflictTargetFilter.isEmpty {
          query.append("WHERE \(conflictTargetFilter.joined(separator: " AND "))\(.newlineOrSpace)")
        }
      }
      query.append("DO ")
      if updates.isEmpty {
        query.append("NOTHING")
        hasInvalidWhere = !updateFilter.isEmpty
      } else {
        query.append("UPDATE \(bind: updates)")
        if !updateFilter.isEmpty {
          query.append("\(.newlineOrSpace)WHERE \(updateFilter.joined(separator: " AND "))")
        }
      }
    } else {
      hasInvalidWhere = !updateFilter.isEmpty
    }
    if !returning.isEmpty {
      query.append("\(.newlineOrSpace)RETURNING \(returning.joined(separator: ", "))")
    }
    if hasInvalidWhere {
      reportIssue(
        """
        Insert statement has invalid update 'where': \(updateFilter.joined(separator: " AND "))

        \(query)
        """
      )
    }
    return query
  }
}

/// A convenience type alias for a non-`RETURNING ``Insert``.
public typealias InsertOf<Into: Table> = Insert<Into, ()>

/// A builder of insert statement values.
///
/// This result builder is used by ``Table/insert(_:values:onConflict:where:doUpdate:where:)`` to
/// insert any number of rows into a table.
@resultBuilder
public enum InsertValuesBuilder<Value> {
  public static func buildExpression(_ expression: [Value]) -> [[QueryFragment]]
  where Value: Table {
    var valueFragments: [[QueryFragment]] = []
    for value in expression {
      var valueFragment: [QueryFragment] = []
      for column in Value.TableColumns.writableColumns {
        func open<Root, Member>(
          _ column: some WritableTableColumnExpression<Root, Member>
        ) -> QueryFragment {
          Member(queryOutput: (value as! Root)[keyPath: column.keyPath]).queryFragment
        }
        valueFragment.append(open(column))
      }
      valueFragments.append(valueFragment)
    }
    return valueFragments
  }

  @_disfavoredOverload
  public static func buildExpression(_ expression: [Value.Draft]) -> [[QueryFragment]]
  where Value: PrimaryKeyedTable {
    var valueFragments: [[QueryFragment]] = []
    for value in expression {
      var valueFragment: [QueryFragment] = []
      for column in Value.Draft.TableColumns.writableColumns {
        func open<Root, Member>(
          _ column: some WritableTableColumnExpression<Root, Member>
        ) -> QueryFragment {
          Member(queryOutput: (value as! Root)[keyPath: column.keyPath]).queryFragment
        }
        valueFragment.append(open(column))
      }
      valueFragments.append(valueFragment)
    }
    return valueFragments
  }

  @_disfavoredOverload
  public static func buildExpression<V: QueryExpression>(
    _ expression: [V]
  ) -> [[QueryFragment]]
  where
    Value == V.QueryValue,
    V.QueryValue: QueryRepresentable & QueryBindable
  {
    [expression.map(\.queryFragment)]
  }

  @_disfavoredOverload
  public static func buildExpression(
    _ expression: [Value.QueryOutput]
  ) -> [[QueryFragment]]
  where Value: QueryRepresentable & QueryBindable {
    [expression.map { Value(queryOutput: $0).queryFragment }]
  }

  public static func buildExpression(_ expression: Value) -> [[QueryFragment]]
  where Value: Table {
    buildExpression([expression])
  }

  public static func buildExpression(_ expression: Value.Draft) -> [[QueryFragment]]
  where Value: PrimaryKeyedTable {
    buildExpression([expression])
  }

  @_disfavoredOverload
  public static func buildExpression<V: QueryExpression>(
    _ expression: V
  ) -> [[QueryFragment]]
  where
    Value == V.QueryValue,
    V.QueryValue: QueryRepresentable & QueryBindable
  {
    buildExpression([expression])
  }

  public static func buildExpression(
    _ expression: Value.QueryOutput
  ) -> [[QueryFragment]]
  where Value: QueryRepresentable & QueryBindable {
    buildExpression([expression])
  }

  @_disfavoredOverload
  public static func buildExpression<each V: QueryExpression>(
    _ expression: (repeat each V)
  ) -> [[QueryFragment]]
  where
    Value == (repeat (each V).QueryValue),
    repeat (each V).QueryValue: QueryRepresentable & QueryBindable
  {
    var valueFragment: [QueryFragment] = []
    for column in repeat each expression {
      valueFragment.append(column.queryFragment)
    }
    return [valueFragment]
  }

  public static func buildExpression<each V: QueryRepresentable & QueryBindable>(
    _ expression: (repeat (each V).QueryOutput)
  ) -> [[QueryFragment]]
  where Value == (repeat each V) {
    var valueFragment: [QueryFragment] = []
    for (columnType, column) in repeat ((each V).self, each expression) {
      valueFragment.append(columnType.init(queryOutput: column).queryFragment)
    }
    return [valueFragment]
  }

  public static func buildExpression(
    _ expression: Value.Columns
  ) -> [[QueryFragment]]
  where Value: _Selection {
    [expression.selection.map(\.expression)]
  }

  public static func buildExpression(
    _ expression: Value.Selection
  ) -> [[QueryFragment]]
  where Value: Table {
    [expression.allColumns.map(\.queryFragment)]
  }

  public static func buildArray(_ components: [[[QueryFragment]]]) -> [[QueryFragment]] {
    components.flatMap(\.self)
  }

  public static func buildBlock(_ components: [[QueryFragment]]) -> [[QueryFragment]] {
    components
  }

  public static func buildEither(first component: [[QueryFragment]]) -> [[QueryFragment]] {
    component
  }

  public static func buildEither(second component: [[QueryFragment]]) -> [[QueryFragment]] {
    component
  }

  public static func buildLimitedAvailability(_ component: [[QueryFragment]]) -> [[QueryFragment]] {
    component
  }

  public static func buildOptional(_ component: [[QueryFragment]]?) -> [[QueryFragment]] {
    component ?? []
  }

  public static func buildPartialBlock(first: [[QueryFragment]]) -> [[QueryFragment]] {
    first
  }

  public static func buildPartialBlock(
    accumulated: [[QueryFragment]],
    next: [[QueryFragment]]
  ) -> [[QueryFragment]] {
    accumulated + next
  }
}

public struct _ExcludedName: AliasName {
  public static var aliasName: String { "excluded" }
}
