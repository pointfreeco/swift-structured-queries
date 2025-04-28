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
  /// A JSON object repsentation of the table's columns.
  ///
  /// Constructs a `json_object` with a field for each column of the table. This can be useful
  /// for loading an associated value in a single query. For example, to query for every reminder,
  /// along with the list it is associated with, one can define a custom `@Selection` for that data
  /// and query as follows:
  ///
  /// @Row {
  ///   @Column {
  ///     ```swift
  ///     @Selection struct Row {
  ///       let reminder: Reminder
  ///       @Column(as: JSONRepresentation<RemindersList>.self)
  ///       let remindersList: RemindersList
  ///     }
  ///     Reminder
  ///       .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
  ///       .select {
  ///         Row.Columns(
  ///           reminder: $0,
  ///           remindersList: $1.jsonObject
  ///         )
  ///       }
  ///     ```
  ///   }
  ///   @Column {
  ///     ```sql
  ///      SELECT
  ///       "reminders".…,
  ///       iif(
  ///         "remindersLists"."id" IS NULL,
  ///         NULL,
  ///         json_object(
  ///           'id', json_quote("id"),
  ///           'color', json_quote("color"),
  ///           'title', json_quote("title")
  ///         )
  ///       )
  ///     FROM "reminders"
  ///     JOIN "remindersLists"
  ///       ON ("reminders"."remindersListID" = "remindersLists"."id")
  ///     ```
  ///   }
  /// }
  ///
  /// > Note: If the primary key of the row is NULL, then NULL is returned for `jsonObject`.
  public var jsonObject: some QueryExpression<JSONRepresentation<QueryValue>> {
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
  ///           reminders: $1.jsonObjects
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
  public var jsonObjects: some QueryExpression<JSONRepresentation<[QueryValue]>> {
    SQLQueryExpression(
      "json_group_array(\(jsonObject)) filter(where \(self.primaryKey.isNot(nil)))"
    )
  }
}
