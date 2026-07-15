import Foundation
public import StructuredQueriesCore

extension QueryExpression where QueryValue: _AnyJSONRepresentable {
  /// Extracts a value from this JSON expression using the `->>` operator.
  ///
  /// ```swift
  /// Profile.select { $0.author.jsonExtract(\.name) }
  /// // SELECT ("profiles"."author" ->> '$."name"') FROM "profiles"
  /// ```
  ///
  /// Nested values can be extracted by chaining further:
  ///
  /// ```swift
  /// Profile.select { $0.author.jsonExtract(\.links[0].homepage) }
  /// // SELECT ("profiles"."author" ->> '$."links"[0]."homepage"') FROM "profiles"
  /// ```
  ///
  /// - Parameter path: A key path from the JSON expression to a field to extract.
  /// - Returns: An expression of the value extracted.
  public func jsonExtract<Context, Member: QueryRepresentable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<Member> {
    _jsonExtract(path)
  }

  @_documentation(visibility: private)
  public func jsonExtract<
    Context: _OptionalJSONPathContext,
    Member: QueryRepresentable
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<Member._Optionalized> {
    _jsonExtract(path)
  }

  /// A JSON array aggregate of this JSON expression.
  ///
  /// Concatenates all of the JSON documents in a group into a JSON array.
  ///
  /// ```swift
  /// Reminder.select { $0.tags.jsonGroupArray() }
  /// // SELECT json_group_array(json("reminders"."tags")) FROM "reminders"
  /// // => [[String]].JSONRepresentation
  /// ```
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSON array aggregate of this expression.
  public func jsonGroupArray(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[QueryValue.QueryOutput].JSONRepresentation> {
    _jsonGroupArray(isDistinct: isDistinct, order: order, filter: filter)
  }
}

extension QueryExpression where QueryValue: _JSONRepresentable {
  /// Sets a value at a given path in this JSON expression using the `json_set` function.
  ///
  /// ```swift
  /// Profile.update { $0.author = $0.author.jsonSet(\.name, "Blob") }
  /// // UPDATE "profiles" SET "author" = json_set("profiles"."author", '$."name"', 'Blob')
  /// ```
  ///
  /// - Parameters:
  ///   - path: A key path to a field to set.
  ///   - value: A value to set.
  /// - Returns: A JSON expression with the value set.
  public func jsonSet<Context: _RequiredJSONPathContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> some QueryExpression<QueryValue> {
    _jsonMutate("json_set", path, .jsonEncoded(value))
  }

  /// Inserts a value at a given path in this JSON expression using the `json_insert` function.
  ///
  /// - Parameters:
  ///   - path: A key path to an optional.
  ///   - value: A value to insert.
  /// - Returns: A JSON expression with the value inserted.
  public func jsonInsert<Member: QueryBindable & _OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathMember, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> some QueryExpression<QueryValue>
  where Member.Wrapped: QueryBindable {
    _jsonMutate("json_insert", path, .jsonEncoded(value))
  }

  /// Appends a value to a JSON array at a given path in this expression using the `json_insert`
  /// function.
  ///
  /// ```swift
  /// Profile.update { $0.tags = $0.tags.jsonAppend("new") }
  /// // UPDATE "profiles" SET "tags" = json_insert("profiles"."tags", '$[#]', 'new')
  /// ```
  ///
  /// - Parameters:
  ///   - path: A key path to an array.
  ///   - value: A value to append.
  /// - Returns: A JSON expression with the value appended.
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._Element>
  ) -> some QueryExpression<QueryValue>
  where Member._Element: QueryBindable {
    _jsonAppend("json_insert", path, .jsonEncoded(value))
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._ElementRepresentation>
  ) -> some QueryExpression<QueryValue> {
    _jsonAppend("json_insert", path, .jsonEncoded(value))
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: _OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._Element>
  ) -> some QueryExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation, Member.Wrapped._Element: QueryBindable {
    _jsonAppend("json_insert", path, .jsonEncoded(value))
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: _OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._ElementRepresentation>
  ) -> some QueryExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation {
    _jsonAppend("json_insert", path, .jsonEncoded(value))
  }

  /// Removes an optional member at a given path from this JSON expression using the `json_remove`
  /// function.
  ///
  /// - Parameter path: A key path to an optional.
  /// - Returns: A JSON expression with the member removed.
  public func jsonRemove<Context: _JSONPathMemberContext, Member: _OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<QueryValue> {
    _jsonRemove("json_remove", path)
  }

  /// Removes an array element at a given path from this JSON expression using the `json_remove`
  /// function.
  ///
  /// - Parameter path: A key path to an array element.
  /// - Returns: A JSON expression with the element removed.
  public func jsonRemove<Context: _JSONPathElementContext, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<QueryValue> {
    _jsonRemove("json_remove", path)
  }

  /// Replaces a value at a given path in this JSON expression using the `json_replace` function.
  ///
  /// - Parameters:
  ///   - path: A key path to an optional.
  ///   - value: A value to replace.
  /// - Returns: A JSON expression with the value replaced.
  public func jsonReplace<Context: _JSONPathMemberContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> some QueryExpression<QueryValue>
  where Member: _OptionalProtocol, Member.Wrapped: QueryBindable {
    _jsonMutate("json_replace", path, .jsonEncoded(value))
  }

  /// Replaces an array element at a given path in this JSON expression using the `json_replace`
  /// function.
  ///
  /// - Parameters:
  ///   - path: A key path to an array element.
  ///   - value: A value to replace.
  /// - Returns: A JSON expression with the value replaced.
  public func jsonReplace<Context: _JSONPathElementContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> some QueryExpression<QueryValue> {
    _jsonMutate("json_replace", path, .jsonEncoded(value))
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func jsonReplace<
    Context: _JSONPathMemberContext & _OptionalJSONPathContext, Member: QueryBindable
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> some QueryExpression<QueryValue> {
    _jsonMutate("json_replace", path, .jsonEncoded(value))
  }
}

extension QueryExpression
where QueryValue: _AnyJSONRepresentable & _JSONArrayRepresentation {
  /// Wraps this expression with the `json_array_length` function.
  ///
  /// ```swift
  /// Reminder.select { $0.tags.jsonArrayLength() }
  /// // SELECT json_array_length("reminders"."tags") FROM "reminders"
  /// ```
  ///
  /// - Returns: An integer expression of the `json_array_length` function wrapping this expression.
  public func jsonArrayLength() -> some QueryExpression<Int> {
    SQLQueryExpression("json_array_length(\(argumentFragment))")
  }
}

extension QueryExpression
where QueryValue: _JSONRepresentable & _JSONArrayRepresentation {
  @_documentation(visibility: private)
  public func jsonAppend(
    _ value: some QueryExpression<QueryValue._Element>
  ) -> some QueryExpression<QueryValue>
  where QueryValue._Element: QueryBindable {
    jsonAppend(\.self, value)
  }

  @_documentation(visibility: private)
  public func jsonAppend(
    _ value: some QueryExpression<QueryValue._ElementRepresentation>
  ) -> some QueryExpression<QueryValue> {
    jsonAppend(\.self, value)
  }
}

extension QueryExpression where QueryValue: _JSONBRepresentable {
  /// Sets a value at a given path in this JSONB expression using the `jsonb_set` function.
  ///
  /// The result is in SQLite's binary JSONB format, making it appropriate for storage contexts,
  /// like an `UPDATE` statement's `SET` clause:
  ///
  /// ```swift
  /// Profile.update { $0.author = $0.author.jsonbSet(\.name, "Blob, Esq.") }
  /// // UPDATE "profiles" SET "author" = jsonb_set("profiles"."author", '$."name"', 'Blob, Esq.')
  /// ```
  ///
  /// - Parameters:
  ///   - path: A key path to a field to set.
  ///   - value: A value to set.
  /// - Returns: A JSONB expression with the value set.
  public func jsonbSet<Context: _RequiredJSONPathContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> some QueryExpression<QueryValue> {
    _jsonMutate("jsonb_set", path, .jsonEncoded(value))
  }

  /// Inserts a value at a given path in this JSONB expression using the `jsonb_insert` function.
  ///
  /// - Parameters:
  ///   - path: A key path to an optional.
  ///   - value: A value to insert.
  /// - Returns: A JSONB expression with the value inserted.
  public func jsonbInsert<Member: QueryBindable & _OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathMember, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> some QueryExpression<QueryValue>
  where Member.Wrapped: QueryBindable {
    _jsonMutate("jsonb_insert", path, .jsonEncoded(value))
  }

  /// Appends a value to a JSON array at a given path in this expression using the `jsonb_insert`
  /// function.
  ///
  /// ```swift
  /// Doc.update { $0.tags = $0.tags.jsonbAppend("new") }
  /// // UPDATE "docs" SET "tags" = jsonb_insert("docs"."tags", '$[#]', 'new')
  /// ```
  ///
  /// - Parameters:
  ///   - path: A key path to an array.
  ///   - value: A value to append.
  /// - Returns: An JSONB expression with the value appended.
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._Element>
  ) -> some QueryExpression<QueryValue>
  where Member._Element: QueryBindable {
    _jsonAppend("jsonb_insert", path, .jsonEncoded(value))
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._ElementRepresentation>
  ) -> some QueryExpression<QueryValue> {
    _jsonAppend("jsonb_insert", path, .jsonEncoded(value))
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: _OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._Element>
  ) -> some QueryExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation, Member.Wrapped._Element: QueryBindable {
    _jsonAppend("jsonb_insert", path, .jsonEncoded(value))
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: _OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._ElementRepresentation>
  ) -> some QueryExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation {
    _jsonAppend("jsonb_insert", path, .jsonEncoded(value))
  }

  /// Removes an optional member at a given path from this JSONB expression using the `jsonb_remove`
  /// function.
  ///
  /// - Parameter path: A key path to an optional.
  /// - Returns: A JSONB expression with the member removed.
  public func jsonbRemove<Context: _JSONPathMemberContext, Member: _OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<QueryValue> {
    _jsonRemove("jsonb_remove", path)
  }

  /// Removes an array element at a given path from this JSONB expression using the `jsonb_remove`
  /// function.
  ///
  /// - Parameter path: A key path to an array element of the document.
  /// - Returns: A JSONB expression with the element removed.
  public func jsonbRemove<Context: _JSONPathElementContext, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<QueryValue> {
    _jsonRemove("jsonb_remove", path)
  }

  /// Replaces a value at a given path in this JSONB expression using the `jsonb_replace`
  /// function.
  ///
  /// - Parameters:
  ///   - path: A key path to an optional.
  ///   - value: A value to replace.
  /// - Returns: A JSONB expression with the value replaced.
  public func jsonbReplace<Context: _JSONPathMemberContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> some QueryExpression<QueryValue>
  where Member: _OptionalProtocol, Member.Wrapped: QueryBindable {
    _jsonMutate("jsonb_replace", path, .jsonEncoded(value))
  }

  /// Replaces an array element at a given path in this JSONB expression using the `jsonb_replace`
  /// function.
  ///
  /// - Parameters:
  ///   - path: A key path to an array element.
  ///   - value: A value to replace.
  /// - Returns: A JSONB expression with the value replaced.
  public func jsonbReplace<Context: _JSONPathElementContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> some QueryExpression<QueryValue> {
    _jsonMutate("jsonb_replace", path, .jsonEncoded(value))
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func jsonbReplace<
    Context: _JSONPathMemberContext & _OptionalJSONPathContext, Member: QueryBindable
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> some QueryExpression<QueryValue> {
    _jsonMutate("jsonb_replace", path, .jsonEncoded(value))
  }
}

extension QueryExpression
where QueryValue: _JSONBRepresentable & _JSONArrayRepresentation {
  @_documentation(visibility: private)
  public func jsonbAppend(
    _ value: some QueryExpression<QueryValue._Element>
  ) -> some QueryExpression<QueryValue>
  where QueryValue._Element: QueryBindable {
    jsonbAppend(\.self, value)
  }

  @_documentation(visibility: private)
  public func jsonbAppend(
    _ value: some QueryExpression<QueryValue._ElementRepresentation>
  ) -> some QueryExpression<QueryValue> {
    jsonbAppend(\.self, value)
  }
}

extension QueryExpression
where QueryValue: _OptionalProtocol, QueryValue.Wrapped: _AnyJSONRepresentable {
  /// Extracts a value from this JSON expression using the `->>` operator.
  ///
  /// - Parameter path: A key path from the document's columns.
  /// - Returns: An expression of the value extracted.
  public func jsonExtract<Context, Member: QueryRepresentable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue.Wrapped>, JSONPath<Context, Member>>
  ) -> some QueryExpression<Member._Optionalized> {
    _jsonExtract(path)
  }

  /// A JSON array aggregate of this JSON expression.
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSON array aggregate of this expression.
  public func jsonGroupArray(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[QueryValue.Wrapped.QueryOutput?].JSONRepresentation> {
    _jsonGroupArray(isDistinct: isDistinct, order: order, filter: filter)
  }
}

extension QueryExpression {
  fileprivate var argumentFragment: QueryFragment {
    $_isSelecting.withValue(false) { queryFragment }
  }

  private func _jsonExtract<Root, Context, Member: QueryRepresentable, Result>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> SQLQueryExpression<Result> {
    SQLQueryExpression(
      Member._queryFragment(
        jsonDecoding: """
          (\(argumentFragment) ->> \(quote: JSONPath()[keyPath: path].pathString, delimiter: .text))
          """
      )
    )
  }

  private func _jsonAppend<Root, Context, Member, Result: QueryRepresentable>(
    _ function: QueryFragment,
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>,
    _ value: QueryFragment
  ) -> JSONMutationExpression<Result> {
    JSONMutationExpression(
      """
      \(function)(\(argumentFragment), \
      \(quote: JSONPath()[keyPath: path].pathString + "[#]", delimiter: .text), \
      \(value))
      """
    )
  }

  private func _jsonRemove<Root, Context, Member, Result: QueryRepresentable>(
    _ function: QueryFragment,
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> JSONMutationExpression<Result> {
    JSONMutationExpression(
      """
      \(function)(\(argumentFragment), \
      \(quote: JSONPath()[keyPath: path].pathString, delimiter: .text))
      """
    )
  }

  private func _jsonMutate<Root, Context, Member, Result: QueryRepresentable>(
    _ function: QueryFragment,
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>,
    _ value: QueryFragment
  ) -> JSONMutationExpression<Result> {
    JSONMutationExpression(
      """
      \(function)(\(argumentFragment), \
      \(quote: JSONPath()[keyPath: path].pathString, delimiter: .text), \
      \(value))
      """
    )
  }

  private func _jsonGroupArray<Result>(
    isDistinct: Bool,
    order: (some QueryExpression)?,
    filter: (some QueryExpression<Bool>)?
  ) -> AggregateFunctionExpression<Result> {
    AggregateFunctionExpression(
      "json_group_array",
      isDistinct: isDistinct,
      ["json(\(argumentFragment))"],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }
}

private struct JSONMutationExpression<QueryValue: QueryRepresentable>: QueryExpression {
  let base: QueryFragment

  init(_ base: QueryFragment) {
    self.base = base
  }

  var queryFragment: QueryFragment {
    _isSelecting ? QueryValue.queryFragment(decoding: base) : base
  }
}

extension QueryExpression where QueryValue: Codable & QueryBindable {
  /// A JSON array aggregate of this expression.
  ///
  /// Concatenates all of the values in a group.
  ///
  /// ```swift
  /// Reminder.select { $0.title.jsonGroupArray() }
  /// // SELECT json_group_array("reminders"."title") FROM "reminders"
  /// ```
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSON array aggregate of this expression.
  @_disfavoredOverload
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

extension TableDefinition where QueryValue: Codable {
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
  ///           'id', "id",
  ///           'title', "title",
  ///           'priority', "priority"
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
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
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

extension TableDefinition where QueryValue: _OptionalProtocol & Codable {
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
  ///           'id', "id",
  ///           'title', "title",
  ///           'priority', "priority"
  ///         )
  ///       END AS "reminders"
  ///     FROM "remindersLists"
  ///     LEFT JOIN "reminders"
  ///       ON ("remindersLists"."id" = "reminders"."remindersListID")
  ///     ```
  ///   }
  /// }
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSON array aggregate of this table.
  public func jsonGroupArray<Wrapped: Codable>(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[Wrapped].JSONRepresentation>
  where QueryValue == Wrapped? {
    let rowFilter = rowid.isNot(nil)
    let filterQueryFragment =
      if let filter {
        rowFilter.and(filter).queryFragment
      } else {
        rowFilter.queryFragment
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
      let value = TableColumn.QueryValue._queryFragment(jsonEncoding: "\(column)")
      return "\(quote: column.name, delimiter: .text), \(value)"
    }
    let fragment: QueryFragment = $_isSelecting.withValue(false) {
      Self.allColumns
        .map { open($0) }
        .joined(separator: ", ")
    }
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

/// A type-safe path into JSON data.
@dynamicMemberLookup
public struct JSONPath<Context, QueryValue> {
  var components: [String] = []

  var pathString: String {
    "$\(components.joined())"
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      QueryValue._Object.TableColumns, TableColumn<QueryValue._Object, Member>
    >
  ) -> JSONPath<Context._Member, Member>
  where Context: _JSONPathContext, QueryValue: _JSONObjectRepresentation {
    JSONPath<Context._Member, Member>(
      components: components + [.member(QueryValue._Object.columns[keyPath: keyPath].name)]
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      QueryValue._Object.TableColumns, TableColumn<QueryValue._Object, Member>
    >
  ) -> JSONPath<Context._Member, Member.QueryOutput>
  where
    Context: _JSONPathContext,
    QueryValue: _JSONObjectRepresentation,
    Member.QueryOutput: QueryBindable
  {
    JSONPath<Context._Member, Member.QueryOutput>(
      components: components + [.member(QueryValue._Object.columns[keyPath: keyPath].name)]
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      QueryValue.Wrapped._Object.TableColumns, TableColumn<QueryValue.Wrapped._Object, Member>
    >
  ) -> JSONPath<_JSONPathMember?, Member>
  where QueryValue: _OptionalProtocol, QueryValue.Wrapped: _JSONObjectRepresentation {
    JSONPath<_JSONPathMember?, Member>(
      components: components + [.member(QueryValue.Wrapped._Object.columns[keyPath: keyPath].name)]
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      QueryValue.Wrapped._Object.TableColumns, TableColumn<QueryValue.Wrapped._Object, Member>
    >
  ) -> JSONPath<_JSONPathMember?, Member.QueryOutput>
  where
    QueryValue: _OptionalProtocol,
    QueryValue.Wrapped: _JSONObjectRepresentation,
    Member.QueryOutput: QueryBindable
  {
    JSONPath<_JSONPathMember?, Member.QueryOutput>(
      components: components + [.member(QueryValue.Wrapped._Object.columns[keyPath: keyPath].name)]
    )
  }

  public subscript(_ index: Int) -> JSONPath<Context._Element, QueryValue._ElementRepresentation>
  where Context: _JSONPathContext, QueryValue: _JSONArrayRepresentation {
    JSONPath<Context._Element, QueryValue._ElementRepresentation>(
      components: components + [.index(index)]
    )
  }

  public subscript(_ index: Int) -> JSONPath<Context._Element, QueryValue._Element>
  where
    Context: _JSONPathContext,
    QueryValue: _JSONArrayRepresentation,
    QueryValue._Element: QueryBindable
  {
    JSONPath<Context._Element, QueryValue._Element>(components: components + [.index(index)])
  }

  public subscript(
    _ index: Int
  ) -> JSONPath<_JSONPathElement?, QueryValue.Wrapped._ElementRepresentation>
  where QueryValue: _OptionalProtocol, QueryValue.Wrapped: _JSONArrayRepresentation {
    JSONPath<_JSONPathElement?, QueryValue.Wrapped._ElementRepresentation>(
      components: components + [.index(index)]
    )
  }

  public subscript(_ index: Int) -> JSONPath<_JSONPathElement?, QueryValue.Wrapped._Element>
  where
    QueryValue: _OptionalProtocol,
    QueryValue.Wrapped: _JSONArrayRepresentation,
    QueryValue.Wrapped._Element: QueryBindable
  {
    JSONPath<_JSONPathElement?, QueryValue.Wrapped._Element>(
      components: components + [.index(index)]
    )
  }
}

public enum _JSONPathRoot {}
public enum _JSONPathMember {}
public enum _JSONPathElement {}

public protocol _JSONPathContext {
  associatedtype _Member = _JSONPathMember
  associatedtype _Element = _JSONPathElement
}

extension _JSONPathRoot: _JSONPathContext {}
extension _JSONPathMember: _JSONPathContext {}
extension _JSONPathElement: _JSONPathContext {}

extension Optional: _JSONPathContext {
  public typealias _Member = _JSONPathMember?
  public typealias _Element = _JSONPathElement?
}

public protocol _OptionalJSONPathContext {}
extension Optional: _OptionalJSONPathContext {}

public protocol _RequiredJSONPathContext {}
extension _JSONPathRoot: _RequiredJSONPathContext {}
extension _JSONPathMember: _RequiredJSONPathContext {}
extension _JSONPathElement: _RequiredJSONPathContext {}

public protocol _JSONPathMemberContext {}
extension _JSONPathMember: _JSONPathMemberContext {}
extension Optional: _JSONPathMemberContext where Wrapped == _JSONPathMember {}

public protocol _JSONPathElementContext {}
extension _JSONPathElement: _JSONPathElementContext {}
extension Optional: _JSONPathElementContext where Wrapped == _JSONPathElement {}

public protocol _JSONObjectRepresentation<_Object> {
  associatedtype _Object: Table
}

public protocol _AnyJSONRepresentable: QueryRepresentable where QueryOutput: Codable {}

public protocol _JSONRepresentable: _AnyJSONRepresentable {}
extension _CodableJSONRepresentation: _JSONRepresentable {}

public protocol _JSONBRepresentable: _AnyJSONRepresentable {}
extension _CodableJSONBRepresentation: _JSONBRepresentable {}

extension _CodableJSONRepresentation: _JSONObjectRepresentation where QueryOutput: Table {
  public typealias _Object = QueryOutput
}

extension _CodableJSONBRepresentation: _JSONObjectRepresentation where QueryOutput: Table {
  public typealias _Object = QueryOutput
}

public protocol _JSONArrayRepresentation<_Element, _ElementRepresentation> {
  associatedtype _Element: Codable
  associatedtype _ElementRepresentation: QueryRepresentable
}

extension _CodableJSONRepresentation: _JSONArrayRepresentation
where QueryOutput: RangeReplaceableCollection, QueryOutput.Element: Codable {
  public typealias _Element = QueryOutput.Element
  public typealias _ElementRepresentation = _CodableJSONRepresentation<QueryOutput.Element>
}

extension _CodableJSONBRepresentation: _JSONArrayRepresentation
where QueryOutput: RangeReplaceableCollection, QueryOutput.Element: Codable {
  public typealias _Element = QueryOutput.Element
  public typealias _ElementRepresentation = _CodableJSONBRepresentation<QueryOutput.Element>
}

extension QueryFragment {
  fileprivate static func jsonEncoded<V: QueryRepresentable>(
    _ value: some QueryExpression<V>
  ) -> QueryFragment {
    V._queryFragment(jsonEncoding: value.argumentFragment)
  }
}

extension String {
  fileprivate static func member(_ name: String) -> String {
    let escaped =
      name
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return ".\"\(escaped)\""
  }

  fileprivate static func index(_ index: Int) -> String {
    index < 0 ? "[#\(index)]" : "[\(index)]"
  }
}
