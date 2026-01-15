extension QueryExpression where QueryValue: QueryBindable {
  /// This expression with an ascending ordering term.
  ///
  /// - Parameter nullOrdering: `NULL`-specific ordering.
  /// - Returns: An ascending ordering of this expression.
  public func asc(nulls nullOrdering: NullOrdering? = nil) -> some QueryExpression {
    OrderingTerm(base: self, direction: .asc, nullOrdering: nullOrdering)
  }

  /// This expression with a descending ordering term.
  ///
  /// - Parameter nullOrdering: `NULL`-specific ordering.
  /// - Returns: A descending ordering of this expression.
  public func desc(nulls nullOrdering: NullOrdering? = nil) -> some QueryExpression {
    OrderingTerm(base: self, direction: .desc, nullOrdering: nullOrdering)
  }
}

/// `NULL`-specific ordering for an ordering term.
public struct NullOrdering: RawRepresentable, Sendable {
  /// A null ordering of `NULLS FIRST`.
  public static let first = Self(rawValue: "FIRST")

  /// A null ordering of `NULLS LAST`.
  public static let last = Self(rawValue: "LAST")

  public let rawValue: QueryFragment

  public init(rawValue: QueryFragment) {
    self.rawValue = rawValue
  }
}

private struct OrderingTerm: QueryExpression {
  typealias QueryValue = Never

  struct Direction {
    static let asc = Self(queryFragment: "ASC")
    static let desc = Self(queryFragment: "DESC")
    let queryFragment: QueryFragment
  }

  let base: QueryFragment
  let direction: Direction
  let nullOrdering: NullOrdering?

  init(base: some QueryExpression, direction: Direction, nullOrdering: NullOrdering?) {
    self.base = base.queryFragment
    self.direction = direction
    self.nullOrdering = nullOrdering
  }

  var queryFragment: QueryFragment {
    var query: QueryFragment = "\(base) \(direction.queryFragment)"
    if let nullOrdering {
      query.append(" NULLS \(nullOrdering.rawValue)")
    }
    return query
  }
}
