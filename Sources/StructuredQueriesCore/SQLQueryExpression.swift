/// A query expression of a raw SQL fragment.
///
/// It is not common to interact with this type directly. A value of this type is returned from the
/// `#sql` macro. See <doc:SafeSQLStrings> for more information.
public struct SQLQueryExpression<QueryValue>: Statement {
  public typealias From = Never

  public let queryFragment: QueryFragment

  public var query: QueryFragment { queryFragment }

  /// Creates a query expression from a raw SQL fragment.
  ///
  /// - Parameters:
  ///   - queryFragment: A query fragment.
  ///   - queryValueType: A type representing the query expression.
  public init(
    _ queryFragment: QueryFragment,
    as queryValueType: QueryValue.Type = QueryValue.self
  ) {
    self.queryFragment = queryFragment
  }

  /// Creates a query expression from a raw SQL fragment.
  ///
  /// - Parameter queryFragment: A query fragment.
  public init(_ queryFragment: QueryFragment) where QueryValue == () {
    self.queryFragment = queryFragment
  }

  /// Creates a type erased query expression from another query expression.
  ///
  /// - Parameter expression: A query expression.
  @_disfavoredOverload
  public init(_ expression: some QueryExpression<QueryValue>) {
    self.queryFragment = expression.queryFragment
  }

  /// Creates a type erased query expression from a statement.
  ///
  /// - Parameter statement: A statement.
  public init(_ statement: some Statement<QueryValue>) {
    self.queryFragment = statement.query
  }
}
