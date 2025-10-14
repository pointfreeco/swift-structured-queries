extension QueryExpression where QueryValue: QueryBindable {
  /// A count aggregate of this expression.
  ///
  /// Counts the number of non-`NULL` times the expression appears in a group.
  ///
  /// ```swift
  /// Reminder.select { $0.id.count() }
  /// // SELECT count("reminders"."id") FROM "reminders"
  ///
  /// Reminder.select { $0.title.count(distinct: true) }
  /// // SELECT count(DISTINCT "reminders"."title") FROM "reminders"
  /// ```
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A count aggregate of this expression.
  public func count(
    distinct isDistinct: Bool = false,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<Int> {
    AggregateFunctionExpression(
      "count",
      isDistinct: isDistinct,
      [queryFragment],
      filter: filter?.queryFragment
    )
  }
}

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped == String {
  /// A string concatenation aggregate of this expression
  ///
  /// Concatenates all of the non-`NULL` strings in a group.
  ///
  /// ```swift
  /// Reminder.select { $0.title.groupConcat() }
  /// // SELECT group_concat("reminders"."title") FROM "reminders"
  /// ```
  ///
  /// - Parameters:
  ///   - separator: A string to insert between each of the results in a group. The default
  ///     separator is a comma.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A string concatenation aggregate of this expression.
  public func groupConcat(
    _ separator: (some QueryExpression)? = String?.none,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<String?> {
    AggregateFunctionExpression(
      "group_concat",
      separator.map { [queryFragment, $0.queryFragment] } ?? [queryFragment],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }

  /// A string concatenation aggregate of this expression.
  ///
  /// See ``groupConcat(_:order:filter:)`` for more.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A string concatenation aggregate of this expression.
  public func groupConcat(
    distinct isDistinct: Bool,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<String?> {
    AggregateFunctionExpression(
      "group_concat",
      isDistinct: isDistinct,
      [queryFragment],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }
}

extension QueryExpression where QueryValue: QueryBindable & _OptionalPromotable {
  /// A maximum aggregate of this expression.
  ///
  /// ```swift
  /// Reminder.select { $0.date.max() }
  /// // SELECT max("reminders"."date") FROM "reminders"
  /// ```
  ///
  /// - Parameters filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A maximum aggregate of this expression.
  public func max(
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
    AggregateFunctionExpression("max", [queryFragment], filter: filter?.queryFragment)
  }

  /// A minimum aggregate of this expression.
  ///
  /// ```swift
  /// Reminder.select { $0.date.max() }
  /// // SELECT min("reminders"."date") FROM "reminders"
  /// ```
  ///
  /// - Parameters filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A minimum aggregate of this expression.
  public func min(
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
    AggregateFunctionExpression("min", [queryFragment], filter: filter?.queryFragment)
  }
}

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped: Numeric {
  /// An average aggregate of this expression.
  ///
  /// ```swift
  /// Reminder.select { $0.date.max() }
  /// // SELECT min("reminders"."date") FROM "reminders"
  /// ```
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: An average aggregate of this expression.
  public func avg(
    distinct isDistinct: Bool = false,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<Double?> {
    AggregateFunctionExpression("avg", isDistinct: isDistinct, [queryFragment], filter: filter?.queryFragment)
  }

  /// An sum aggregate of this expression.
  ///
  /// ```swift
  /// Item.select { $0.quantity.sum() }
  /// // SELECT sum("items"."quantity") FROM "items"
  /// ```
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A sum aggregate of this expression.
  public func sum(
    distinct isDistinct: Bool = false,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> SQLQueryExpression<QueryValue._Optionalized> {
    // NB: We must explicitly erase here to avoid a runtime crash with opaque return types
    // TODO: Report issue to Swift team.
    SQLQueryExpression(
      AggregateFunctionExpression<QueryValue._Optionalized>(
        "sum",
        isDistinct: isDistinct,
        [queryFragment],
        filter: filter?.queryFragment
      )
      .queryFragment
    )
  }

  /// An total aggregate of this expression.
  ///
  /// ```swift
  /// Item.select { $0.price.total() }
  /// // SELECT total("items"."price") FROM "items"
  /// ```
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A total aggregate of this expression.
  public func total(
    distinct isDistinct: Bool = false,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<QueryValue> {
    AggregateFunctionExpression(
      "total",
      isDistinct: isDistinct,
      [queryFragment],
      filter: filter?.queryFragment
    )
  }
}

extension QueryExpression where Self == AggregateFunctionExpression<Int> {
  /// A `count(*)` aggregate.
  ///
  /// ```swift
  /// Reminder.select { .count() }
  /// // SELECT count(*) FROM "reminders"
  /// ```
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A `count(*)` aggregate.
  public static func count(
    filter: (any QueryExpression<Bool>)? = nil
  ) -> Self {
    AggregateFunctionExpression("count", ["*"], filter: filter?.queryFragment)
  }
}

/// A query expression of an aggregate function.
public struct AggregateFunctionExpression<QueryValue>: QueryExpression, Sendable {
  var name: QueryFragment
  var isDistinct: Bool
  var arguments: [QueryFragment]
  var order: QueryFragment?
  var filter: QueryFragment?

  public init<each Argument: QueryExpression>(
    _ name: String,
    distinct isDistinct: Bool = false,
    _ arguments: repeat each Argument,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) {
    self.init(
      QueryFragment(quote: name),
      isDistinct: isDistinct,
      Array(repeat each arguments),
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }

  package init(
    _ name: QueryFragment,
    isDistinct: Bool = false,
    _ arguments: [QueryFragment] = [],
    order: QueryFragment? = nil,
    filter: QueryFragment? = nil
  ) {
    self.name = name
    self.isDistinct = isDistinct
    self.arguments = arguments
    self.order = order
    self.filter = filter
  }

  public var queryFragment: QueryFragment {
    var query: QueryFragment = "\(name)("
    if isDistinct {
      query.append("DISTINCT ")
    }
    query.append(arguments.joined(separator: ", "))
    if let order {
      query.append(" ORDER BY \(order)")
    }
    query.append(")")
    if let filter {
      query.append(" FILTER (WHERE \(filter))")
    }
    return query
  }
}
