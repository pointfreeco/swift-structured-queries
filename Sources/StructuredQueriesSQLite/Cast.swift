import StructuredQueriesCore

extension QueryExpression where QueryValue: QueryBindable {
  public func cast<Other: SQLiteType>(
    as _: Other.Type = Other.self
  ) -> some QueryExpression<Other> {
    Cast(base: self)
  }
}

extension QueryExpression where QueryValue: QueryBindable & _OptionalProtocol {
  public func cast<Other: _OptionalPromotable & SQLiteType>(
    as _: Other.Type = Other.self
  ) -> some QueryExpression<Other._Optionalized>
  where Other._Optionalized: SQLiteType {
    Cast(base: self)
  }

  @available(
    *, deprecated, message: "Cast optional to non-optional produces invalid query expression"
  )
  public func cast<Other: SQLiteType>(
    as _: Other.Type = Other.self
  ) -> some QueryExpression<Other> {
    Cast(base: self)
  }
}

extension QueryExpression where QueryValue: SQLiteType {
  @available(*, deprecated, message: "Cast to same query value type always succeeds")
  public func cast(
    as _: QueryValue.Type = QueryValue.self
  ) -> some QueryExpression<QueryValue> {
    self
  }
}

private struct Cast<QueryValue: SQLiteType, Base: QueryExpression>: QueryExpression {
  let base: Base
  var queryFragment: QueryFragment {
    "CAST(\(base.queryFragment) AS \(QueryValue.typeAffinity.rawValue))"
  }
}