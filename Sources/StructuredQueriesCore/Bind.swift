/// A query expression of a statement binding.
///
/// It is not common to interact with this type directly. A value of this type is returned from the
/// `#bind` macro.
public struct BindQueryExpression<QueryValue: QueryRepresentable & QueryExpression>: QueryExpression
{
  public let base: QueryValue

  public init(
    _ queryOutput: QueryValue.QueryOutput,
    as queryValueType: QueryValue.Type = QueryValue.self
  ) {
    self.base = QueryValue(queryOutput: queryOutput)
  }

  public var queryFragment: QueryFragment {
    base.queryFragment
  }
}
