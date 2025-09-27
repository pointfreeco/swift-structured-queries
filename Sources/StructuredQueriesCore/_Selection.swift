public protocol _Selection: QueryRepresentable {
  associatedtype Columns: _SelectedColumns<Self>
}

public protocol _SelectedColumns<QueryValue>: QueryExpression {
  var selection: [(aliasName: String, expression: QueryFragment)] { get }
}

extension _SelectedColumns {
  public var queryFragment: QueryFragment {
    if _isSelecting {
      return selection.map { "\($1) AS \(quote: $0)" }.joined(separator: ", ")
    } else {
      return selection.map { $1 }.joined(separator: ", ")
    }
  }
}
