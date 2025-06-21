/// A builder of query fragments.
///
/// This result builder is used by various query building methods, like ``Select/order(by:)`` and
/// ``Select/where(_:)-5pthx``, to conditionally introduce query fragments to a query.
@resultBuilder
public enum QueryFragmentBuilder<Clause> {
  public static func buildBlock(_ component: [QueryFragment]) -> [QueryFragment] {
    component
  }

  public static func buildEither(first component: [QueryFragment]) -> [QueryFragment] {
    component
  }

  public static func buildEither(second component: [QueryFragment]) -> [QueryFragment] {
    component
  }

  public static func buildOptional(_ component: [QueryFragment]?) -> [QueryFragment] {
    component ?? []
  }
}

extension QueryFragmentBuilder<Bool> {
  public static func buildExpression(
    _ expression: some QueryExpression<Bool>
  ) -> [QueryFragment] {
    [expression.queryFragment]
  }

  public static func buildExpression(
    _ expression: some QueryExpression<some _OptionalPromotable<Bool?>>
  ) -> [QueryFragment] {
    [expression.queryFragment]
  }
}

extension QueryFragmentBuilder<()> {
  public static func buildExpression<each C: QueryExpression>(
    _ expression: (repeat each C)
  ) -> [QueryFragment] {
    Array(repeat each expression)
  }
}

extension QueryFragmentBuilder<any Statement> {
  public static func buildExpression(
    _ expression: some Statement
  ) -> [QueryFragment] {
    [expression.query]
  }

  public static func buildBlock(
    _ first: [QueryFragment],
    _ rest: [QueryFragment]...
  ) -> [QueryFragment] {
    first + rest.flatMap(\.self)
  }
}
