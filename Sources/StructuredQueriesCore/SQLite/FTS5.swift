import IssueReporting

/// A virtual table using the FTS5 extension.
///
/// Apply this protocol to a `@Table` declaration to introduce FTS5 helpers.
public protocol FTS5: Table {}

extension TableDefinition where QueryValue: FTS5 {
  /// A predicate expression from this table matched against another _via_ the `MATCH` operator.
  ///
  /// ```swift
  /// ReminderText.where { $0.match("get") }
  /// // SELECT … FROM "reminderTexts" WHERE ("reminderTexts" MATCH 'get')
  /// ```
  ///
  /// - Parameter pattern: A string expression describing the `MATCH` pattern.
  /// - Returns: A predicate expression.
  public func match(_ pattern: some StringProtocol) -> some QueryExpression<Bool> {
    SQLQueryExpression(
      """
      (\(QueryValue.self) MATCH \(bind: "\(pattern)"))
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

  @available(*, deprecated, message: "Virtual tables are not 'rowid' tables")
  public var rowid: some QueryExpression<Int> {
    SQLQueryExpression(
      """
      \(QueryValue.self)."rowid"
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
    _ open: some StringProtocol,
    _ close: some StringProtocol
  ) -> some QueryExpression<String> {
    SQLQueryExpression(
      """
      highlight(\
      \(Root.self), \
      (\(cid)),
      \(quote: "\(open)", delimiter: .text), \
      \(quote: "\(close)", delimiter: .text)\
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
  public func match(_ pattern: some StringProtocol) -> some QueryExpression<Bool> {
    Root.columns.match("\(name):\(pattern)")
  }

  /// A string expression highlighting matches in text fragments of this column using the given
  /// delimiters.
  ///
  /// - Parameters:
  ///   - open: An opening delimiter denoting the beginning of a match, _e.g._ `"<b>"`.
  ///   - close: A closing delimiter denoting the end of a match, _e.g._, `"</b>"`.
  ///   - ellipsis: Text indicating a truncation of text in the column.
  ///   - tokens: The maximum number of tokens in the returned text.
  /// - Returns: A string expression highlighting matches in this column.
  public func snippet(
    _ open: some StringProtocol,
    _ close: some StringProtocol,
    _ ellipsis: some StringProtocol,
    _ tokens: Int
  ) -> some QueryExpression<String> {
    SQLQueryExpression(
      """
      snippet(\
      \(Root.self), \
      (\(cid)),
      \(quote: "\(open)", delimiter: .text), \
      \(quote: "\(close)", delimiter: .text), \
      \(quote: "\(ellipsis)", delimiter: .text), \
      \(raw: tokens)\
      )
      """
    )
  }
}

extension TableColumnExpression {
  fileprivate var cid: some Statement<Int> {
    SQLQueryExpression(
      """
      SELECT "cid" FROM pragma_table_info(\(quote: Root.tableName, delimiter: .text)) \
      WHERE "name" = \(quote: name, delimiter: .text)
      """
    )
  }
}
