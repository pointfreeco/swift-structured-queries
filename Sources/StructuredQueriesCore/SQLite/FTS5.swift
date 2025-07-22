public protocol FTS5: Table {}

extension TableDefinition where QueryValue: FTS5 {
  public var rank: some QueryExpression<Double?> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."rank"
      """
    )
  }

  public func match(_ pattern: some QueryExpression<String>) -> some QueryExpression<Bool> {
    SQLQueryExpression(
      """
      (\(QueryValue.self) MATCH \(pattern))
      """
    )
  }
}

extension TableColumnExpression where Root: FTS5 {
  public func highlight(
    _ open: String,
    _ close: String
  ) -> some QueryExpression<String> {
    SQLQueryExpression(
      """
      highlight(\
      \(Root.self), \
      (\
      SELECT "cid" FROM pragma_table_info(\(quote: Root.tableName, delimiter: .text)) \
      WHERE "name" = \(quote: name, delimiter: .text)\
      ),
      \(quote: open, delimiter: .text), \
      \(quote: close, delimiter: .text)\
      )
      """
    )
  }
}
