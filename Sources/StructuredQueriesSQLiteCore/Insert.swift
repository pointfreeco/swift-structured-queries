extension Table {
  /// An insert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert(
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var insert = insert(columns, values: values, onConflictDoUpdate: updates, where: updateFilter)
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An insert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert(
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var insert = insert(columns, values: values, onConflictDoUpdate: updates, where: updateFilter)
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<T1, each T2>(
    or conflictResolution: ConflictResolution,
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
    var insert = insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<T1, each T2>(
    or conflictResolution: ConflictResolution,
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
    var insert = insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
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
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2>(
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var insert = insert(columns, values: values, onConflictDoUpdate: updates, where: updateFilter)
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An insert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2>(
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var insert = insert(columns, values: values, onConflictDoUpdate: updates, where: updateFilter)
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2, T1, each T2>(
    or conflictResolution: ConflictResolution,
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
    var insert = insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2, T1, each T2>(
    or conflictResolution: ConflictResolution,
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
    var insert = insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An insert statement for a table selection.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
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
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var insert = insert(
      columns,
      select: selection,
      onConflictDoUpdate: updates,
      where: updateFilter
    )
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An insert statement for a table selection.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
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
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var insert = insert(
      columns,
      select: selection,
      onConflictDoUpdate: updates,
      where: updateFilter
    )
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An insert statement for a table selection.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
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
    or conflictResolution: ConflictResolution,
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
    var insert = insert(
      columns,
      select: selection,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a `Select`
  /// statement.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
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
    or conflictResolution: ConflictResolution,
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
    var insert = insert(
      columns,
      select: selection,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }

  /// An insert statement for a table's default values.
  ///
  /// - Parameter conflictResolution: A conflict resolution algorithm.
  /// - Returns: An insert statement.
  public static func insert(
    or conflictResolution: ConflictResolution
  ) -> InsertOf<Self> {
    var insert = insert()
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }
}

// TODO: Support composite keys.
extension PrimaryKeyedTable where TableColumns.PrimaryKeyColumn == TableColumn<Self, PrimaryKey> {
  /// An upsert statement for given drafts.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - values: A builder of row values for the given columns.
  /// - Returns: An insert statement with an upsert clause.
  public static func upsert(
    or conflictResolution: ConflictResolution,
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]]
  ) -> InsertOf<Self> {
    var insert = upsert(values: values)
    insert.conflictResolution = conflictResolution.queryFragment
    return insert
  }
}
