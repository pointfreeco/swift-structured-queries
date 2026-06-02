import StructuredQueries

struct SimpleSelect<QueryValue>: PartialSelectStatement {
  typealias From = Never

  var query: QueryFragment

  init(
    _ selection: () -> some QueryExpression<QueryValue>
  ) where QueryValue: QueryRepresentable {
    query = "SELECT \(selection().queryFragment)"
  }

  @_disfavoredOverload
  init<each C: QueryExpression>(
    _ selection: () -> (repeat each C)
  )
  where
    repeat (each C).QueryValue: QueryRepresentable,
    QueryValue == (repeat (each C).QueryValue)
  {
    let columns = [QueryFragment](repeat each selection())
    query = "SELECT \(columns.joined(separator: ", "))"
  }
}
