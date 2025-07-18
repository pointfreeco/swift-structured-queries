extension PartialSelectStatement {
  /// Creates a compound select statement from the union of this select statement and another.
  ///
  /// The operation combines two select statements together as a compound select statement using
  /// the `UNION` (or `UNION ALL`) operators.
  ///
  /// - Parameters:
  ///   - all: Use the `UNION ALL` operator instead of `UNION`.
  ///   - other: Another select statement with the same selected column types.
  /// - Returns: A compound select statement.
  public func union(
    all: Bool = false,
    _ other: some PartialSelectStatement<QueryValue>
  ) -> some PartialSelectStatement<QueryValue> {
    CompoundSelect(lhs: self, operator: all ? .unionAll : .union, rhs: other)
  }

  /// Creates a compound select statement from the intersection of this select statement and
  /// another.
  ///
  /// The operation combines two select statements together as a compound select statement using
  /// the `INTERSECT` operator.
  ///
  /// - Parameter other: Another select statement with the same selected column types.
  /// - Returns: A compound select statement.
  public func intersect<F, J>(
    _ other: some SelectStatement<QueryValue, F, J>
  ) -> some PartialSelectStatement<QueryValue> {
    CompoundSelect(lhs: self, operator: .intersect, rhs: other)
  }

  /// Creates a compound select statement from this select statement and the subtraction of another.
  ///
  /// The operation combines two select statements together as a compound select statement using
  /// the `EXCEPT` operator.
  ///
  /// - Parameter other: Another select statement with the same selected column types.
  /// - Returns: A compound select statement.
  public func except<F, J>(
    _ other: some SelectStatement<QueryValue, F, J>
  ) -> some PartialSelectStatement<QueryValue> {
    CompoundSelect(lhs: self, operator: .except, rhs: other)
  }
}

private struct CompoundSelect<QueryValue>: PartialSelectStatement {
  typealias From = Never
  typealias Joins = Never

  struct Operator {
    static var except: Self { Self(queryFragment: "EXCEPT") }
    static var intersect: Self { Self(queryFragment: "INTERSECT") }
    static var union: Self { Self(queryFragment: "UNION") }
    static var unionAll: Self { Self(queryFragment: "UNION ALL") }
    let queryFragment: QueryFragment
  }

  let lhs: QueryFragment
  let `operator`: QueryFragment
  let rhs: QueryFragment

  init(lhs: some PartialSelectStatement, operator: Operator, rhs: some PartialSelectStatement) {
    self.lhs = lhs.query
    self.operator = `operator`.queryFragment
    self.rhs = rhs.query
  }

  var query: QueryFragment {
    guard !lhs.isEmpty else { return rhs }
    guard !rhs.isEmpty else { return lhs }
    return "\(lhs)\(.newlineOrSpace)\(`operator`.indented())\(.newlineOrSpace)\(rhs)"
  }
}
