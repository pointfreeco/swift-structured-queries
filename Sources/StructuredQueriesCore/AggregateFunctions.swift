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
  /// - Parameter isDistinct: Whether or not to include a `DISTINCT` clause, which filters
  ///   duplicates from the aggregation.
  /// - Returns: A count aggregate of this expression.
  public func count(
    distinct isDistinct: Bool = false
  ) -> some QueryExpression<Int> {
    AggregateFunctionExpression("count", isDistinct: isDistinct, [queryFragment])
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
  /// - Parameter separator: A string to insert between each of the results in a group. The default
  ///   separator is a comma.
  /// - Returns: A string concatenation aggregate of this expression.
  public func groupConcat(
    _ separator: (some QueryExpression)? = String?.none
  ) -> some QueryExpression<String?> {
    AggregateFunctionExpression(
      "group_concat",
      separator.map { [queryFragment, $0.queryFragment] } ?? [queryFragment]
    )
  }

  /// A string concatenation aggregate of this expression.
  ///
  /// See ``groupConcat(_:)`` for more.
  ///
  /// - Parameter isDistinct: Whether or not to include a `DISTINCT` clause, which filters
  ///   duplicates from the aggregation.
  /// - Returns: A string concatenation aggregate of this expression.
  public func groupConcat(
    distinct isDistinct: Bool
  ) -> some QueryExpression<String?> {
    AggregateFunctionExpression("group_concat", isDistinct: isDistinct, [queryFragment])
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
  /// - Returns: A maximum aggregate of this expression.
  public func max() -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
    AggregateFunctionExpression("max", [queryFragment])
  }

  /// A minimum aggregate of this expression.
  ///
  /// ```swift
  /// Reminder.select { $0.date.min() }
  /// // SELECT min("reminders"."date") FROM "reminders"
  /// ```
  ///
  /// - Returns: A minimum aggregate of this expression.
  public func min() -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
    AggregateFunctionExpression("min", [queryFragment])
  }
}

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped: Numeric {
  /// An average aggregate of this expression.
  ///
  /// ```swift
  /// Item.select { $0.price.avg() }
  /// // SELECT avg("items"."price") FROM "items"
  /// ```
  ///
  /// - Parameter isDistinct: Whether or not to include a `DISTINCT` clause, which filters
  ///   duplicates from the aggregation.
  /// - Returns: An average aggregate of this expression.
  public func avg(
    distinct isDistinct: Bool = false
  ) -> some QueryExpression<Double?> {
    AggregateFunctionExpression("avg", isDistinct: isDistinct, [queryFragment])
  }

  /// A sum aggregate of this expression.
  ///
  /// ```swift
  /// Item.select { $0.quantity.sum() }
  /// // SELECT sum("items"."quantity") FROM "items"
  /// ```
  ///
  /// - Parameter isDistinct: Whether or not to include a `DISTINCT` clause, which filters
  ///   duplicates from the aggregation.
  /// - Returns: A sum aggregate of this expression.
  public func sum(
    distinct isDistinct: Bool = false
  ) -> SQLQueryExpression<QueryValue._Optionalized> {
    // NB: We must explicitly erase here to avoid a runtime crash with opaque return types
    // TODO: Report issue to Swift team.
    SQLQueryExpression(
      AggregateFunctionExpression<QueryValue._Optionalized>(
        "sum",
        isDistinct: isDistinct,
        [queryFragment]
      )
      .queryFragment
    )
  }

  /// A total aggregate of this expression.
  ///
  /// ```swift
  /// Item.select { $0.price.total() }
  /// // SELECT total("items"."price") FROM "items"
  /// ```
  ///
  /// - Parameter isDistinct: Whether or not to include a `DISTINCT` clause, which filters
  ///   duplicates from the aggregation.
  /// - Returns: A total aggregate of this expression.
  public func total(
    distinct isDistinct: Bool = false
  ) -> some QueryExpression<QueryValue> {
    AggregateFunctionExpression("total", isDistinct: isDistinct, [queryFragment])
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
  /// - Returns: A `count(*)` aggregate.
  public static func count() -> Self {
    AggregateFunctionExpression("count", ["*"])
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
