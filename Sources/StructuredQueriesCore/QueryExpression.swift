/// A type that represents a full or partial SQL query.
public protocol QueryExpression<QueryValue> {
  /// The Swift data type representation of the expression's SQL data type.
  ///
  /// For example, a `TEXT` expression may be represented as a `String` query value.
  ///
  /// This type is used to introduce type-safety at the query builder level.
  associatedtype QueryValue

  /// The number of columns associated with this expression.
  static var columnWidth: Int { get }

  /// The query fragment associated with this expression.
  var queryFragment: QueryFragment { get }
}

extension QueryExpression {
  public static var columnWidth: Int {
    1
  }
}
