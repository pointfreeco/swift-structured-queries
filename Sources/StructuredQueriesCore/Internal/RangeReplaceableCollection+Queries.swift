extension RangeReplaceableCollection {
    public init<each Q: QueryExpression>(_ elements: repeat each Q)
  where Element == QueryFragment {
    self.init()
    for element in repeat each elements {
      append(element.queryFragment)
    }
  }

  public init<each Q: QueryExpression>(_ elements: repeat each Q)
  where Element == any QueryExpression {
    self.init()
    for element in repeat each elements {
      append(element)
    }
  }

  func removingDuplicates() -> Self where Element: Hashable {
    var set: Set<Element> = []
    return filter { set.insert($0).inserted }
  }
}
