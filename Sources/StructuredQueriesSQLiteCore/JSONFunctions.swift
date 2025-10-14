import Foundation

extension QueryExpression {
  /// Passes this expression and the given one to the `json_patch` function.
  ///
  /// - Parameter other: A JSON object to patch this object with.
  /// - Returns: A JSON expression of the result of the invoking the `json_patch` function.
  public func jsonPatch<QueryOutput: Codable>(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue>
  where QueryValue == _CodableJSONRepresentation<QueryOutput> {
    QueryFunction("json_patch", self, other)
  }

  /// Wraps this expression with the `json_array_length` function.
  ///
  /// ```swift
  /// Reminder.select { $0.tags.jsonArrayLength() }
  /// // SELECT json_array_length("reminders"."tags") FROM "reminders"
  /// ```
  ///
  /// - Returns: An integer expression of the `json_array_length` function wrapping this expression.
  public func jsonArrayLength<Element: Codable>() -> some QueryExpression<Int>
  where QueryValue == [Element].JSONRepresentation {
    QueryFunction("json_array_length", self)
  }
}

extension QueryExpression where QueryValue: Codable & QueryBindable {
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
  ///   - isDistinct: An boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSON array aggregate of this expression.
  public func jsonGroupArray(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[QueryValue].JSONRepresentation> {
    AggregateFunctionExpression(
      "json_group_array",
      isDistinct: isDistinct,
      [queryFragment],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }
}

extension PrimaryKeyedTableDefinition where QueryValue: Codable {
  /// A JSON array representation of the aggregation of a table's columns.
  ///
  /// Constructs a JSON array of JSON objects with a field for each column of the table. This can be
  /// useful for loading many associated values in a single query. For example, to query for every
  /// reminders list, along with the array of reminders it is associated with, one can define a
  /// custom data type for that data and query as follows:
  ///
  /// @Row {
  ///   @Column {
  ///     ```swift
  ///     @Selection struct Row {
  ///       let remindersList: RemindersList
  ///       @Column(as: [Reminder].JSONRepresentation.self)
  ///       let reminders: [Reminder]
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
  ///       CASE WHEN
  ///         ("reminders"."id" IS NOT NULL)
  ///       THEN
  ///         json_object(
  ///           'id', json_quote("id"),
  ///           'title', json_quote("title"),
  ///           'priority', json_quote("priority")
  ///         )
  ///       END AS "reminders"
  ///     FROM "remindersLists"
  ///     JOIN "reminders"
  ///       ON ("remindersLists"."id" = "reminders"."remindersListID")
  ///     ```
  ///   }
  /// }
  ///
  /// - Parameters:
  ///   - isDistinct: An boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSON array aggregate of this table.
  public func jsonGroupArray(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[QueryValue].JSONRepresentation> {
    AggregateFunctionExpression(
      "json_group_array",
      isDistinct: isDistinct,
      [jsonObject().queryFragment],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }
}

extension PrimaryKeyedTableDefinition
where
  QueryValue: _OptionalProtocol & Codable,
  PrimaryColumn: _TableColumnExpression<QueryValue, PrimaryKey>
{
  /// A JSON array representation of the aggregation of a table's columns.
  ///
  /// Constructs a JSON array of JSON objects with a field for each column of the table. This can be
  /// useful for loading many associated values in a single query. For example, to query for every
  /// reminders list, along with the array of reminders it is associated with, one can define a
  /// custom data type for that data and query as follows:
  ///
  /// @Row {
  ///   @Column {
  ///     ```swift
  ///     @Selection struct Row {
  ///       let remindersList: RemindersList
  ///       @Column(as: [Reminder].JSONRepresentation.self)
  ///       let reminders: [Reminder]
  ///     }
  ///     RemindersList
  ///       .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
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
  ///       CASE WHEN
  ///         ("reminders"."id" IS NOT NULL)
  ///       THEN
  ///         json_object(
  ///           'id', json_quote("id"),
  ///           'title', json_quote("title"),
  ///           'priority', json_quote("priority")
  ///         )
  ///       END AS "reminders"
  ///     FROM "remindersLists"
  ///     JOIN "reminders"
  ///       ON ("remindersLists"."id" = "reminders"."remindersListID")
  ///     ```
  ///   }
  /// }
  ///
  /// - Parameters:
  ///   - isDistinct: An boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSON array aggregate of this table.
  public func jsonGroupArray<Wrapped: Codable>(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[Wrapped].JSONRepresentation>
  where QueryValue == Wrapped? {
    let primaryKeyColumns: QueryFragment = self.primaryKey._names
      .map { "\(QueryValue.self).\(quote: $0)" }
      .joined(separator: ", ")
    let primaryKeyNulls: QueryFragment = Array(
      repeating: QueryFragment("NULL"), count: self.primaryKey._names.count
    )
    .joined(separator: ", ")
    let primaryKeyFilter = SQLQueryExpression(
      "(\(primaryKeyColumns)) IS NOT (\(primaryKeyNulls))",
      as: Bool.self
    )
    let filterQueryFragment =
      if let filter {
        primaryKeyFilter.and(filter).queryFragment
      } else {
        primaryKeyFilter.queryFragment
      }
    return AggregateFunctionExpression(
      "json_group_array",
      isDistinct: isDistinct,
      [QueryValue.columns.jsonObject().queryFragment],
      order: order?.queryFragment,
      filter: filterQueryFragment
    )
  }
}

extension TableDefinition where QueryValue: Codable {
  /// A JSON representation of a table's columns.
  ///
  /// Useful for referencing a table row in a larger JSON selection.
  public func jsonObject() -> some QueryExpression<_CodableJSONRepresentation<QueryValue>> {
    func open<TableColumn: TableColumnExpression>(_ column: TableColumn) -> QueryFragment {
      typealias Value = TableColumn.QueryValue._Optionalized.Wrapped

      func isJSONRepresentation<T: Codable>(_: T.Type, isOptional: Bool = false) -> Bool {
        func isOptionalJSONRepresentation<U: _OptionalProtocol>(_: U.Type) -> Bool {
          if let codableType = U.Wrapped.self as? any Codable.Type {
            return isJSONRepresentation(codableType, isOptional: true)
          } else {
            return false
          }
        }
        if let optionalType = T.self as? any _OptionalProtocol.Type {
          return isOptionalJSONRepresentation(optionalType)
        } else if isOptional {
          return TableColumn.QueryValue.self == T.JSONRepresentation?.self
        } else {
          return Value.self == T.JSONRepresentation.self
        }
      }

      if Value.self == Bool.self {
        return """
          \(quote: column.name, delimiter: .text), \
          json(CASE \(column) WHEN 0 THEN 'false' WHEN 1 THEN 'true' END)
          """
      } else if Value.self == Date.UnixTimeRepresentation.self {
        return "\(quote: column.name, delimiter: .text), datetime(\(column), 'unixepoch')"
      } else if Value.self == Date.JulianDayRepresentation.self {
        return "\(quote: column.name, delimiter: .text), datetime(\(column), 'julianday')"
      } else if let codableType = TableColumn.QueryValue.QueryOutput.self
        as? any Codable.Type,
        isJSONRepresentation(codableType)
      {
        return "\(quote: column.name, delimiter: .text), json(\(column))"
      } else {
        return "\(quote: column.name, delimiter: .text), json_quote(\(column))"
      }
    }
    let fragment: QueryFragment = Self.allColumns
      .map { open($0) }
      .joined(separator: ", ")
    return QueryFunction("json_object", SQLQueryExpression(fragment))
  }
}

extension Optional.TableColumns where QueryValue: Codable {
  /// A JSON representation of a table's columns.
  ///
  /// Useful for referencing a table row in a larger JSON selection.
  public func jsonObject() -> some QueryExpression<_CodableJSONRepresentation<Wrapped>?> {
    Case().when(rowid.isNot(nil), then: Wrapped.columns.jsonObject())
  }
}
