/// A type that represents a full SQL query.
public protocol Statement<QueryValue>: QueryExpression {
  /// A type representing the table being queried, if any.
  associatedtype From

  /// A type representing tables joined to the ``From`` table.
  associatedtype Joins = ()

  /// A fragment representing the full query of this statement.
  var query: QueryFragment { get }
}

extension Statement {
  public var queryFragment: QueryFragment {
    "(\(.newline)\(query.indented())\(.newline))"
  }
}
