extension Table {
  /// A where clause filtered by a Boolean key path.
  ///
  /// ```swift
  /// @Table
  /// struct User {
  ///   let id: Int
  ///   var email: String
  /// }
  ///
  /// User.where { $0.id == 1 }
  /// // WHERE ("users"."id" = 1)
  ///
  /// User.where { $0.like("%@pointfree.co") }
  /// // WHERE ("users"."email" LIKE '%@pointfree.co')
  /// ```
  ///
  /// See <doc:WhereClauses> for more.
  ///
  /// - Parameter keyPath: A key path to a Boolean expression to filter by.
  /// - Returns: A `WHERE` clause.
  public static func `where`(
    _ keyPath: KeyPath<TableColumns, some QueryExpression<Bool>>
  ) -> Where<Self> {
    Where(predicates: [columns[keyPath: keyPath].queryFragment])
  }

  /// A where clause filtered by a predicate expression.
  ///
  /// See <doc:WhereClauses> for more.
  ///
  /// - Parameter predicate: A predicate used to generate the `WHERE` clause.
  /// - Returns: A `WHERE` clause.
  @_disfavoredOverload
  public static func `where`(
    _ predicate: (TableColumns) -> some QueryExpression<Bool>
  ) -> Where<Self> {
    Where(predicates: [predicate(columns).queryFragment])
  }

  /// A where clause filtered by a predicate expression.
  ///
  /// See <doc:WhereClauses> for more.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A `WHERE` clause.
  public static func `where`(
    @QueryFragmentBuilder<Bool> _ predicate: (TableColumns) -> [QueryFragment]
  ) -> Where<Self> {
    Where(predicates: predicate(columns))
  }
}

/// A `WHERE` clause used to apply a filter to a statement.
///
/// See ``Table/where(_:)`` for how to create this type.
#if compiler(>=6.1)
  @dynamicMemberLookup
#endif
public struct Where<From: Table> {
  public static func + (lhs: Self, rhs: Self) -> Self {
    Where(predicates: (lhs.predicates + rhs.predicates).removingDuplicates())
  }

  var predicates: [QueryFragment] = []
  var unscoped = false

  #if compiler(>=6.1)
    public static subscript(dynamicMember keyPath: KeyPath<From.Type, Self>) -> Self {
      From.self[keyPath: keyPath]
    }

    public subscript<each C: QueryRepresentable, each J: Table>(
      dynamicMember keyPath: KeyPath<From.Type, Select<(repeat each C), From, (repeat each J)>>
    ) -> Select<(repeat each C), From, (repeat each J)> {
      self + From.self[keyPath: keyPath]
    }

    public subscript(dynamicMember keyPath: KeyPath<From.Type, Self>) -> Self {
      self + From.self[keyPath: keyPath]
    }
  #endif
}

extension Where: SelectStatement {
  public typealias QueryValue = ()

  public func asSelect() -> SelectOf<From> {
    (unscoped ? Select() : Select(clauses: From.all._selectClauses))
      .and(self)
  }

  public var _selectClauses: _SelectClauses {
    _SelectClauses(where: predicates)
  }

  /// A select statement for a column of the filtered table.
  ///
  /// - Parameter selection: A key path to a column to select.
  /// - Returns: A select statement that selects the given column.
  public func select<C: QueryExpression>(
    _ selection: KeyPath<From.TableColumns, C>
  ) -> Select<C.QueryValue, From, ()>
  where C.QueryValue: QueryRepresentable {
    asSelect().select(selection)
  }

  /// A select statement for a column of the filtered table.
  ///
  /// - Parameter selection: A closure that selects a result column from the filtered table.
  /// - Returns: A select statement that selects the given column.
  public func select<C: QueryExpression>(
    _ selection: (From.TableColumns) -> C
  ) -> Select<C.QueryValue, From, ()>
  where C.QueryValue: QueryRepresentable {
    asSelect().select(selection)
  }

  /// A select statement for columns of the filtered table.
  ///
  /// - Parameter selection: A closure that selects result columns from the filtered table.
  /// - Returns: A select statement that selects the given columns.
  public func select<C1: QueryExpression, C2: QueryExpression, each C3: QueryExpression>(
    _ selection: (From.TableColumns) -> (C1, C2, repeat each C3)
  ) -> Select<(C1.QueryValue, C2.QueryValue, repeat (each C3).QueryValue), From, ()>
  where
    C1.QueryValue: QueryRepresentable,
    C2.QueryValue: QueryRepresentable,
    repeat (each C3).QueryValue: QueryRepresentable
  {
    asSelect().select(selection)
  }

  /// A distinct select statement for the filtered table.
  ///
  /// - Parameter isDistinct: Whether or not to `SELECT DISTINCT`.
  /// - Returns: A select statement with a `DISTINCT` clause determined by `isDistinct`.
  public func distinct(_ isDistinct: Bool = true) -> SelectOf<From> {
    asSelect().distinct(isDistinct)
  }

  /// A select statement for the filtered table joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that joins the given table.
  public func join<each C: QueryRepresentable, F: Table, each J: Table>(
    _ other: any SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), From, (F, repeat each J)> {
    asSelect().join(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for the filtered table joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that joins the given table.
  @_documentation(visibility: private)
  public func join<each C: QueryRepresentable, F: Table>(
    _ other: any SelectStatement<(repeat each C), F, ()>,
    on constraint: ((From.TableColumns, F.TableColumns)) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), From, F> {
    asSelect().join(other, on: constraint)
  }

  /// A select statement for the filtered table left-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that left-joins the given table.
  public func leftJoin<each C: QueryRepresentable, F: Table, each J: Table>(
    _ other: any SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C)._Optionalized),
    From,
    (F._Optionalized, repeat (each J)._Optionalized)
  > {
    let joined = asSelect().leftJoin(other, on: constraint)
    return joined
  }

  // NB: Optimization
  /// A select statement for the filtered table left-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that left-joins the given table.
  @_documentation(visibility: private)
  public func leftJoin<each C: QueryRepresentable, F: Table>(
    _ other: any SelectStatement<(repeat each C), F, ()>,
    on constraint: ((From.TableColumns, F.TableColumns)) -> some QueryExpression<Bool>
  ) -> Select<(repeat (each C)._Optionalized), From, F._Optionalized> {
    asSelect().leftJoin(other, on: constraint)
  }

  /// A select statement for the filtered table right-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that right-joins the given table.
  public func rightJoin<each C: QueryRepresentable, F: Table, each J: Table>(
    _ other: any SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), From._Optionalized, (F, repeat each J)> {
    let joined = asSelect().rightJoin(other, on: constraint)
    return joined
  }

  // NB: Optimization
  /// A select statement for the filtered table right-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that right-joins the given table.
  @_documentation(visibility: private)
  public func rightJoin<each C: QueryRepresentable, F: Table>(
    _ other: any SelectStatement<(repeat each C), F, ()>,
    on constraint: ((From.TableColumns, F.TableColumns)) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), From._Optionalized, F> {
    asSelect().rightJoin(other, on: constraint)
  }

  /// A select statement for the filtered table full-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that full-joins the given table.
  public func fullJoin<each C: QueryRepresentable, F: Table, each J: Table>(
    _ other: any SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C)._Optionalized),
    From._Optionalized,
    (F._Optionalized, repeat (each J)._Optionalized)
  > {
    let joined = asSelect().fullJoin(other, on: constraint)
    return joined
  }

  // NB: Optimization
  /// A select statement for the filtered table full-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that full-joins the given table.
  @_documentation(visibility: private)
  public func fullJoin<each C: QueryRepresentable, F: Table>(
    _ other: any SelectStatement<(repeat each C), F, ()>,
    on constraint: ((From.TableColumns, F.TableColumns)) -> some QueryExpression<Bool>
  ) -> Select<(repeat (each C)._Optionalized), From._Optionalized, F._Optionalized> {
    asSelect().fullJoin(other, on: constraint)
  }

  /// Adds a condition to a where clause.
  ///
  /// ```swift
  /// extension Reminder {
  ///   static let flagged = Self.where(\.isFlagged)
  /// }
  ///
  /// Reminder.flagged.where(\.isCompleted)
  /// // WHERE "reminders"."isFlagged" AND "reminders"."isCompleted"
  /// ```
  ///
  /// - Parameter keyPath: A key path to a Boolean expression to filter by.
  /// - Returns: A where clause with the added predicate.
  public func `where`(
    _ keyPath: KeyPath<From.TableColumns, some QueryExpression<Bool>>
  ) -> Self {
    var `where` = self
    `where`.predicates.append(From.columns[keyPath: keyPath].queryFragment)
    return `where`
  }

  /// Adds a condition to a where clause.
  ///
  /// - Parameter predicate: A predicate to add.
  /// - Returns: A where clause with the added predicate.
  @_disfavoredOverload
  public func `where`(
    _ predicate: (From.TableColumns) -> some QueryExpression<Bool>
  ) -> Self {
    var `where` = self
    `where`.predicates.append(predicate(From.columns).queryFragment)
    return `where`
  }

  /// Adds a condition to a where clause.
  ///
  /// - Parameter predicate: A predicate to add.
  /// - Returns: A where clause with the added predicate.
  public func `where`(
    @QueryFragmentBuilder<Bool> _ predicate: (From.TableColumns) -> [QueryFragment]
  ) -> Self {
    var `where` = self
    `where`.predicates.append(contentsOf: predicate(From.columns))
    return `where`
  }

  /// Combines the predicates of two where clauses together using `AND`.
  ///
  /// - Parameters:
  ///   - lhs: A where clause.
  ///   - rhs: Another where clause.
  /// - Returns: A where clause that `AND`s the given where clauses together.
  public static func && (lhs: Self, rhs: Self) -> Self {
    lhs.and(rhs)
  }

  /// Combines the predicates of two where clauses together using `OR`.
  ///
  /// - Parameters:
  ///   - lhs: A where clause.
  ///   - rhs: Another where clause.
  /// - Returns: A where clause that `OR`s the given where clauses together.
  public static func || (lhs: Self, rhs: Self) -> Self {
    lhs.or(rhs)
  }

  /// Negates the predicates of a where clause using `NOT`.
  ///
  /// - Parameter where: A where clause.
  /// - Returns: A where clause that `NOT`s the given where clause.
  public static prefix func ! (where: Self) -> Self {
    `where`.not()
  }

  /// Combines the predicates of this where clause and another using `AND`.
  ///
  /// - Parameter other: Another where clause.
  /// - Returns: A where clause that `AND`s the given where clauses together.
  public func and(_ other: Self) -> Self {
    var `where` = self
    `where`.predicates = [
      """
      (\(`where`.predicates.joined(separator: " AND "))) \
      AND \
      (\(other.predicates.joined(separator: " AND ")))
      """
    ]
    return `where`
  }

  /// Combines the predicates of this where clause and another using `OR`.
  ///
  /// - Parameter other: Another where clause.
  /// - Returns: A where clause that `OR`s the given where clauses together.
  public func or(_ other: Self) -> Self {
    var `where` = self
    `where`.predicates = [
      """
      (\(`where`.predicates.joined(separator: " AND "))) \
      OR \
      (\(other.predicates.joined(separator: " AND ")))
      """
    ]
    return `where`
  }

  /// Negates the predicates of a where clause using `NOT`.
  ///
  /// - Returns: A where clause that `NOT`s this where clause.
  public func not() -> Self {
    var `where` = self
    `where`.predicates = ["NOT (\(`where`.predicates.joined(separator: " AND ")))"]
    return `where`
  }

  /// A select statement for the filtered table grouped by the given column.
  public func group<C: QueryExpression>(
    by grouping: (From.TableColumns) -> C
  ) -> Select<(), From, ()> {
    asSelect().group(by: grouping)
  }

  /// A select statement for the filtered table grouped by the given columns.
  public func group<C1: QueryExpression, C2: QueryExpression, each C3: QueryExpression>(
    by grouping: (From.TableColumns) -> (C1, C2, repeat each C3)
  ) -> SelectOf<From> {
    asSelect().group(by: grouping)
  }

  /// A select statement for the filtered table with the given `HAVING` clause.
  public func having(
    _ predicate: (From.TableColumns) -> some QueryExpression<Bool>
  ) -> SelectOf<From> {
    asSelect().having(predicate)
  }

  /// A select statement for the filtered table ordered by the given column.
  ///
  /// - Parameter ordering: A key path to a column to order by.
  /// - Returns: A select statement that is ordered by the given column.
  public func order(
    by ordering: KeyPath<From.TableColumns, some QueryExpression>
  ) -> SelectOf<From> {
    asSelect().order(by: ordering)
  }

  /// A select statement for the filtered table grouped by the given columns.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A select statement that is ordered by the given columns.
  public func order(
    @QueryFragmentBuilder<()>
    by ordering: (From.TableColumns) -> [QueryFragment]
  ) -> SelectOf<From> {
    asSelect().order(by: ordering)
  }

  /// A select statement for the filtered table with a limit and optional offset.
  ///
  /// - Parameters:
  ///   - maxLength: A closure that produces a `LIMIT` expression from this table's columns.
  ///   - offset: A closure that produces an `OFFSET` expression from this table's columns.
  /// - Returns: A select statement with a limit and optional offset.
  public func limit(
    _ maxLength: (From.TableColumns) -> some QueryExpression<Int>,
    offset: ((From.TableColumns) -> some QueryExpression<Int>)? = nil
  ) -> SelectOf<From> {
    asSelect().limit(maxLength, offset: offset)
  }

  /// A select statement for the filtered table with a limit and optional offset.
  ///
  /// - Parameters:
  ///   - maxLength: An integer limit for the select's `LIMIT` clause.
  ///   - offset: An optional integer offset of the select's `OFFSET` clause.
  /// - Returns: A select statement with a limit and optional offset.
  public func limit(_ maxLength: Int, offset: Int? = nil) -> SelectOf<From> {
    asSelect().limit(maxLength, offset: offset)
  }

  /// A select statement for the filtered table's row count.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects `count(*)`.
  public func count(
    filter: ((From.TableColumns) -> any QueryExpression<Bool>)? = nil
  ) -> Select<Int, From, ()> {
    asSelect().count(filter: filter)
  }

  /// A delete statement for the filtered table.
  public func delete() -> DeleteOf<From> {
    Delete(where: unscoped ? predicates : From.all._selectClauses.where + predicates)
  }

  /// An update statement for the filtered table.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - updates: A closure describing column-wise updates to perform.
  /// - Returns: An update statement.
  public func update(
    or conflictResolution: ConflictResolution? = nil,
    set updates: (inout Updates<From>) -> Void
  ) -> UpdateOf<From> {
    Update(
      conflictResolution: conflictResolution,
      updates: Updates(updates),
      where: unscoped ? predicates : From.all._selectClauses.where + predicates
    )
  }

  public var query: QueryFragment {
    asSelect().query
  }
}
