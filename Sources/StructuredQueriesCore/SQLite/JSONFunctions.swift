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
  /// A JSON array repsentation of the aggregation of a table's columns.
  ///
  /// Constructs a JSON array of JSON objects with a field for each column of the table. This can be
  /// useful for loading many associated values in a single query. For example, to query for every
  /// reminders list, along with the array of reminders it is associated with, one can define a
  /// custom `@Selection` for that data and query as follows:
  ///
  /// @Row {
  ///   @Column {
  ///     ```swift
  ///     @Selection struct Row {
  ///       let remindersList: RemindersList
  ///       @Column(as: JSONRepresentation<[Reminder]>.self)
  ///       let reminders: Reminder
  ///     }
  ///     RemindersList
  ///       .join(Reminder.all) { $0.id.eq($1.remindersListID) }
  ///       .select {
  ///         Row.Columns(
  ///           remindersList: $0,
  ///           reminders: $1.jsonGroupArray()
  ///         )
  ///       }
  ///     ```
  ///   }
  ///   @Column {
  ///     ```sql
  ///      SELECT
  ///       "remindersLists".…,
  ///       iif(
  ///         "reminders"."id" IS NULL,
  ///         NULL,
  ///         json_object(
  ///           'id', json_quote("id"),
  ///           'title', json_quote("title"),
  ///           'priority', json_quote("priority")
  ///         )
  ///       )
  ///     FROM "remindersLists"
  ///     JOIN "reminders"
  ///       ON ("remindersLists"."id" = "reminders"."remindersListID")
  ///     ```
  ///   }
  /// }
  ///
  /// > Note: If the primary key of the row is NULL, then the object is omitted from the array.
  public func jsonGroupArray(
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<JSONRepresentation<[QueryValue]>> {
    let filter = filter.map { primaryKey.isNot(nil) && $0 } ?? primaryKey.isNot(nil)
    return jsonObject.jsonGroupArray(order: order, filter: filter)
  }

  private var jsonObject: some QueryExpression<QueryValue> {
    func open<TableColumn: TableColumnExpression>(_ column: TableColumn) -> QueryFragment {
      switch TableColumn.QueryValue.self {
      case is Bool.Type:
        return
          "\(quote: column.name, delimiter: .text), iif(\(column) = 0, json('false'), json('true'))"
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
}
