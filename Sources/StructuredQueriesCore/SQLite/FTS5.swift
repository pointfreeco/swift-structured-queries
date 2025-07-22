/// A virtual table using the FTS5 extension.
///
/// Apply this protocol to a `@Table` declaration to introduce FTS5 helpers.
public protocol FTS5: Table {}
extension TableDefinition where QueryValue: FTS5 {
  @available(*, deprecated, message: "Virtual tables are not 'rowid' tables")
  public var rowid: some QueryExpression<Int> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."rowid"
      """
    )
  }

  /// An expression representing the search result's rank.
  public var rank: some QueryExpression<Double?> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."rank"
      """
    )
  }

  /// A predicate expression from this table matched against another _via_ the `MATCH` operator.
  ///
  /// ```swift
  /// ReminderText.where { $0.match("get") }
  /// // SELECT … FROM "reminderTexts" WHERE ("reminderTexts" MATCH 'get')
  /// ```
  ///
  /// - Parameter pattern: A string expression describing the `MATCH` pattern.
  /// - Returns: A predicate expression.
  public func match(_ pattern: some QueryExpression<String>) -> some QueryExpression<Bool> {
    SQLQueryExpression(
      """
      (\(QueryValue.self) MATCH \(pattern))
      """
    )
  }
}

extension TableColumnExpression where Root: FTS5 {
  /// A string expression highlighting matches in this column using the given delimiters.
  ///
  /// - Parameters:
  ///   - open: An opening delimiter denoting the beginning of a match, _e.g._ `"<b>"`.
  ///   - close: A closing delimiter denoting the end of a match, _e.g._, `"</b>"`.
  /// - Returns: A string expression highlighting matches in this column.
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

  /// A predicate expression from this column matched against another _via_ the `MATCH` operator.
  ///
  /// ```swift
  /// ReminderText.where { $0.title.match("get") }
  /// // SELECT … FROM "reminderTexts" WHERE ("reminderTexts"."title" MATCH 'get')
  /// ```
  ///
  /// - Parameter pattern: A string expression describing the `MATCH` pattern.
  /// - Returns: A predicate expression.
  public func match(_ pattern: some QueryExpression<String>) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "MATCH", rhs: pattern)
  }
}
