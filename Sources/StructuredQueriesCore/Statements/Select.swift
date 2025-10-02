extension Table {
  /// A select statement for a column of this table.
  ///
  /// See <doc:SelectStatements> for more info.
  ///
  /// - Parameter selection: A key path to a column to select.
  /// - Returns: A select statement that selects the given column.
  public static func select<ResultColumn: QueryExpression>(
    _ selection: KeyPath<TableColumns, ResultColumn>
  ) -> Select<ResultColumn.QueryValue, Self, ()>
  where ResultColumn.QueryValue: QueryRepresentable {
    Where().select(selection)
  }

  /// A select statement for a column of this table.
  ///
  /// See <doc:SelectStatements> for more info.
  ///
  /// - Parameter selection: A closure that selects a result column from this table's columns.
  /// - Returns: A select statement that selects the given column.
  public static func select<ResultColumn: QueryExpression>(
    _ selection: (TableColumns) -> ResultColumn
  ) -> Select<ResultColumn.QueryValue, Self, ()>
  where ResultColumn.QueryValue: QueryRepresentable {
    Where().select(selection)
  }

  /// A select statement for columns of this table.
  ///
  /// See <doc:SelectStatements> for more info.
  ///
  /// - Parameter selection: A closure that selects result columns from this table's columns.
  /// - Returns: A select statement that selects the given columns.
  public static func select<
    C1: QueryExpression,
    C2: QueryExpression,
    each C3: QueryExpression
  >(
    _ selection: (TableColumns) -> (C1, C2, repeat each C3)
  ) -> Select<(C1.QueryValue, C2.QueryValue, repeat (each C3).QueryValue), Self, ()>
  where
    C1.QueryValue: QueryRepresentable,
    C2.QueryValue: QueryRepresentable,
    repeat (each C3).QueryValue: QueryRepresentable
  {
    Where().select(selection)
  }

  /// A distinct select statement for this table.
  ///
  /// - Parameter isDistinct: Whether or not to `SELECT DISTINCT`.
  /// - Returns: A select statement with a `DISTINCT` clause determined by `isDistinct`.
  public static func distinct(_ isDistinct: Bool = true) -> SelectOf<Self> {
    Where().distinct(isDistinct)
  }

  /// A select statement for this table joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that joins the given table.
  public static func join<
    each C: QueryRepresentable,
    F: Table,
    each J: Table
  >(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), Self, (F, repeat each J)> {
    Where().join(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for this table joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that joins the given table.
  @_documentation(visibility: private)
  public static func join<each C: QueryRepresentable, F: Table>(
    _ other: some SelectStatement<(repeat each C), F, ()>,
    on constraint: (
      (TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), Self, F> {
    Where().join(other, on: constraint)
  }

  /// A select statement for this table left-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that left-joins the given table.
  public static func leftJoin<
    each C: QueryRepresentable,
    F: Table,
    each J: Table
  >(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C)._Optionalized),
    Self,
    (F._Optionalized, repeat (each J)._Optionalized)
  > {
    Where().leftJoin(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for this table left-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that left-joins the given table.
  @_documentation(visibility: private)
  public static func leftJoin<each C: QueryRepresentable, F: Table>(
    _ other: some SelectStatement<(repeat each C), F, ()>,
    on constraint: (
      (TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat (each C)._Optionalized), Self, F._Optionalized> {
    Where().leftJoin(other, on: constraint)
  }

  /// A select statement for this table right-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that right-joins the given table.
  public static func rightJoin<
    each C: QueryRepresentable,
    F: Table,
    each J: Table
  >(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), Self._Optionalized, (F, repeat each J)> {
    Where<Self>().rightJoin(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for this table right-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that right-joins the given table.
  @_documentation(visibility: private)
  public static func rightJoin<each C: QueryRepresentable, F: Table>(
    _ other: some SelectStatement<(repeat each C), F, ()>,
    on constraint: (
      (TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), Self._Optionalized, F> {
    Where<Self>().rightJoin(other, on: constraint)
  }

  /// A select statement for this table full-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that full-joins the given table.
  public static func fullJoin<
    each C: QueryRepresentable,
    F: Table,
    each J: Table
  >(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C)._Optionalized),
    Self._Optionalized,
    (F._Optionalized, repeat (each J)._Optionalized)
  > {
    Where<Self>().fullJoin(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for this table full-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that full-joins the given table.
  @_documentation(visibility: private)
  public static func fullJoin<each C: QueryRepresentable, F: Table>(
    _ other: some SelectStatement<(repeat each C), F, ()>,
    on constraint: (
      (TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat (each C)._Optionalized), Self._Optionalized, F._Optionalized> {
    Where<Self>().fullJoin(other, on: constraint)
  }

  /// A select statement for this table grouped by the given column.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this table's columns.
  /// - Returns: A select statement that groups by the given column.
  public static func group<C: QueryExpression>(
    by grouping: (TableColumns) -> C
  ) -> SelectOf<Self> {
    Where().group(by: grouping)
  }

  /// A select statement for this table grouped by the given columns.
  ///
  /// - Parameter grouping: A closure that returns columns to group by from this table's columns.
  /// - Returns: A select statement that groups by the given column.
  public static func group<
    C1: QueryExpression,
    C2: QueryExpression,
    each C3: QueryExpression
  >(
    by grouping: (TableColumns) -> (C1, C2, repeat each C3)
  ) -> SelectOf<Self> {
    Where().group(by: grouping)
  }

  /// A select statement for this table with the given `HAVING` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this table's
  ///   columns.
  /// - Returns: A select statement that is filtered by the given predicate.
  public static func having(
    _ predicate: (TableColumns) -> some QueryExpression<some _OptionalPromotable<Bool?>>
  ) -> SelectOf<Self> {
    Where().having(predicate)
  }

  /// A select statement for this table ordered by the given column.
  ///
  /// - Parameter ordering: A key path to a column to order by.
  /// - Returns: A select statement that is ordered by the given column.
  public static func order(
    by ordering: KeyPath<TableColumns, some QueryExpression>
  ) -> SelectOf<Self> {
    Where().order(by: ordering)
  }

  /// A select statement for this table ordered by the given columns.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A select statement that is ordered by the given columns.
  public static func order(
    @QueryFragmentBuilder<()>
    by ordering: (TableColumns) -> [QueryFragment]
  ) -> SelectOf<Self> {
    Where().order(by: ordering)
  }

  /// A select statement for this table with a limit and optional offset.
  ///
  /// - Parameters:
  ///   - maxLength: A closure that produces a `LIMIT` expression from the filtered table's columns.
  ///   - offset: A closure that produces an `OFFSET` expression from the filtered table's columns.
  /// - Returns: A select statement with a limit and optional offset.
  public static func limit(
    _ maxLength: (TableColumns) -> some QueryExpression<Int>,
    offset: ((TableColumns) -> some QueryExpression<Int>)? = nil
  ) -> SelectOf<Self> {
    Where().limit(maxLength, offset: offset)
  }

  /// A select statement for this table with a limit and optional offset.
  ///
  /// - Parameters:
  ///   - maxLength: An integer limit for the select's `LIMIT` clause.
  ///   - offset: An optional integer offset of the select's `OFFSET` clause.
  /// - Returns: A select statement with a limit and optional offset.
  public static func limit(_ maxLength: Int, offset: Int? = nil) -> SelectOf<Self> {
    Where().limit(maxLength, offset: offset)
  }

  /// A select statement for this table's row count.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects `count(*)`.
  public static func count(
    filter: ((TableColumns) -> any QueryExpression<Bool>)? = nil
  ) -> Select<Int, Self, ()> {
    Where().count(filter: filter)
  }
}

public struct _SelectClauses: Sendable {
  var isEmpty = false
  var distinct = false
  var columns: [QueryFragment] = []
  var joins: [_JoinClause] = []
  var `where`: [QueryFragment] = []
  var group: [QueryFragment] = []
  var having: [QueryFragment] = []
  var order: [QueryFragment] = []
  var limit: _LimitClause?
}

/// A `SELECT` statement.
///
/// This type of statement is constructed from ``Table/all`` and static aliases to methods on the
/// `Select` type, like `select`, `join`, `group(by:)`, `order(by:)`, and more.
///
/// To learn more, see <doc:SelectStatements>.
#if compiler(>=6.1)
  @dynamicMemberLookup
#endif
public struct Select<Columns, From: Table, Joins>: Sendable {
  // NB: A parameter pack compiler crash forces us to heap-allocate this storage.
  @CopyOnWrite var clauses = _SelectClauses()

  fileprivate var isEmpty: Bool {
    get { clauses.isEmpty }
    set { clauses.isEmpty = newValue }
    _modify { yield &clauses.isEmpty }
  }
  fileprivate var distinct: Bool {
    get { clauses.distinct }
    set { clauses.distinct = newValue }
    _modify { yield &clauses.distinct }
  }
  fileprivate var columns: [QueryFragment] {
    get { clauses.columns }
    set { clauses.columns = newValue }
    _modify { yield &clauses.columns }
  }
  fileprivate var joins: [_JoinClause] {
    get { clauses.joins }
    set { clauses.joins = newValue }
    _modify { yield &clauses.joins }
  }
  fileprivate var `where`: [QueryFragment] {
    get { clauses.where }
    set { clauses.where = newValue }
    _modify { yield &clauses.where }
  }
  fileprivate var group: [QueryFragment] {
    get { clauses.group }
    set { clauses.group = newValue }
    _modify { yield &clauses.group }
  }
  fileprivate var having: [QueryFragment] {
    get { clauses.having }
    set { clauses.having = newValue }
    _modify { yield &clauses.having }
  }
  fileprivate var order: [QueryFragment] {
    get { clauses.order }
    set { clauses.order = newValue }
    _modify { yield &clauses.order }
  }
  fileprivate var limit: _LimitClause? {
    get { clauses.limit }
    set { clauses.limit = newValue }
    _modify { yield &clauses.limit }
  }

  fileprivate init(
    isEmpty: Bool,
    distinct: Bool,
    columns: [QueryFragment],
    joins: [_JoinClause],
    where: [QueryFragment],
    group: [QueryFragment],
    having: [QueryFragment],
    order: [QueryFragment],
    limit: _LimitClause?
  ) {
    self.isEmpty = isEmpty
    self.columns = columns
    self.distinct = distinct
    self.joins = joins
    self.where = `where`
    self.group = group
    self.having = having
    self.order = order
    self.limit = limit
  }

  init(clauses: _SelectClauses) {
    self.clauses = clauses
  }
}

extension Select {
  init(isEmpty: Bool = false, where: [QueryFragment] = []) {
    self.isEmpty = isEmpty
    self.where = `where`
  }

  #if DEBUG && compiler(>=6.1)
    // NB: This can cause 'EXC_BAD_ACCESS' when 'C2' or 'J2' contain parameters.
    // TODO: Report issue to Swift team.
    @available(
      *,
      unavailable,
      message: """
        No overload is available for this many columns/joins. To request more overloads, please file a GitHub issue that describes your use case: https://github.com/pointfreeco/swift-structured-queries
        """
    )
    public subscript<
      each C1: QueryRepresentable,
      each C2: QueryRepresentable,
      each J1: Table,
      each J2: Table
    >(
      dynamicMember keyPath: KeyPath<From.Type, Select<(repeat each C2), From, (repeat each J2)>>
    ) -> Select<(repeat each C1, repeat each C2), From, (repeat each J1, repeat each J2)>
    where Columns == (repeat each C1), Joins == (repeat each J1) {
      self + From.self[keyPath: keyPath]
    }
  #endif

  /// Creates a new select statement from this one by appending the given result column to its
  /// selection.
  ///
  /// - Parameter selection: A key path to a column to select.
  /// - Returns: A new select statement that selects the given column.
  public func select<each C1: QueryRepresentable, C2: QueryExpression>(
    _ selection: KeyPath<From.TableColumns, C2>
  ) -> Select<(repeat each C1, C2.QueryValue), From, ()>
  where Columns == (repeat each C1), C2.QueryValue: QueryRepresentable, Joins == () {
    select { $0[keyPath: selection] }
  }

  // NB: This overload is required for CTEs with join clauses to avoid a compiler bug.
  /// Creates a new select statement from this one by selecting the given result column.
  ///
  /// - Parameter selection: A closure that selects a result column from this select's tables.
  /// - Returns: A new select statement that selects the given column.
  @_disfavoredOverload
  public func select<C: QueryExpression, each J: Table>(
    _ selection: ((From.TableColumns, repeat (each J).TableColumns)) -> C
  ) -> Select<C.QueryValue, From, (repeat each J)>
  where Columns == (), C.QueryValue: QueryRepresentable, Joins == (repeat each J) {
    _select(selection)
  }

  /// Creates a new select statement from this one by selecting the given result column.
  ///
  /// - Parameter selection: A closure that selects a result column from this select's tables.
  /// - Returns: A new select statement that selects the given column.
  @_disfavoredOverload
  public func select<C: QueryExpression, each J: Table>(
    _ selection: (From.TableColumns, repeat (each J).TableColumns) -> C
  ) -> Select<C.QueryValue, From, (repeat each J)>
  where Columns == (), C.QueryValue: QueryRepresentable, Joins == (repeat each J) {
    _select(selection)
  }

  /// Creates a new select statement from this one by appending the given result column to its
  /// selection.
  ///
  /// - Parameter selection: A closure that selects a result column from this select's table.
  /// - Returns: A new select statement that selects the given column.
  public func select<each C1: QueryRepresentable, C2: QueryExpression>(
    _ selection: (From.TableColumns) -> C2
  ) -> Select<(repeat each C1, C2.QueryValue), From, ()>
  where Columns == (repeat each C1), C2.QueryValue: QueryRepresentable, Joins == () {
    _select(selection)
  }

  /// Creates a new select statement from this one by appending the given result column to its
  /// selection.
  ///
  /// - Parameter selection: A closure that selects a result column from this select's tables.
  /// - Returns: A new select statement that selects the given column.
  public func select<each C1: QueryRepresentable, C2: QueryExpression, each J: Table>(
    _ selection: ((From.TableColumns, repeat (each J).TableColumns)) -> C2
  ) -> Select<(repeat each C1, C2.QueryValue), From, (repeat each J)>
  where Columns == (repeat each C1), C2.QueryValue: QueryRepresentable, Joins == (repeat each J) {
    _select(selection)
  }

  /// Creates a new select statement from this one by appending the given result column to its
  /// selection.
  ///
  /// - Parameter selection: A closure that selects a result column from this select's tables.
  /// - Returns: A new select statement that selects the given column.
  @_disfavoredOverload
  public func select<each C1: QueryRepresentable, C2: QueryExpression, each J: Table>(
    _ selection: (From.TableColumns, repeat (each J).TableColumns) -> C2
  ) -> Select<(repeat each C1, C2.QueryValue), From, (repeat each J)>
  where Columns == (repeat each C1), C2.QueryValue: QueryRepresentable, Joins == (repeat each J) {
    _select(selection)
  }

  /// Creates a new select statement from this one by appending the given result columns to its
  /// selection.
  ///
  /// - Parameter selection: A closure that selects columns from this select's tables.
  /// - Returns: A new select statement that selects the given columns.
  public func select<
    each C1: QueryRepresentable,
    C2: QueryExpression,
    C3: QueryExpression,
    each C4: QueryExpression,
    each J: Table
  >(
    _ selection: ((From.TableColumns, repeat (each J).TableColumns)) -> (C2, C3, repeat each C4)
  ) -> Select<
    (repeat each C1, C2.QueryValue, C3.QueryValue, repeat (each C4).QueryValue),
    From,
    (repeat each J)
  >
  where
    Columns == (repeat each C1),
    C2.QueryValue: QueryRepresentable,
    C3.QueryValue: QueryRepresentable,
    repeat (each C4).QueryValue: QueryRepresentable,
    Joins == (repeat each J)
  {
    _select(selection)
  }

  /// Creates a new select statement from this one by appending the given result columns to its
  /// selection.
  ///
  /// - Parameter selection: A closure that selects columns from this select's tables.
  /// - Returns: A new select statement that selects the given columns.
  @_disfavoredOverload
  public func select<
    each C1: QueryRepresentable,
    C2: QueryExpression,
    C3: QueryExpression,
    each C4: QueryExpression,
    each J: Table
  >(
    _ selection: (From.TableColumns, repeat (each J).TableColumns) -> (C2, C3, repeat each C4)
  ) -> Select<
    (repeat each C1, C2.QueryValue, C3.QueryValue, repeat (each C4).QueryValue),
    From,
    (repeat each J)
  >
  where
    Columns == (repeat each C1),
    C2.QueryValue: QueryRepresentable,
    C3.QueryValue: QueryRepresentable,
    repeat (each C4).QueryValue: QueryRepresentable,
    Joins == (repeat each J)
  {
    _select(selection)
  }

  private func _select<
    each C1: QueryRepresentable,
    each C2: QueryExpression,
    each J: Table
  >(
    _ selection: ((From.TableColumns, repeat (each J).TableColumns)) -> (repeat each C2)
  ) -> Select<(repeat each C1, repeat (each C2).QueryValue), From, (repeat each J)>
  where
    Columns == (repeat each C1),
    repeat (each C2).QueryValue: QueryRepresentable,
    Joins == (repeat each J)
  {
    Select<(repeat each C1, repeat (each C2).QueryValue), From, (repeat each J)>(
      isEmpty: isEmpty,
      distinct: distinct,
      columns: columns
        + $_isSelecting.withValue(true) {
          Array(repeat each selection((From.columns, repeat (each J).columns)))
        },
      joins: joins,
      where: `where`,
      group: group,
      having: having,
      order: order,
      limit: limit
    )
  }

  /// Creates a new select statement from this one by setting its distinct clause.
  ///
  /// - Parameter isDistinct: Whether or not to `SELECT DISTINCT`.
  /// - Returns: A new select statement with a `DISTINCT` clause determined by `isDistinct`.
  public func distinct(_ isDistinct: Bool = true) -> Self {
    var select = self
    select.distinct = isDistinct
    return select
  }

  /// Creates a new select statement from this one by joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that joins the given table and combines their clauses
  ///   together.
  public func join<
    each C1: QueryRepresentable,
    each C2: QueryRepresentable,
    F: Table,
    each J1: Table,
    each J2: Table
  >(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(repeat each C2), F, (repeat each J2)>,
    on constraint: (
      (
        From.TableColumns, repeat (each J1).TableColumns, F.TableColumns,
        repeat (each J2).TableColumns
      )
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C1, repeat each C2), From, (repeat each J1, F, repeat each J2)>
  where Columns == (repeat each C1), Joins == (repeat each J1) {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: nil,
      table: F.self,
      constraint: constraint(
        (From.columns, repeat (each J1).columns, F.columns, repeat (each J2).columns)
      )
    )
    return Select<(repeat each C1, repeat each C2), From, (repeat each J1, F, repeat each J2)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  // NB: Optimization
  /// Creates a new select statement from this one by joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that joins the given table and combines their clauses
  ///   together.
  @_documentation(visibility: private)
  @_disfavoredOverload
  public func join<
    each C1: QueryRepresentable, each C2: QueryRepresentable, F: Table, each J: Table
  >(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(repeat each C2), F, ()>,
    on constraint: (
      (From.TableColumns, repeat (each J).TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C1, repeat each C2), From, (repeat each J, F)>
  where Columns == (repeat each C1), Joins == (repeat each J) {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: nil,
      table: F.self,
      constraint: constraint(
        (From.columns, repeat (each J).columns, F.columns)
      )
    )
    return Select<(repeat each C1, repeat each C2), From, (repeat each J, F)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  /// Creates a new select statement from this one by joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that joins the given table and combines their clauses
  ///   together.
  @_disfavoredOverload
  @_documentation(visibility: private)
  public func join<F: Table, each J: Table>(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<QueryValue, From, (F, repeat each J)> where QueryValue: QueryRepresentable {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: nil,
      table: F.self,
      constraint: constraint(
        (From.columns, F.columns, repeat (each J).columns)
      )
    )
    return Select<QueryValue, From, (F, repeat each J)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func join<F: Table>(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatementOf<F>,
    on constraint: (
      (From.TableColumns, Joins.TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(), From, (Joins, F)> where Joins: Table {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: nil,
      table: F.self,
      constraint: constraint(
        (From.columns, Joins.columns, F.columns)
      )
    )
    return Select<(), From, (Joins, F)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  /// Creates a new select statement from this one by left-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that left-joins the given table and combines their clauses
  ///   together.
  public func leftJoin<
    each C1: QueryRepresentable,
    each C2: QueryRepresentable,
    F: Table,
    each J1: Table,
    each J2: Table
  >(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(repeat each C2), F, (repeat each J2)>,
    on constraint: (
      (
        From.TableColumns, repeat (each J1).TableColumns, F.TableColumns,
        repeat (each J2).TableColumns
      )
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat each C1, repeat (each C2)._Optionalized),
    From,
    (repeat each J1, F._Optionalized, repeat (each J2)._Optionalized)
  >
  where Columns == (repeat each C1), Joins == (repeat each J1) {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .left,
      table: F.self,
      constraint: constraint(
        (From.columns, repeat (each J1).columns, F.columns, repeat (each J2).columns)
      )
    )
    return Select<
      (repeat each C1, repeat (each C2)._Optionalized),
      From,
      (repeat each J1, F._Optionalized, repeat (each J2)._Optionalized)
    >(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  // NB: Optimization
  /// Creates a new select statement from this one by left-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that left-joins the given table and combines their clauses
  ///   together.
  @_disfavoredOverload
  @_documentation(visibility: private)
  public func leftJoin<
    each C1: QueryRepresentable, each C2: QueryRepresentable, F: Table, each J: Table
  >(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(repeat each C2), F, ()>,
    on constraint: (
      (From.TableColumns, repeat (each J).TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat each C1, repeat (each C2)._Optionalized),
    From,
    (repeat each J, F._Optionalized)
  >
  where Columns == (repeat each C1), Joins == (repeat each J) {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .left,
      table: F.self,
      constraint: constraint(
        (From.columns, repeat (each J).columns, F.columns)
      )
    )
    return Select<
      (repeat each C1, repeat (each C2)._Optionalized),
      From,
      (repeat each J, F._Optionalized)
    >(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  // NB: Optimization
  /// Creates a new select statement from this one by left-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that left-joins the given table and combines their clauses
  ///   together.
  @_disfavoredOverload
  @_documentation(visibility: private)
  public func leftJoin<F: Table, each J: Table>(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<QueryValue, From, (F._Optionalized, repeat (each J)._Optionalized)>
  where QueryValue: QueryRepresentable {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .left,
      table: F.self,
      constraint: constraint(
        (From.columns, F.columns, repeat (each J).columns)
      )
    )
    return Select<QueryValue, From, (F._Optionalized, repeat (each J)._Optionalized)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func leftJoin<F: Table>(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatementOf<F>,
    on constraint: (
      (From.TableColumns, Joins.TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(), From, (Joins, F._Optionalized)>
  where Joins: Table {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .left,
      table: F.self,
      constraint: constraint(
        (From.columns, Joins.columns, F.columns)
      )
    )
    return Select<(), From, (Joins, F._Optionalized)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  /// Creates a new select statement from this one by right-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that right-joins the given table and combines their clauses
  ///   together.
  public func rightJoin<
    each C1: QueryRepresentable,
    each C2: QueryRepresentable,
    F: Table,
    each J1: Table,
    each J2: Table
  >(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(repeat each C2), F, (repeat each J2)>,
    on constraint: (
      (
        From.TableColumns, repeat (each J1).TableColumns, F.TableColumns,
        repeat (each J2).TableColumns
      )
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C1)._Optionalized, repeat each C2),
    From._Optionalized,
    (repeat (each J1)._Optionalized, F, repeat each J2)
  >
  where Columns == (repeat each C1), Joins == (repeat each J1) {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .right,
      table: F.self,
      constraint: constraint(
        (From.columns, repeat (each J1).columns, F.columns, repeat (each J2).columns)
      )
    )
    return Select<
      (repeat (each C1)._Optionalized, repeat each C2),
      From._Optionalized,
      (repeat (each J1)._Optionalized, F, repeat each J2)
    >(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  // NB: Optimization
  /// Creates a new select statement from this one by right-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that right-joins the given table and combines their clauses
  ///   together.
  @_disfavoredOverload
  @_documentation(visibility: private)
  public func rightJoin<
    each C1: QueryRepresentable, each C2: QueryRepresentable, F: Table, each J: Table
  >(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(repeat each C2), F, ()>,
    on constraint: (
      (From.TableColumns, repeat (each J).TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C1)._Optionalized, repeat each C2),
    From._Optionalized,
    (repeat (each J)._Optionalized, F)
  >
  where Columns == (repeat each C1), Joins == (repeat each J) {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .right,
      table: F.self,
      constraint: constraint(
        (From.columns, repeat (each J).columns, F.columns)
      )
    )
    return Select<
      (repeat (each C1)._Optionalized, repeat each C2),
      From._Optionalized,
      (repeat (each J)._Optionalized, F)
    >(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  // NB: Optimization
  /// Creates a new select statement from this one by right-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that right-joins the given table and combines their clauses
  ///   together.
  @_disfavoredOverload
  @_documentation(visibility: private)
  public func rightJoin<F: Table, each J: Table>(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<QueryValue, From._Optionalized, (F, repeat each J)>
  where QueryValue: QueryRepresentable {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .right,
      table: F.self,
      constraint: constraint(
        (From.columns, F.columns, repeat (each J).columns)
      )
    )
    return Select<QueryValue, From._Optionalized, (F, repeat each J)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func rightJoin<F: Table>(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatementOf<F>,
    on constraint: (
      (From.TableColumns, Joins.TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(), From._Optionalized, (Joins._Optionalized, F)>
  where Joins: Table {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .right,
      table: F.self,
      constraint: constraint(
        (From.columns, Joins.columns, F.columns)
      )
    )
    return Select<(), From._Optionalized, (Joins._Optionalized, F)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  /// Creates a new select statement from this one by full-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that full-joins the given table and combines their clauses
  ///   together.
  public func fullJoin<
    each C1: QueryRepresentable,
    each C2: QueryRepresentable,
    F: Table,
    each J1: Table,
    each J2: Table
  >(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(repeat each C2), F, (repeat each J2)>,
    on constraint: (
      (
        From.TableColumns, repeat (each J1).TableColumns, F.TableColumns,
        repeat (each J2).TableColumns
      )
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C1)._Optionalized, repeat (each C2)._Optionalized),
    From._Optionalized,
    (repeat (each J1)._Optionalized, F._Optionalized, repeat (each J2)._Optionalized)
  >
  where Columns == (repeat each C1), Joins == (repeat each J1) {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .full,
      table: F.self,
      constraint: constraint(
        (From.columns, repeat (each J1).columns, F.columns, repeat (each J2).columns)
      )
    )
    return Select<
      (repeat (each C1)._Optionalized, repeat (each C2)._Optionalized),
      From._Optionalized,
      (repeat (each J1)._Optionalized, F._Optionalized, repeat (each J2)._Optionalized)
    >(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  // NB: Optimization
  /// Creates a new select statement from this one by full-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that full-joins the given table and combines their clauses
  ///   together.
  @_disfavoredOverload
  @_documentation(visibility: private)
  public func fullJoin<
    each C1: QueryRepresentable, each C2: QueryRepresentable, F: Table, each J: Table
  >(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(repeat each C2), F, ()>,
    on constraint: (
      (From.TableColumns, repeat (each J).TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C1)._Optionalized, repeat (each C2)._Optionalized),
    From._Optionalized,
    (repeat (each J)._Optionalized, F._Optionalized)
  >
  where Columns == (repeat each C1), Joins == (repeat each J) {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .full,
      table: F.self,
      constraint: constraint(
        (From.columns, repeat (each J).columns, F.columns)
      )
    )
    return Select<
      (repeat (each C1)._Optionalized, repeat (each C2)._Optionalized),
      From._Optionalized,
      (repeat (each J)._Optionalized, F._Optionalized)
    >(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  // NB: Optimization
  /// Creates a new select statement from this one by full-joining another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A new select statement that full-joins the given table and combines their clauses
  ///   together.
  @_disfavoredOverload
  @_documentation(visibility: private)
  public func fullJoin<F: Table, each J: Table>(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatement<(), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<QueryValue, From._Optionalized, (F._Optionalized, repeat (each J)._Optionalized)>
  where QueryValue: QueryRepresentable {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .full,
      table: F.self,
      constraint: constraint(
        (From.columns, F.columns, repeat (each J).columns)
      )
    )
    return Select<QueryValue, From._Optionalized, (F._Optionalized, repeat (each J)._Optionalized)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func fullJoin<F: Table>(
    // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
    _ other: any SelectStatementOf<F>,
    on constraint: (
      (From.TableColumns, Joins.TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(), From._Optionalized, (Joins._Optionalized, F._Optionalized)>
  where Joins: Table {
    let other = other.asSelect()
    let join = _JoinClause(
      operator: .full,
      table: F.self,
      constraint: constraint(
        (From.columns, Joins.columns, F.columns)
      )
    )
    return Select<(), From._Optionalized, (Joins._Optionalized, F._Optionalized)>(
      isEmpty: isEmpty || other.isEmpty,
      distinct: distinct || other.distinct,
      columns: columns + other.columns,
      joins: joins + [join] + other.joins,
      where: `where` + other.where,
      group: group + other.group,
      having: having + other.having,
      order: order + other.order,
      limit: other.limit ?? limit
    )
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter keyPath: A key path from this select's table to a Boolean expression to filter by.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`(
    _ keyPath: KeyPath<From.TableColumns, some QueryExpression<some _OptionalPromotable<Bool?>>>
  ) -> Self
  where Joins == () {
    var select = self
    select.where.append(From.columns[keyPath: keyPath].queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this select's
  ///   tables.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  @_disfavoredOverload
  public func `where`<each J: Table>(
    _ predicate: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<
      some _OptionalPromotable<Bool?>
    >
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.where.append(predicate(From.columns, repeat (each J).columns).queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`<each J: Table>(
    @QueryFragmentBuilder<Bool>
    _ predicate: (From.TableColumns, repeat (each J).TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.where.append(contentsOf: predicate(From.columns, repeat (each J).columns))
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this select's
  ///   tables.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  @_disfavoredOverload
  public func `where`(
    _ predicate: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<
      some _OptionalPromotable<Bool?>
    >
  ) -> Self
  where Joins: Table {
    var select = self
    select.where.append(predicate(From.columns, Joins.columns).queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`(
    @QueryFragmentBuilder<Bool>
    _ predicate: (From.TableColumns, Joins.TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins: Table {
    var select = self
    select.where.append(contentsOf: predicate(From.columns, Joins.columns))
    return select
  }

  public func and(_ other: Where<From>) -> Self {
    var select = self
    select.where = (select.where + other.predicates).removingDuplicates()
    return select
  }

  public func or(_ other: Where<From>) -> Self {
    var select = self
    if select.where.isEmpty {
      select.where = other.predicates
    } else {
      select.where = [
        """
        (\(select.where.joined(separator: " AND ")) \
        OR \
        \(other.predicates.joined(separator: " AND ")))
        """
      ]
    }
    return select
  }

  /// Creates a new select statement from this one by appending the given column to its `GROUP BY`
  /// clause.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this select's tables.
  /// - Returns: A new select statement that groups by the given column.
  public func group<C: QueryExpression, each J: Table>(
    by grouping: (From.TableColumns, repeat (each J).TableColumns) -> C
  ) -> Self where Joins == (repeat each J) {
    _group(by: grouping)
  }

  /// Creates a new select statement from this one by appending the given columns to its `GROUP BY`
  /// clause.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this select's tables.
  /// - Returns: A new select statement that groups by the given column.
  public func group<
    C1: QueryExpression,
    C2: QueryExpression,
    each C3: QueryExpression,
    each J: Table
  >(
    by grouping: (From.TableColumns, repeat (each J).TableColumns) -> (C1, C2, repeat each C3)
  ) -> Self where Joins == (repeat each J) {
    _group(by: grouping)
  }

  /// Creates a new select statement from this one by appending the given column to its `GROUP BY`
  /// clause.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this select's tables.
  /// - Returns: A new select statement that groups by the given column.
  public func group<C: QueryExpression>(
    by grouping: (From.TableColumns, Joins.TableColumns) -> C
  ) -> Self where Joins: Table {
    _group(by: grouping)
  }

  /// Creates a new select statement from this one by appending the given columns to its `GROUP BY`
  /// clause.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this select's tables.
  /// - Returns: A new select statement that groups by the given column.
  public func group<
    C1: QueryExpression,
    C2: QueryExpression,
    each C3: QueryExpression
  >(
    by grouping: (From.TableColumns, Joins.TableColumns) -> (C1, C2, repeat each C3)
  ) -> Self where Joins: Table {
    _group(by: grouping)
  }

  private func _group<
    each C: QueryExpression,
    each J: Table
  >(
    by grouping: (From.TableColumns, repeat (each J).TableColumns) -> (repeat each C)
  ) -> Self where Joins == (repeat each J) {
    var select = self
    select.group
      .append(
        contentsOf: Array(repeat each grouping(From.columns, repeat (each J).columns))
      )
    return select
  }

  private func _group<each C: QueryExpression>(
    by grouping: (From.TableColumns, Joins.TableColumns) -> (repeat each C)
  ) -> Self where Joins: Table {
    var select = self
    select.group
      .append(
        contentsOf: Array(repeat each grouping(From.columns, Joins.columns))
      )
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `HAVING` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this select's
  ///   tables.
  /// - Returns: A new select statement that appends the given predicate to its `HAVING` clause.
  @_disfavoredOverload
  public func having<each J: Table>(
    _ predicate: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<
      some _OptionalPromotable<Bool?>
    >
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.having.append(predicate(From.columns, repeat (each J).columns).queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `HAVING` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `HAVING` clause.
  public func having<each J: Table>(
    @QueryFragmentBuilder<Bool>
    _ predicate: (From.TableColumns, repeat (each J).TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.having.append(contentsOf: predicate(From.columns, repeat (each J).columns))
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `HAVING` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this select's
  ///   tables.
  /// - Returns: A new select statement that appends the given predicate to its `HAVING` clause.
  @_disfavoredOverload
  public func having(
    _ predicate: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<
      some _OptionalPromotable<Bool?>
    >
  ) -> Self
  where Joins: Table {
    var select = self
    select.having.append(predicate(From.columns, Joins.columns).queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `HAVING` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `HAVING` clause.
  public func having(
    @QueryFragmentBuilder<Bool>
    _ predicate: (From.TableColumns, Joins.TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins: Table {
    var select = self
    select.having.append(contentsOf: predicate(From.columns, Joins.columns))
    return select
  }

  /// Creates a new select statement from this one by appending a column to its `ORDER BY` clause.
  ///
  /// - Parameter ordering: A key path to a column to order by.
  /// - Returns: A new select statement that appends the given column to its `ORDER BY` clause.
  public func order(by ordering: KeyPath<From.TableColumns, some QueryExpression>) -> Self {
    var select = self
    select.order.append(From.columns[keyPath: ordering].queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending columns to its `ORDER BY` clause.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A new select statement that appends the returned columns to its `ORDER BY` clause.
  public func order<each J: Table>(
    @QueryFragmentBuilder<()>
    by ordering: (From.TableColumns, repeat (each J).TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.order.append(contentsOf: ordering(From.columns, repeat (each J).columns))
    return select
  }

  /// Creates a new select statement from this one by appending columns to its `ORDER BY` clause.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A new select statement that appends the returned columns to its `ORDER BY` clause.
  public func order(
    @QueryFragmentBuilder<()>
    by ordering: (From.TableColumns, Joins.TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins: Table {
    var select = self
    select.order.append(contentsOf: ordering(From.columns, Joins.columns))
    return select
  }

  /// Creates a new select statement from this one by overriding its `LIMIT` and `OFFSET` clauses.
  ///
  /// - Parameters:
  ///   - maxLength: A closure that produces a `LIMIT` expression from this select's tables.
  ///   - offset: A closure that produces an `OFFSET` expression from this select's tables.
  /// - Returns: A new select statement that overrides this one's `LIMIT` and `OFFSET` clauses.
  public func limit<each J: Table>(
    _ maxLength: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<Int>,
    offset: ((From.TableColumns, repeat (each J).TableColumns) -> any QueryExpression<Int>)? = nil
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.limit = _LimitClause(
      maxLength: maxLength(From.columns, repeat (each J).columns).queryFragment,
      offset: offset?(From.columns, repeat (each J).columns).queryFragment ?? select.limit?.offset
    )
    return select
  }

  /// Creates a new select statement from this one by overriding its `LIMIT` and `OFFSET` clauses.
  ///
  /// - Parameters:
  ///   - maxLength: A closure that produces a `LIMIT` expression from this select's tables.
  ///   - offset: A closure that produces an `OFFSET` expression from this select's tables.
  /// - Returns: A new select statement that overrides this one's `LIMIT` and `OFFSET` clauses.
  public func limit(
    _ maxLength: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<Int>,
    offset: ((From.TableColumns, Joins.TableColumns) -> any QueryExpression<Int>)? = nil
  ) -> Self
  where Joins: Table {
    var select = self
    select.limit = _LimitClause(
      maxLength: maxLength(From.columns, Joins.columns).queryFragment,
      offset: offset?(From.columns, Joins.columns).queryFragment ?? select.limit?.offset
    )
    return select
  }

  /// Creates a new select statement from this one by overriding its `LIMIT` and `OFFSET` clauses.
  ///
  /// - Parameters:
  ///   - maxLength: An integer limit for the select's `LIMIT` clause.
  ///   - offset: An optional integer offset of the select's `OFFSET` clause.
  /// - Returns: A new select statement that overrides this one's `LIMIT` and `OFFSET` clauses.
  public func limit<each J: Table>(_ maxLength: Int, offset: Int? = nil) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.limit = _LimitClause(
      maxLength: maxLength.queryFragment,
      offset: offset?.queryFragment ?? select.limit?.offset
    )
    return select
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count<each J: Table>(
    filter: ((From.TableColumns, repeat (each J).TableColumns) -> any QueryExpression<Bool>)? = nil
  ) -> Select<Int, From, (repeat each J)>
  where Columns == (), Joins == (repeat each J) {
    let filter = filter?(From.columns, repeat (each J).columns)
    return select { _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count<each C: QueryRepresentable, each J: Table>(
    filter: ((From.TableColumns, repeat (each J).TableColumns) -> any QueryExpression<Bool>)? = nil
  ) -> Select<
    (repeat each C, Int), From, (repeat each J)
  >
  where Columns == (repeat each C), Joins == (repeat each J) {
    let filter = filter?(From.columns, repeat (each J).columns)
    return select { _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count(
    filter: ((From.TableColumns, Joins.TableColumns) -> any QueryExpression<Bool>)? = nil
  ) -> Select<Int, From, Joins>
  where Columns == (), Joins: Table {
    let filter = filter?(From.columns, Joins.columns)
    return select { _, _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count<each C: QueryRepresentable>(
    filter: ((From.TableColumns, Joins.TableColumns) -> any QueryExpression<Bool>)? = nil
  ) -> Select<
    (repeat each C, Int), From, Joins
  >
  where Columns == (repeat each C), Joins: Table {
    let filter = filter?(From.columns, Joins.columns)
    return select { _, _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by transforming its selected columns to a new
  /// selection.
  ///
  /// - Parameter transform: A mapping closure. Accepts a tuple of selected columns and returns a
  ///   transformed selection.
  /// - Returns: A new select statement that selects the result of the transformation.
  public func map<each C1: QueryRepresentable, each C2: QueryExpression>(
    _ transform: (repeat SQLQueryExpression<each C1>) -> (repeat each C2)
  ) -> Select<(repeat (each C2).QueryValue), From, Joins>
  where
    QueryValue == (repeat each C1),
    repeat (each C2).QueryValue: QueryRepresentable
  {
    var iterator = columns.makeIterator()
    func next<Element>() -> SQLQueryExpression<Element> {
      SQLQueryExpression(iterator.next()!)
    }
    return Select<(repeat (each C2).QueryValue), From, Joins>(
      isEmpty: isEmpty,
      distinct: distinct,
      columns: Array(repeat each transform(repeat { _ in next() }((each C1).self))),
      joins: joins,
      where: `where`,
      group: group,
      having: having,
      order: order,
      limit: limit
    )
  }

  /// Returns a fully unscoped version of this select statement.
  public var unscoped: Where<From> {
    From.unscoped
  }

  /// Returns this select statement unchanged.
  public var all: Self {
    self
  }

  /// Returns an empty select statement.
  public var none: Self {
    var select = self
    select.isEmpty = true
    return select
  }
}

/// Combines two select statements of the same table type together.
///
/// This operator combines two select statements of the same table type together by combining
/// each of their clauses together.
///
/// - Parameters:
///   - lhs: A select statement.
///   - rhs: Another select statement of the same table type.
/// - Returns: A new select statement combining the clauses of each select statement.
public func + <
  each C1: QueryRepresentable,
  each C2: QueryRepresentable,
  From: Table,
  each J1: Table,
  each J2: Table
>(
  // TODO: Report issue to Swift team. Using 'some' crashes the compiler.
  lhs: any SelectStatement<(repeat each C1), From, (repeat each J1)>,
  rhs: any SelectStatement<(repeat each C2), From, (repeat each J2)>
) -> Select<
  (repeat each C1, repeat each C2), From, (repeat each J1, repeat each J2)
> {
  let lhs = lhs.asSelect()
  let rhs = rhs.asSelect()
  return Select<
    (repeat each C1, repeat each C2), From, (repeat each J1, repeat each J2)
  >(
    isEmpty: lhs.isEmpty || rhs.isEmpty,
    distinct: lhs.distinct || rhs.distinct,
    columns: lhs.columns + rhs.columns,
    joins: lhs.joins + rhs.joins,
    where: (lhs.where + rhs.where).removingDuplicates(),
    group: (lhs.group + rhs.group).removingDuplicates(),
    having: (lhs.having + rhs.having).removingDuplicates(),
    order: (lhs.order + rhs.order).removingDuplicates(),
    limit: rhs.limit ?? lhs.limit
  )
}

@TaskLocal public var _isSelecting = false

extension Select: SelectStatement {
  public typealias QueryValue = Columns

  public var _selectClauses: _SelectClauses {
    clauses
  }

  public var query: QueryFragment {
    guard !isEmpty else { return "" }
    var query: QueryFragment = "SELECT"
    let columns =
      columns.isEmpty
      ? [From.columns.queryFragment] + joins.map { $0.tableColumns }
      : columns
    if distinct {
      query.append(" DISTINCT")
    }
    query.append(" \(columns.joined(separator: ", "))")
    query.append("\(.newlineOrSpace)FROM ")
    if let schemaName = From.schemaName {
      query.append("\(quote: schemaName).")
    }
    query.append(From.tableFragment)
    if let tableAlias = From.tableAlias {
      query.append(" AS \(quote: tableAlias)")
    }
    for join in joins {
      query.append("\(.newlineOrSpace)\(join)")
    }
    if !`where`.isEmpty {
      query.append("\(.newlineOrSpace)WHERE \(`where`.joined(separator: " AND "))")
    }
    if !group.isEmpty {
      query.append("\(.newlineOrSpace)GROUP BY \(group.joined(separator: ", "))")
    }
    if !having.isEmpty {
      query.append("\(.newlineOrSpace)HAVING \(having.joined(separator: " AND "))")
    }
    if !order.isEmpty {
      query.append("\(.newlineOrSpace)ORDER BY \(order.joined(separator: ", "))")
    }
    if let limit {
      query.append("\(.newlineOrSpace)\(limit)")
    }
    return query
  }
}

public typealias SelectOf<From: Table, each Join: Table> =
  Select<(), From, (repeat each Join)>

public struct _JoinClause: QueryExpression, Sendable {
  public typealias QueryValue = Never

  struct Operator {
    static let full = Self(queryFragment: "FULL")
    static let inner = Self(queryFragment: "INNER")
    static let left = Self(queryFragment: "LEFT")
    static let right = Self(queryFragment: "RIGHT")
    let queryFragment: QueryFragment
  }

  let constraint: QueryFragment
  let `operator`: QueryFragment?
  let tableAlias: String?
  let tableColumns: QueryFragment
  let tableName: QueryFragment

  init(
    operator: Operator?,
    table: any Table.Type,
    constraint: some QueryExpression<Bool>
  ) {
    self.constraint = constraint.queryFragment
    self.operator = `operator`?.queryFragment
    tableAlias = table.tableAlias
    tableColumns = table.columns.queryFragment
    tableName = table.tableFragment
  }

  public var queryFragment: QueryFragment {
    var query: QueryFragment = ""
    if let `operator` {
      query.append("\(`operator`) ")
    }
    query.append("JOIN \(tableName) ")
    if let tableAlias = tableAlias {
      query.append("AS \(quote: tableAlias) ")
    }
    query.append("ON \(constraint)")
    return query
  }
}

public struct _LimitClause: QueryExpression, Sendable {
  public typealias QueryValue = Never

  let maxLength: QueryFragment
  let offset: QueryFragment?

  public var queryFragment: QueryFragment {
    var query: QueryFragment = "LIMIT \(maxLength)"
    if let offset {
      query.append(" OFFSET \(offset)")
    }
    return query
  }
}

@propertyWrapper
private struct CopyOnWrite<Value> {
  final class Storage {
    var value: Value
    init(value: Value) {
      self.value = value
    }
  }
  var storage: Storage
  init(wrappedValue: Value) {
    self.storage = Storage(value: wrappedValue)
  }
  var wrappedValue: Value {
    get { storage.value }
    set {
      if isKnownUniquelyReferenced(&storage) {
        storage.value = newValue
      } else {
        storage = Storage(value: newValue)
      }
    }
  }
}

extension CopyOnWrite: Sendable where Value: Sendable {}

extension CopyOnWrite.Storage: @unchecked Sendable where Value: Sendable {}
