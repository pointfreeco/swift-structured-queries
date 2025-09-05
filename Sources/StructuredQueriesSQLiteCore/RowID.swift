extension TableDefinition {
  /// An expression representing the table's rowid.
  ///
  /// > Note: The associated table must be a [rowid table](https://sqlite.org/rowidtable.html) or
  /// > else the query will fail.
  public var rowid: some QueryExpression<Int> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."rowid"
      """
    )
  }
}
