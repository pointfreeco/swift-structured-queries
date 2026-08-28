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
  ///     Tag(title: "car")
  ///   }
  ///   Tag(title: "kids")
  ///   Tag(title: "someday")
  ///   Tag(title: "optional")
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
    @InsertValuesBuilder<Self> values: () -> ValuesRows<Self>,
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
  ) -> InsertOf<Self> {
    _insert(
      columnNames: TableColumns.writableColumns.map(\.name),
      values: .values(values().rows),
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
  ///     Tag(title: "car")
  ///   }
  ///   Tag(title: "kids")
  ///   Tag(title: "someday")
  ///   Tag(title: "optional")
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
    @InsertValuesBuilder<Self> values: () -> ValuesRows<Self>,
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: { columns, _ in return updateFilter(columns) }
    )
  }

  /// An insert statement for one or more table rows.
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
  public static func insert<T1: _TableColumnExpression, each T2: _TableColumnExpression>(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> ValuesRows<Self>,
    onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
  ) -> InsertOf<Self> {
    withoutActuallyEscaping(updates) { updates in
      _insert(
        columnNames: TableColumns.writableColumns.map(\.name),
        values: .values(values().rows),
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An insert statement for one or more table rows.
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
  public static func insert<T1: _TableColumnExpression, each T2: _TableColumnExpression>(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> ValuesRows<Self>,
    onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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
      where: { row, _ in return updateFilter(row) }
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
  public static func insert<V1: _TableColumnExpression, each V2: _TableColumnExpression>(
    _ columns: (TableColumns) -> (V1, repeat each V2),
    @InsertValuesBuilder<(V1.Value, repeat (each V2).Value)>
    values: () -> ValuesRows<(V1.Value, repeat (each V2).Value)>,
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
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
  public static func insert<V1: _TableColumnExpression, each V2: _TableColumnExpression>(
    _ columns: (TableColumns) -> (V1, repeat each V2),
    @InsertValuesBuilder<(V1.Value, repeat (each V2).Value)>
    values: () -> ValuesRows<(V1.Value, repeat (each V2).Value)>,
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: { columns, _ in return updateFilter(columns) }
    )
  }

  /// An insert statement for one or more table rows.
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
  public static func insert<
    V1: _TableColumnExpression,
    each V2: _TableColumnExpression,
    T1: _TableColumnExpression,
    each T2: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> (V1, repeat each V2),
    @InsertValuesBuilder<(V1.Value, repeat (each V2).Value)>
    values: () -> ValuesRows<(V1.Value, repeat (each V2).Value)>,
    onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
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

  /// An insert statement for one or more table rows.
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
  public static func insert<
    V1: _TableColumnExpression,
    each V2: _TableColumnExpression,
    T1: _TableColumnExpression,
    each T2: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> (V1, repeat each V2),
    @InsertValuesBuilder<(V1.Value, repeat (each V2).Value)>
    values: () -> ValuesRows<(V1.Value, repeat (each V2).Value)>,
    onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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
      where: { row, _ in return updateFilter(row) }
    )
  }

  private static func _insert<
    each Value: _TableColumnExpression,
    each ConflictTarget: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> (repeat each Value),
    @InsertValuesBuilder<(repeat (each Value).Value)>
    values: () -> ValuesRows<(repeat (each Value).Value)>,
    onConflict conflictTargets: (TableColumns) -> (repeat each ConflictTarget)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in repeat each columns(Self.columns) {
      columnNames.append(contentsOf: column._names)
    }
    return _insert(
      columnNames: columnNames,
      values: .values(values().rows),
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
    V1: _TableColumnExpression,
    each V2: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> (V1, repeat each V2),
    select selection: () -> some PartialSelectStatement<(V1.Value, repeat (each V2).Value)>,
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
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

  // NB: This overload is required due to a parameter pack bug.
  public static func insert<V1: _TableColumnExpression>(
    _ columns: (TableColumns) -> V1,
    select selection: () -> some PartialSelectStatement<V1.Value>,
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
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
    V1: _TableColumnExpression,
    each V2: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> (V1, repeat each V2),
    select selection: () -> some PartialSelectStatement<(V1.Value, repeat (each V2).Value)>,
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      select: selection,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: { columns, _ in return updateFilter(columns) }
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
    V1: _TableColumnExpression,
    each V2: _TableColumnExpression,
    T1: _TableColumnExpression,
    each T2: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> (V1, repeat each V2),
    select selection: () -> some PartialSelectStatement<(V1.Value, repeat (each V2).Value)>,
    onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
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

  // NB: This overload is required due to a parameter pack bug.
  public static func insert<
    V1: _TableColumnExpression,
    T1: _TableColumnExpression,
    each T2: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> V1,
    select selection: () -> some PartialSelectStatement<V1.Value>,
    onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
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
    V1: _TableColumnExpression,
    each V2: _TableColumnExpression,
    T1: _TableColumnExpression,
    each T2: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> (V1, repeat each V2),
    select selection: () -> some PartialSelectStatement<(V1.Value, repeat (each V2).Value)>,
    onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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
      where: { row, _ in return updateFilter(row) }
    )
  }

  // NB: This overload is required due to a parameter pack bug.
  public static func insert<
    V1: _TableColumnExpression,
    T1: _TableColumnExpression,
    each T2: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> V1,
    select selection: () -> some PartialSelectStatement<V1.Value>,
    onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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
      where: { columns, _ in return updateFilter(columns) }
    )
  }

  // NB: We should constrain these generics `where Root == Self` when Swift supports same-type
  //     constraints in parameter packs.
  private static func _insert<
    each Value: _TableColumnExpression,
    each ConflictTarget: _TableColumnExpression
  >(
    _ columns: (TableColumns) -> (repeat each Value),
    select selection: () -> some PartialSelectStatement<(repeat (each Value).Value)>,
    onConflict conflictTargets: (TableColumns) -> (repeat each ConflictTarget)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in repeat each columns(Self.columns) {
      columnNames.append(contentsOf: column._names)
    }
    return _insert(
      columnNames: columnNames,
      values: .select(selection()),
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
      where: { _, _ in return [] }
    )
  }

  fileprivate static func _insert<each ConflictTarget: _TableColumnExpression>(
    columnNames: [String],
    values: InsertValues,
    onConflict conflictTargets: (TableColumns) -> (repeat each ConflictTarget)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns, Excluded) -> [QueryFragment] = { _, _ in [] }
  ) -> InsertOf<Self> {
    var conflictTargetColumnNames: [String] = []
    if let conflictTargets = conflictTargets(Self.columns) {
      for column in repeat each conflictTargets {
        conflictTargetColumnNames.append(contentsOf: column._names)
      }
    }
    return Insert(
      conflictResolution: nil,
      columnNames: columnNames,
      conflictTargetColumnNames: conflictTargetColumnNames,
      conflictTargetFilter: targetFilter(Self.columns),
      values: values,
      updates: updates.map { updates in Updates { updates(&$0, Excluded.QueryValue.columns) } },
      updateFilter: updateFilter(Self.columns, Excluded.QueryValue.columns),
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
    @InsertValuesBuilder<Self> values: () -> ValuesRows<Self>
  ) -> InsertOf<Self> {
    insert(
      values: values,
      onConflict: { $0.primaryKey },
      doUpdate: { updates, _ in
        for (column, excluded) in zip(Draft.TableColumns.writableColumns, Excluded.writableColumns)
        where !columns.primaryKey._names.contains(column.name) {
          updates.set(column, excluded.queryFragment)
        }
      }
    )
  }
}

private enum InsertValues {
  case `default`
  case values([[QueryFragment]])
  case select(any PartialSelectStatement)
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

  package func _returning<R>(_ returning: [QueryFragment]) -> Insert<Into, R> {
    Insert<Into, R>(
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

    case .select(let statement):
      let select = statement.query
      guard !select.isEmpty else { return "" }
      query.append("\(.newlineOrSpace)\(select)")
      if updates != nil,
        (statement as? any HasUpsertParsingAmbiguity)?.hasUpsertParsingAmbiguity == true
      {
        query.append("\(.newlineOrSpace)WHERE 1")
      }

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
        query.append("UPDATE \(updates)")
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
  public static func buildExpression(_ expression: [Value]) -> ValuesRows<Value>
  where Value: Table {
    var valueFragments: [[QueryFragment]] = []
    for value in expression {
      var encoder = QueryFragmentsEncoder()
      do {
        try value.encode(to: &encoder)
        valueFragments.append(encoder.fragments)
      } catch {
        valueFragments.append(
          Array(
            repeating: QueryFragment(segments: [.invalid(error)]),
            count: Value.TableColumns.writableColumns.count
          )
        )
      }
    }
    return ValuesRows(rows: valueFragments, elements: [Value.writableValuesElement])
  }

  @_disfavoredOverload
  public static func buildExpression(_ expression: [Value.Draft]) -> ValuesRows<Value>
  where Value: Table, Value.Draft: TableDraft {
    var valueFragments: [[QueryFragment]] = []
    for value in expression {
      var encoder = QueryFragmentsEncoder()
      do {
        try value.encode(to: &encoder)
        valueFragments.append(encoder.fragments)
      } catch {
        valueFragments.append(
          Array(
            repeating: QueryFragment(segments: [.invalid(error)]),
            count: Value.Draft.TableColumns.writableColumns.count
          )
        )
      }
    }
    return ValuesRows(rows: valueFragments, elements: [Value.Draft.writableValuesElement])
  }

  @_disfavoredOverload
  public static func buildExpression<V: QueryExpression>(
    _ expression: [V]
  ) -> ValuesRows<Value>
  where
    Value == V.QueryValue,
    V.QueryValue: QueryRepresentable & QueryBindable
  {
    ValuesRows(
      rows: expression.map { [$0.queryFragment] },
      elements: ValuesElement.elements(for: Value.self)
    )
  }

  @_disfavoredOverload
  public static func buildExpression(
    _ expression: [Value.QueryOutput]
  ) -> ValuesRows<Value>
  where Value: QueryRepresentable & QueryBindable {
    ValuesRows(
      rows: expression.map { [Value(queryOutput: $0).queryFragment] },
      elements: ValuesElement.elements(for: Value.self)
    )
  }

  public static func buildExpression(_ expression: Value) -> ValuesRows<Value>
  where Value: Table {
    buildExpression([expression])
  }

  public static func buildExpression(_ expression: Value.Draft) -> ValuesRows<Value>
  where Value: Table, Value.Draft: TableDraft {
    buildExpression([expression])
  }

  @_disfavoredOverload
  public static func buildExpression<V: QueryExpression>(
    _ expression: V
  ) -> ValuesRows<Value>
  where
    Value == V.QueryValue,
    V.QueryValue: QueryRepresentable & QueryBindable
  {
    buildExpression([expression])
  }

  public static func buildExpression(
    _ expression: Value.QueryOutput
  ) -> ValuesRows<Value>
  where Value: QueryRepresentable & QueryBindable {
    buildExpression([expression])
  }

  @_disfavoredOverload
  public static func buildExpression<each V: QueryExpression>(
    _ expression: (repeat each V)
  ) -> ValuesRows<Value>
  where
    Value == (repeat (each V).QueryValue),
    repeat (each V).QueryValue: QueryRepresentable
  {
    var valueFragment: [QueryFragment] = []
    for column in repeat each expression {
      valueFragment.append(column.queryFragment)
    }
    return ValuesRows(
      rows: [valueFragment],
      elements: ValuesElement.elements(for: repeat ((each V).QueryValue).self)
    )
  }

  public static func buildExpression<each V: QueryRepresentable & QueryBindable>(
    _ expression: (repeat (each V).QueryOutput)
  ) -> ValuesRows<Value>
  where Value == (repeat each V) {
    var valueFragment: [QueryFragment] = []
    for (columnType, column) in repeat ((each V).self, each expression) {
      valueFragment.append(columnType.init(queryOutput: column).queryFragment)
    }
    return ValuesRows(
      rows: [valueFragment],
      elements: ValuesElement.elements(for: repeat (each V).self)
    )
  }

  public static func buildExpression(
    _ expression: Value.Selection
  ) -> ValuesRows<Value>
  where Value: Table {
    ValuesRows(
      rows: [expression.allColumns.map(\.queryFragment)],
      elements: [Value.valuesElement]
    )
  }

  public static func buildExpression(
    _ expression: some TableExpression<Value>
  ) -> ValuesRows<Value>
  where Value: Table {
    ValuesRows(
      rows: [expression.allColumns.map(\.queryFragment)],
      elements: [Value.valuesElement]
    )
  }

  public static func buildArray(_ components: [ValuesRows<Value>]) -> ValuesRows<Value> {
    var rows = ValuesRows<Value>(rows: [])
    rows.rows.reserveCapacity(components.reduce(0) { $0 + $1.rows.count })
    for component in components {
      rows.append(component)
    }
    return rows
  }

  public static func buildBlock(_ components: ValuesRows<Value>) -> ValuesRows<Value> {
    components
  }

  public static func buildEither(first component: ValuesRows<Value>) -> ValuesRows<Value> {
    component
  }

  public static func buildEither(second component: ValuesRows<Value>) -> ValuesRows<Value> {
    component
  }

  public static func buildLimitedAvailability(_ component: ValuesRows<Value>) -> ValuesRows<Value> {
    component
  }

  public static func buildOptional(_ component: ValuesRows<Value>?) -> ValuesRows<Value> {
    component ?? ValuesRows(rows: [])
  }

  public static func buildPartialBlock(first: ValuesRows<Value>) -> ValuesRows<Value> {
    first
  }

  public static func buildPartialBlock(
    accumulated: ValuesRows<Value>,
    next: ValuesRows<Value>
  ) -> ValuesRows<Value> {
    var rows = accumulated
    rows.append(next)
    return rows
  }
}

public struct _ExcludedName: AliasName {
  public static var aliasName: String { "excluded" }
}
