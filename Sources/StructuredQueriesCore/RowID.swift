extension TableDefinition {
  /// An expression representing the table's rowid.
  ///
  /// > Note: This is a SQLite-specific feature. The associated table must be a 
  /// > [rowid table](https://sqlite.org/rowidtable.html) or else the query will fail.
  /// > Consider moving code that uses this to a SQLite-specific module.
  @available(*, deprecated, message: "rowid is SQLite-specific. Import StructuredQueriesSQLite for full support.")
  public var rowid: some QueryExpression<Int> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."rowid"
      """
    )
  }
}