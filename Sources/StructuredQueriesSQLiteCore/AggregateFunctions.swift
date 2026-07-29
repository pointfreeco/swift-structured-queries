public import StructuredQueriesCore

extension QueryExpression where QueryValue: QueryBindable {
  /// A count aggregate of this expression, with a `FILTER` clause.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A count aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func count(
    distinct isDistinct: Bool = false,
    filter: some QueryExpression<Bool>
  ) -> some QueryExpression<Int> {
    AggregateFunctionExpression<Int>(
      "count", isDistinct: isDistinct, [queryFragment], filter: filter.queryFragment
    )
  }
}

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped == String {
  /// A string concatenation aggregate of this expression, with a `FILTER` clause.
  ///
  /// - Parameters:
  ///   - separator: A string to insert between each of the results in a group.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A string concatenation aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func groupConcat(
    _ separator: (some QueryExpression)? = String?.none,
    filter: some QueryExpression<Bool>
  ) -> some QueryExpression<String?> {
    _groupConcat(separator, order: nil, filter: filter.queryFragment)
  }

  /// A string concatenation aggregate of this expression, with an `ORDER BY` clause.
  ///
  /// - Parameters:
  ///   - separator: A string to insert between each of the results in a group.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A string concatenation aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public func groupConcat(
    _ separator: (some QueryExpression)? = String?.none,
    order: some QueryExpression,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<String?> {
    _groupConcat(separator, order: order.queryFragment, filter: filter?.queryFragment)
  }

  /// A string concatenation aggregate of this expression, with a `FILTER` clause.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A string concatenation aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func groupConcat(
    distinct isDistinct: Bool,
    filter: some QueryExpression<Bool>
  ) -> some QueryExpression<String?> {
    AggregateFunctionExpression<String?>(
      "group_concat", isDistinct: isDistinct, [queryFragment], filter: filter.queryFragment
    )
  }

  /// A string concatenation aggregate of this expression, with an `ORDER BY` clause.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A string concatenation aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public func groupConcat(
    distinct isDistinct: Bool,
    order: some QueryExpression,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<String?> {
    AggregateFunctionExpression<String?>(
      "group_concat",
      isDistinct: isDistinct,
      [queryFragment],
      order: order.queryFragment,
      filter: filter?.queryFragment
    )
  }

  fileprivate func _groupConcat(
    _ separator: (some QueryExpression)?,
    order: QueryFragment?,
    filter: QueryFragment?
  ) -> AggregateFunctionExpression<String?> {
    AggregateFunctionExpression(
      "group_concat",
      separator.map { [queryFragment, $0.queryFragment] } ?? [queryFragment],
      order: order,
      filter: filter
    )
  }
}

extension QueryExpression where QueryValue: QueryBindable & _OptionalPromotable {
  /// A maximum aggregate of this expression, with a `FILTER` clause.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A maximum aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func max(
    filter: some QueryExpression<Bool>
  ) -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
    AggregateFunctionExpression<QueryValue._Optionalized.Wrapped?>(
      "max", [queryFragment], filter: filter.queryFragment
    )
  }

  /// A minimum aggregate of this expression, with a `FILTER` clause.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A minimum aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func min(
    filter: some QueryExpression<Bool>
  ) -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
    AggregateFunctionExpression<QueryValue._Optionalized.Wrapped?>(
      "min", [queryFragment], filter: filter.queryFragment
    )
  }
}

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped: Numeric {
  /// An average aggregate of this expression, with a `FILTER` clause.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: An average aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func avg(
    distinct isDistinct: Bool = false,
    filter: some QueryExpression<Bool>
  ) -> some QueryExpression<Double?> {
    AggregateFunctionExpression<Double?>(
      "avg", isDistinct: isDistinct, [queryFragment], filter: filter.queryFragment
    )
  }

  /// A sum aggregate of this expression, with a `FILTER` clause.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A sum aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func sum(
    distinct isDistinct: Bool = false,
    filter: some QueryExpression<Bool>
  ) -> SQLQueryExpression<QueryValue._Optionalized> {
    // NB: We must explicitly erase here to avoid a runtime crash with opaque return types
    // TODO: Report issue to Swift team.
    SQLQueryExpression(
      AggregateFunctionExpression<QueryValue._Optionalized>(
        "sum", isDistinct: isDistinct, [queryFragment], filter: filter.queryFragment
      )
      .queryFragment
    )
  }

  /// A total aggregate of this expression, with a `FILTER` clause.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A total aggregate of this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func total(
    distinct isDistinct: Bool = false,
    filter: some QueryExpression<Bool>
  ) -> some QueryExpression<QueryValue> {
    AggregateFunctionExpression<QueryValue>(
      "total", isDistinct: isDistinct, [queryFragment], filter: filter.queryFragment
    )
  }
}

extension QueryExpression where Self == AggregateFunctionExpression<Int> {
  /// A `count(*)` aggregate, with a `FILTER` clause.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A `count(*)` aggregate.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public static func count(filter: any QueryExpression<Bool>) -> Self {
    AggregateFunctionExpression("count", ["*"], filter: filter.queryFragment)
  }
}

extension PrimaryKeyedTableDefinition where PrimaryColumn: TableColumnExpression {
  /// A query expression representing the number of rows in this table, with a `FILTER` clause.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: An expression representing the number of rows in this table.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func count(
    distinct isDistinct: Bool = false,
    filter: some QueryExpression<Bool>
  ) -> some QueryExpression<Int> {
    primaryKey.count(distinct: isDistinct, filter: filter)
  }
}

extension Table {
  /// A select statement for this table's row count, with a `FILTER` clause.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects `count(*)`.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public static func count(
    filter: @escaping (TableColumns) -> any QueryExpression<Bool>
  ) -> Select<Int, Self, ()> {
    Where().count(filter: filter)
  }
}

extension Where {
  /// A select statement for the filtered table's row count, with a `FILTER` clause.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects `count(*)`.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func count(
    filter: (From.TableColumns) -> any QueryExpression<Bool>
  ) -> Select<Int, From, ()> {
    asSelect().count(filter: filter)
  }
}

extension Select {
  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func count<each J: Table>(
    filter: (From.TableColumns, repeat (each J).TableColumns) -> any QueryExpression<Bool>
  ) -> Select<Int, From, Joins>
  where Columns == (), Joins == (repeat each J) {
    let filter = filter(From.columns, repeat (each J).columns)
    return select { _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func count<each C: QueryRepresentable, each J: Table>(
    filter: (From.TableColumns, repeat (each J).TableColumns) -> any QueryExpression<Bool>
  ) -> Select<
    (repeat each C, Int), From, (repeat each J)
  >
  where Columns == (repeat each C), Joins == (repeat each J) {
    let filter = filter(From.columns, repeat (each J).columns)
    return select { _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func count(
    filter: (From.TableColumns, Joins.TableColumns) -> any QueryExpression<Bool>
  ) -> Select<Int, From, Joins>
  where Columns == (), Joins: Table {
    let filter = filter(From.columns, Joins.columns)
    return select { _, _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  #endif
  public func count<each C: QueryRepresentable>(
    filter: (From.TableColumns, Joins.TableColumns) -> any QueryExpression<Bool>
  ) -> Select<
    (repeat each C, Int), From, Joins
  >
  where Columns == (repeat each C), Joins: Table {
    let filter = filter(From.columns, Joins.columns)
    return select { _, _ in .count(filter: filter) }
  }
}
