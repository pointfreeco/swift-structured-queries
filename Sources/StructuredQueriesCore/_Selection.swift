public protocol _Selection: QueryRepresentable {
  associatedtype Columns: _SelectedColumns<Self>
}

public protocol _SelectedColumns<QueryValue>: QueryExpression {
  var selection: [(aliasName: String, expression: QueryFragment)] { get }
}

extension _SelectedColumns {
  public var queryFragment: QueryFragment {
    selection.map {
      // Avoid aliasing fragments comprising multiple
      // columns
      //
      // Atomic unit of a fragment seems to comprise 3 segments
      // (e.g. [.sql("table"), .sql("."), .sql("column")].
      $1.segments.count <= 3
        ? "\($1) AS \(quote: $0)" as QueryFragment
        : $1
    }.joined(separator: ", ")
  }
}
