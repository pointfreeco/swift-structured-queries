extension RangeReplaceableCollection {
  package init<each Q: QueryExpression>(_ elements: repeat each Q)
  where Element == QueryFragment {
    self.init()
    for element in repeat each elements {
      append(element.queryFragment)
    }
  }

  package init<each Q: QueryExpression>(_ elements: repeat each Q)
  where Element == any QueryExpression & Sendable {
    self.init()
    for element in repeat each elements {
      append(SQLQueryExpression(element))
    }
  }

  func removingDuplicates() -> Self where Element: Hashable {
    var set: Set<Element> = []
    return filter { set.insert($0).inserted }
  }
}
