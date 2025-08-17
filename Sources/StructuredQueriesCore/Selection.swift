public protocol Selection: QueryRepresentable {
  associatedtype Columns: SelectedColumns<Self>
}

public protocol SelectedColumns<QueryValue>: QueryExpression {
  var selection: [(aliasName: String, expression: QueryFragment)] { get }
}

extension SelectedColumns {
  public var queryFragment: QueryFragment {
    selection.map { "\($1) AS \(quote: $0)" as QueryFragment }.joined(separator: ", ")
  }
}
