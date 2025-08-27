import StructuredQueriesCore

extension TableDefinition {
  /// An expression representing the table's rowid for SQLite databases.
  ///
  /// This provides the full, non-deprecated implementation for SQLite's rowid feature.
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
