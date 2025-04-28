import Foundation
import StructuredQueriesSupport

extension QueryExpression {
  /// Wraps this expression with the `json_array_length` function.
  ///
  /// ```swift
  /// Reminder.select { $0.tags.jsonArrayLength() }
  /// // SELECT json_array_length("reminders"."tags") FROM "reminders"
  /// ```
  ///
  /// - Returns: An integer expression of the `json_array_length` function wrapping this expression.
  public func jsonArrayLength<Element: Codable & Sendable>() -> some QueryExpression<Int>
  where QueryValue == JSONRepresentation<[Element]> {
    QueryFunction("json_array_length", self)
  }
}

extension QueryExpression where QueryValue: Codable & Sendable {
  /// A JSON array aggregate of this expression
  ///
  /// Concatenates all of the values in a group.
  ///
  /// ```swift
  /// Reminder.select { $0.title.jsonGroupArray() }
  /// // SELECT json_group_array("reminders"."title") FROM "reminders"
  /// ```
  ///
  /// - Parameters:
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSON array aggregate of this expression.
  public func jsonGroupArray(
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<JSONRepresentation<[QueryValue]>> {
    AggregateFunction("json_group_array", self, order: order, filter: filter)
  }
}

extension PrimaryKeyedTableDefinition where QueryValue: Codable & Sendable {
  /// A JSON object repsentation of the table's columns
  ///
  /// Constructs a `json_object` with a field for each column of the table.
  ///
  /// @Row {
  ///   @Column {
  ///     ```swift
  ///     @Table struct Tag: Codable {
  ///     Tag.select { $0.json }
  ///     ```
  ///   }
  ///   @Column {
  ///     ```sql
  ///      let x = 1
  ///      ```
  ///   }
  /// }
  ///
  public var jsonObject: some QueryExpression<JSONRepresentation<QueryValue>> {
    func open<TableColumn: TableColumnExpression>(_ column: TableColumn) -> QueryFragment {
      switch TableColumn.QueryValue.self {
      case is Bool.Type:
        return "\(quote: column.name, delimiter: .text), iif(\(column) = 0, json('false'), json('true'))"
      case is Date.UnixTimeRepresentation.Type:
        return "\(quote: column.name, delimiter: .text), datetime(\(column), 'unixepoch')"
      case is Date.JulianDayRepresentation.Type:
        return "\(quote: column.name, delimiter: .text), datetime(\(column), 'julianday')"
      default:
        return "\(quote: column.name, delimiter: .text), json_quote(\(column))"
      }
    }
    let fragment: QueryFragment = Self.allColumns
      .map { open($0) }
      .joined(separator: ", ")
    return SQLQueryExpression("iif(\(self.primaryKey.is(nil)), NULL, json_object(\(fragment)))")
  }

  public var jsonObjects: some QueryExpression<JSONRepresentation<[QueryValue]>> {
    SQLQueryExpression(
      "json_group_array(\(jsonObject)) filter(where \(self.primaryKey.isNot(nil)))"
    )
  }
}
