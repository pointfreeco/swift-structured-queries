import Foundation
import IssueReporting
public import StructuredQueriesCore

#if CasePaths && ColumnCoding
  public import CasePaths
#endif

extension QueryExpression where QueryValue: _AnyJSONRepresentable {
  /// Extracts a value from this JSON expression using the `json_extract` function.
  ///
  /// ```swift
  /// Profile.select { $0.author.jsonExtract(\.name) }
  /// // SELECT json_extract("profiles"."author", '$."name"') FROM "profiles"
  /// ```
  ///
  /// Nested values can be extracted by chaining further:
  ///
  /// ```swift
  /// Profile.select { $0.author.jsonExtract(\.links[0].homepage) }
  /// // SELECT json_extract("profiles"."author", '$."links"[0]."homepage"') FROM "profiles"
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

  /// Extracts a value from this JSON expression using the `jsonb_extract` function.
  ///
  /// Works like `jsonExtract`, except JSON objects and arrays are extracted in SQLite's binary
  /// JSONB format, making the result appropriate for storage contexts, like an `UPDATE`
  /// statement's `SET` clause:
  ///
  /// ```swift
  /// Profile.update {
  ///   $0.author = $0.author.jsonbSet(\.links, $0.author.jsonbExtract(\.pastLinks[0]))
  /// }
  /// // UPDATE "profiles"
  /// // SET "author" = jsonb_set(
  /// //   "profiles"."author", '$."links"', jsonb_extract("profiles"."author", '$."pastLinks"[0]')
  /// // )
  /// ```
  ///
  /// - Parameter path: A key path from the JSON expression to a field to extract.
  /// - Returns: An expression of the value extracted.
  public func jsonbExtract<Context, Member: QueryRepresentable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<Member> {
    _jsonbExtract(path)
  }

  @_documentation(visibility: private)
  public func jsonbExtract<
    Context: _OptionalJSONPathContext,
    Member: QueryRepresentable
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<Member._Optionalized> {
    _jsonbExtract(path)
  }

  /// A JSON array aggregate of this JSON expression.
  ///
  /// Concatenates all of the JSON values in a group into a JSON array.
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

  /// A JSONB array aggregate of this JSON expression.
  ///
  /// Works like `jsonGroupArray`, except the aggregate is in SQLite's binary JSONB format, making
  /// it appropriate for storage contexts, like assignment to a JSONB column. To select and decode
  /// an aggregate directly, use `jsonGroupArray`, instead.
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSONB array aggregate of this expression.
  public func jsonbGroupArray(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[QueryValue.QueryOutput].JSONBRepresentation> {
    _jsonbGroupArray(isDistinct: isDistinct, order: order, filter: filter)
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
  ) -> _JSONSetExpression<QueryValue> {
    _JSONSetExpression(
      function: "json_set",
      base: argumentFragment,
      arguments: [.jsonSetArguments("json_object", path, .jsonEncoded(value))]
    )
  }

  @_documentation(visibility: private)
  public func jsonSet<Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathCase, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONSetExpression<QueryValue> {
    _JSONSetExpression(
      function: "json_set",
      base: argumentFragment,
      arguments: [.jsonSetArguments("json_object", path, .jsonEncoded(value))]
    )
  }

  /// Inserts a value at a given path in this JSON expression using the `json_insert` function.
  ///
  /// - Parameters:
  ///   - path: A key path to an optional.
  ///   - value: A value to insert.
  /// - Returns: A JSON expression with the value inserted.
  public func jsonInsert<Member: QueryBindable & StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathMember, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: QueryBindable {
    _JSONInsertExpression(
      function: "json_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, .jsonEncoded(value))]
    )
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
  ) -> _JSONInsertExpression<QueryValue>
  where Member._Element: QueryBindable {
    _JSONInsertExpression(
      function: "json_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, appending: "[#]", .jsonEncoded(value))]
    )
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue> {
    _JSONInsertExpression(
      function: "json_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, appending: "[#]", .jsonEncoded(value))]
    )
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation, Member.Wrapped._Element: QueryBindable {
    _JSONInsertExpression(
      function: "json_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, appending: "[#]", .jsonEncoded(value))]
    )
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation {
    _JSONInsertExpression(
      function: "json_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, appending: "[#]", .jsonEncoded(value))]
    )
  }

  /// Removes an optional member at a given path from this JSON expression using the `json_remove`
  /// function.
  ///
  /// - Parameter path: A key path to an optional.
  /// - Returns: A JSON expression with the member removed.
  public func jsonRemove<Context: _JSONPathMemberContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> _JSONRemoveExpression<QueryValue> {
    _JSONRemoveExpression(
      function: "json_remove",
      base: argumentFragment,
      arguments: [.jsonArguments(path)]
    )
  }

  /// Removes an array element at a given path from this JSON expression using the `json_remove`
  /// function.
  ///
  /// - Parameter path: A key path to an array element.
  /// - Returns: A JSON expression with the element removed.
  public func jsonRemove<Context: _JSONPathElementContext, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> _JSONRemoveExpression<QueryValue> {
    _JSONRemoveExpression(
      function: "json_remove",
      base: argumentFragment,
      arguments: [.jsonArguments(path)]
    )
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
  ) -> _JSONReplaceExpression<QueryValue>
  where Member: StructuredQueriesCore._OptionalProtocol, Member.Wrapped: QueryBindable {
    _JSONReplaceExpression(
      function: "json_replace",
      base: argumentFragment,
      arguments: [.jsonArguments(path, .jsonEncoded(value))]
    )
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
  ) -> _JSONReplaceExpression<QueryValue> {
    _JSONReplaceExpression(
      function: "json_replace",
      base: argumentFragment,
      arguments: [.jsonArguments(path, .jsonEncoded(value))]
    )
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func jsonReplace<
    Context: _JSONPathMemberContext & _OptionalJSONPathContext, Member: QueryBindable
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONReplaceExpression<QueryValue> {
    _JSONReplaceExpression(
      function: "json_replace",
      base: argumentFragment,
      arguments: [.jsonArguments(path, .jsonEncoded(value))]
    )
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

extension QueryExpression where QueryValue: _AnyJSONRepresentable {
  /// Wraps this expression with the `json_array_length` function for an array at a given path.
  ///
  /// ```swift
  /// Profile.select { $0.author.jsonArrayLength(\.pastLinks) }
  /// // SELECT json_array_length("profiles"."author", '$."pastLinks"') FROM "profiles"
  /// ```
  ///
  /// - Parameter path: A key path from the JSON expression to an array.
  /// - Returns: An integer expression of the `json_array_length` function.
  public func jsonArrayLength<Context, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<Int> {
    _jsonArrayLength(path)
  }

  @_documentation(visibility: private)
  public func jsonArrayLength<
    Context: _OptionalJSONPathContext,
    Member: _JSONArrayRepresentation
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<Int?> {
    _jsonArrayLength(path)
  }

  @_documentation(visibility: private)
  public func jsonArrayLength<Context, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> some QueryExpression<Int?>
  where Member.Wrapped: _JSONArrayRepresentation {
    _jsonArrayLength(path)
  }
}

extension QueryExpression
where QueryValue: _JSONRepresentable & _JSONArrayRepresentation {
  @_documentation(visibility: private)
  public func jsonAppend(
    _ value: some QueryExpression<QueryValue._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where QueryValue._Element: QueryBindable {
    jsonAppend(\.self, value)
  }

  @_documentation(visibility: private)
  public func jsonAppend(
    _ value: some QueryExpression<QueryValue._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue> {
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
  ) -> _JSONSetExpression<QueryValue> {
    _JSONSetExpression(
      function: "jsonb_set",
      base: argumentFragment,
      arguments: [.jsonSetArguments("jsonb_object", path, .jsonEncoded(value))]
    )
  }

  @_documentation(visibility: private)
  public func jsonbSet<Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathCase, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONSetExpression<QueryValue> {
    _JSONSetExpression(
      function: "jsonb_set",
      base: argumentFragment,
      arguments: [.jsonSetArguments("jsonb_object", path, .jsonEncoded(value))]
    )
  }

  /// Inserts a value at a given path in this JSONB expression using the `jsonb_insert` function.
  ///
  /// - Parameters:
  ///   - path: A key path to an optional.
  ///   - value: A value to insert.
  /// - Returns: A JSONB expression with the value inserted.
  public func jsonbInsert<Member: QueryBindable & StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathMember, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: QueryBindable {
    _JSONInsertExpression(
      function: "jsonb_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, .jsonEncoded(value))]
    )
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
  ) -> _JSONInsertExpression<QueryValue>
  where Member._Element: QueryBindable {
    _JSONInsertExpression(
      function: "jsonb_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, appending: "[#]", .jsonEncoded(value))]
    )
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue> {
    _JSONInsertExpression(
      function: "jsonb_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, appending: "[#]", .jsonEncoded(value))]
    )
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation, Member.Wrapped._Element: QueryBindable {
    _JSONInsertExpression(
      function: "jsonb_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, appending: "[#]", .jsonEncoded(value))]
    )
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation {
    _JSONInsertExpression(
      function: "jsonb_insert",
      base: argumentFragment,
      arguments: [.jsonArguments(path, appending: "[#]", .jsonEncoded(value))]
    )
  }

  /// Removes an optional member at a given path from this JSONB expression using the `jsonb_remove`
  /// function.
  ///
  /// - Parameter path: A key path to an optional.
  /// - Returns: A JSONB expression with the member removed.
  public func jsonbRemove<Context: _JSONPathMemberContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> _JSONRemoveExpression<QueryValue> {
    _JSONRemoveExpression(
      function: "jsonb_remove",
      base: argumentFragment,
      arguments: [.jsonArguments(path)]
    )
  }

  /// Removes an array element at a given path from this JSONB expression using the `jsonb_remove`
  /// function.
  ///
  /// - Parameter path: A key path to an array element.
  /// - Returns: A JSONB expression with the element removed.
  public func jsonbRemove<Context: _JSONPathElementContext, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> _JSONRemoveExpression<QueryValue> {
    _JSONRemoveExpression(
      function: "jsonb_remove",
      base: argumentFragment,
      arguments: [.jsonArguments(path)]
    )
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
  ) -> _JSONReplaceExpression<QueryValue>
  where Member: StructuredQueriesCore._OptionalProtocol, Member.Wrapped: QueryBindable {
    _JSONReplaceExpression(
      function: "jsonb_replace",
      base: argumentFragment,
      arguments: [.jsonArguments(path, .jsonEncoded(value))]
    )
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
  ) -> _JSONReplaceExpression<QueryValue> {
    _JSONReplaceExpression(
      function: "jsonb_replace",
      base: argumentFragment,
      arguments: [.jsonArguments(path, .jsonEncoded(value))]
    )
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func jsonbReplace<
    Context: _JSONPathMemberContext & _OptionalJSONPathContext, Member: QueryBindable
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONReplaceExpression<QueryValue> {
    _JSONReplaceExpression(
      function: "jsonb_replace",
      base: argumentFragment,
      arguments: [.jsonArguments(path, .jsonEncoded(value))]
    )
  }
}

extension QueryExpression
where QueryValue: _JSONBRepresentable & _JSONArrayRepresentation {
  @_documentation(visibility: private)
  public func jsonbAppend(
    _ value: some QueryExpression<QueryValue._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where QueryValue._Element: QueryBindable {
    jsonbAppend(\.self, value)
  }

  @_documentation(visibility: private)
  public func jsonbAppend(
    _ value: some QueryExpression<QueryValue._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue> {
    jsonbAppend(\.self, value)
  }
}

extension QueryExpression
where QueryValue: StructuredQueriesCore._OptionalProtocol, QueryValue.Wrapped: _AnyJSONRepresentable {
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

  /// A JSONB array aggregate of this JSON expression.
  ///
  /// Works like `jsonGroupArray`, except the aggregate is in SQLite's binary JSONB format, making
  /// it appropriate for storage contexts, like assignment to a JSONB column. To select and decode
  /// an aggregate directly, use `jsonGroupArray`, instead.
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSONB array aggregate of this expression.
  public func jsonbGroupArray(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[QueryValue.Wrapped.QueryOutput?].JSONBRepresentation> {
    _jsonbGroupArray(isDistinct: isDistinct, order: order, filter: filter)
  }
}

extension QueryExpression {
  fileprivate var argumentFragment: QueryFragment {
    $_isSelecting.withValue(false) { queryFragment }
  }

  private func _jsonExtract<Root, Context, Member: QueryRepresentable, Result>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> SQLQueryExpression<Result> {
    SQLQueryExpression(_jsonExtract("json_extract", path))
  }

  private func _jsonbExtract<Root, Context, Member: QueryRepresentable, Result>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> JSONFunctionExpression<Result> {
    JSONFunctionExpression(
      base: _jsonExtract("jsonb_extract", path),
      decode: Member.queryFragment(decoding:)
    )
  }

  private func _jsonArrayLength<Root, Context, Member, Result>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> SQLQueryExpression<Result> {
    SQLQueryExpression(
      """
      json_array_length(\
      \(argumentFragment), \
      \(quote: JSONPath()[keyPath: path].pathString, delimiter: .text)\
      )
      """
    )
  }

  private func _jsonExtract<Root, Context, Member: QueryRepresentable>(
    _ function: QueryFragment,
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> QueryFragment {
    Member._queryFragment(
      jsonDecoding: """
        \(function)(\
        \(argumentFragment), \
        \(quote: JSONPath()[keyPath: path].pathString, delimiter: .text)\
        )
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

  private func _jsonbGroupArray<Result>(
    isDistinct: Bool,
    order: (some QueryExpression)?,
    filter: (some QueryExpression<Bool>)?
  ) -> AggregateFunctionExpression<Result> {
    AggregateFunctionExpression(
      "jsonb_group_array",
      isDistinct: isDistinct,
      ["jsonb(\(argumentFragment))"],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
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

  /// A JSONB array aggregate of this expression.
  ///
  /// Works like `jsonGroupArray`, except the aggregate is in SQLite's binary JSONB format, making
  /// it appropriate for storage contexts, like assignment to a JSONB column:
  ///
  /// ```swift
  /// Post.update { $0.notes = Track.select { $0.trackName.jsonbGroupArray() } }
  /// // UPDATE "posts" SET "notes" = (
  /// //   SELECT jsonb_group_array("tracks"."track_name") FROM "tracks"
  /// // )
  /// ```
  ///
  /// To select and decode an aggregate directly, use `jsonGroupArray`, instead.
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSONB array aggregate of this expression.
  @_disfavoredOverload
  public func jsonbGroupArray(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[QueryValue].JSONBRepresentation> {
    AggregateFunctionExpression(
      "jsonb_group_array",
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

  /// A JSONB array representation of the aggregation of a table's columns.
  ///
  /// Works like `jsonGroupArray`, except the aggregate is in SQLite's binary JSONB format, making
  /// it appropriate for storage contexts, like assignment to a JSONB column. To select and decode
  /// an aggregate directly, use `jsonGroupArray`, instead.
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSONB array aggregate of this table.
  public func jsonbGroupArray(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[QueryValue].JSONBRepresentation> {
    AggregateFunctionExpression(
      "jsonb_group_array",
      isDistinct: isDistinct,
      [jsonbObject().queryFragment],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }
}

extension TableDefinition where QueryValue: StructuredQueriesCore._OptionalProtocol & Codable {
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

  /// A JSONB array representation of the aggregation of a table's columns.
  ///
  /// Works like `jsonGroupArray`, except the aggregate is in SQLite's binary JSONB format, making
  /// it appropriate for storage contexts, like assignment to a JSONB column. To select and decode
  /// an aggregate directly, use `jsonGroupArray`, instead.
  ///
  /// - Parameters:
  ///   - isDistinct: A boolean to enable the `DISTINCT` clause to apply to the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A JSONB array aggregate of this table.
  public func jsonbGroupArray<Wrapped: Codable>(
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<[Wrapped].JSONBRepresentation>
  where QueryValue == Wrapped? {
    let rowFilter = rowid.isNot(nil)
    let filterQueryFragment =
      if let filter {
        rowFilter.and(filter).queryFragment
      } else {
        rowFilter.queryFragment
      }
    return AggregateFunctionExpression(
      "jsonb_group_array",
      isDistinct: isDistinct,
      [QueryValue.columns.jsonbObject().queryFragment],
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
    QueryFunction("json_object", SQLQueryExpression(_jsonObjectArguments))
  }

  /// A JSONB representation of a table's columns.
  ///
  /// Works like ``jsonObject()``, except the object is in SQLite's binary JSONB format, making it
  /// appropriate for storage contexts, like assignment to a JSONB column.
  public func jsonbObject() -> some QueryExpression<_CodableJSONBRepresentation<QueryValue>> {
    QueryFunction("jsonb_object", SQLQueryExpression(_jsonObjectArguments))
  }

  fileprivate var _jsonObjectArguments: QueryFragment {
    func open<TableColumn: TableColumnExpression>(_ column: TableColumn) -> QueryFragment {
      let value = TableColumn.QueryValue._queryFragment(jsonEncoding: "\(column)")
      return "\(quote: column.name, delimiter: .text), \(value)"
    }
    return $_isSelecting.withValue(false) {
      Self.allColumns
        .map { open($0) }
        .joined(separator: ", ")
    }
  }
}

#if CasePaths && ColumnCoding
  extension TableDefinition where QueryValue: Codable & CasePathable {
    /// A JSON representation of an enum table's columns.
    ///
    /// Produces a single-key JSON object for the table's active case, matching the JSON coding
    /// generated for Codable enum tables.
    public func jsonObject() -> some QueryExpression<_CodableJSONRepresentation<QueryValue>> {
      func open<TableColumn: TableColumnExpression>(_ column: TableColumn) -> QueryFragment {
        TableColumn.QueryValue._queryFragment(jsonEncoding: "\(column)")
      }
      let branches: [QueryFragment] = $_isSelecting.withValue(false) {
        var branches: [QueryFragment] = []
        for child in Mirror(reflecting: self).children {
          if let column = child.value as? any TableColumnExpression {
            branches.append(
              """
              WHEN \(column) IS NOT NULL \
              THEN json_object(\(quote: column.name, delimiter: .text), \(open(column)))
              """
            )
          } else if let group = child.value as? any _JSONColumnGroup {
            let groupColumns = group._jsonGroupColumns
            guard !groupColumns.isEmpty else { continue }
            let condition: QueryFragment =
              groupColumns
              .map { "\($0) IS NOT NULL" }
              .joined(separator: " OR ")
            let object: QueryFragment =
              groupColumns
              .map { "\(quote: $0.name, delimiter: .text), \(open($0))" }
              .joined(separator: ", ")
            branches.append(
              """
              WHEN (\(condition)) \
              THEN json_object(\(quote: group._jsonGroupName, delimiter: .text), json_object(\(object)))
              """
            )
          }
        }
        return branches
      }
      return SQLQueryExpression("CASE \(branches.joined(separator: " ")) END")
    }

    /// A JSON array representation of the aggregation of an enum table's columns.
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

  extension TableDefinition where QueryValue: StructuredQueriesCore._OptionalProtocol & Codable {
    @_documentation(visibility: private)
    public func jsonGroupArray<Wrapped: Codable & CasePathable>(
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

  extension Optional.TableColumns where QueryValue: Codable, Wrapped: CasePathable {
    /// A JSON representation of an enum table's columns.
    ///
    /// Produces a single-key JSON object for the table's active case, matching the JSON coding
    /// generated for Codable enum tables.
    public func jsonObject() -> some QueryExpression<_CodableJSONRepresentation<Wrapped>?> {
      Case().when(rowid.isNot(nil), then: Wrapped.columns.jsonObject())
    }
  }

  private protocol _JSONColumnGroup {
    var _jsonGroupName: String { get }
    var _jsonGroupColumns: [any TableColumnExpression] { get }
  }

  extension ColumnGroup: _JSONColumnGroup {
    fileprivate var _jsonGroupName: String { name }
    fileprivate var _jsonGroupColumns: [any TableColumnExpression] { _allColumns }
  }

  extension CaseColumnGroup: _JSONColumnGroup {
    fileprivate var _jsonGroupName: String { name }
    fileprivate var _jsonGroupColumns: [any TableColumnExpression] { _allColumns }
  }
#endif

extension Optional.TableColumns where QueryValue: Codable {
  /// A JSON representation of a table's columns.
  ///
  /// Useful for referencing a table row in a larger JSON selection.
  public func jsonObject() -> some QueryExpression<_CodableJSONRepresentation<Wrapped>?> {
    Case().when(rowid.isNot(nil), then: Wrapped.columns.jsonObject())
  }

  /// A JSONB representation of a table's columns.
  ///
  /// Works like ``jsonObject()``, except the object is in SQLite's binary JSONB format, making it
  /// appropriate for storage contexts, like assignment to a JSONB column.
  public func jsonbObject() -> some QueryExpression<_CodableJSONBRepresentation<Wrapped>?> {
    Case().when(rowid.isNot(nil), then: Wrapped.columns.jsonbObject())
  }
}

/// A type-safe path into JSON data.
@dynamicMemberLookup
public struct JSONPath<Context, QueryValue> {
  var components: [String] = []
  var caseName: String?

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
  where QueryValue: StructuredQueriesCore._OptionalProtocol, QueryValue.Wrapped: _JSONObjectRepresentation {
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
    QueryValue: StructuredQueriesCore._OptionalProtocol,
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
  where QueryValue: StructuredQueriesCore._OptionalProtocol, QueryValue.Wrapped: _JSONArrayRepresentation {
    JSONPath<_JSONPathElement?, QueryValue.Wrapped._ElementRepresentation>(
      components: components + [.index(index)]
    )
  }

  public subscript(_ index: Int) -> JSONPath<_JSONPathElement?, QueryValue.Wrapped._Element>
  where
    QueryValue: StructuredQueriesCore._OptionalProtocol,
    QueryValue.Wrapped: _JSONArrayRepresentation,
    QueryValue.Wrapped._Element: QueryBindable
  {
    JSONPath<_JSONPathElement?, QueryValue.Wrapped._Element>(
      components: components + [.index(index)]
    )
  }

  public subscript<Object: Table & Codable, Member: Table & Codable>(
    dynamicMember keyPath: KeyPath<Object.TableColumns, ColumnGroup<Object, Member>>
  ) -> JSONPath<Context._Member, _CodableJSONRepresentation<Member>>
  where
    Context: _JSONPathContext,
    QueryValue == _CodableJSONRepresentation<Object>,
    Member.QueryOutput == Member,
    Member._Optionalized == Member?
  {
    JSONPath<Context._Member, _CodableJSONRepresentation<Member>>(
      components: components + [.member(Object.columns[keyPath: keyPath].name)]
    )
  }

  public subscript<Object: Table & Codable, Member: Table & Codable>(
    dynamicMember keyPath: KeyPath<Object.TableColumns, ColumnGroup<Object, Member?>>
  ) -> JSONPath<Context._Member, _CodableJSONRepresentation<Member>?>
  where
    Context: _JSONPathContext,
    QueryValue == _CodableJSONRepresentation<Object>,
    Member.QueryOutput == Member
  {
    JSONPath<Context._Member, _CodableJSONRepresentation<Member>?>(
      components: components + [.member(Object.columns[keyPath: keyPath].name)]
    )
  }

  public subscript<Object: Table & Codable, Member: Table & Codable>(
    dynamicMember keyPath: KeyPath<Object.TableColumns, ColumnGroup<Object, Member>>
  ) -> JSONPath<Context._Member, _CodableJSONBRepresentation<Member>>
  where
    Context: _JSONPathContext,
    QueryValue == _CodableJSONBRepresentation<Object>,
    Member.QueryOutput == Member,
    Member._Optionalized == Member?
  {
    JSONPath<Context._Member, _CodableJSONBRepresentation<Member>>(
      components: components + [.member(Object.columns[keyPath: keyPath].name)]
    )
  }

  public subscript<Object: Table & Codable, Member: Table & Codable>(
    dynamicMember keyPath: KeyPath<Object.TableColumns, ColumnGroup<Object, Member?>>
  ) -> JSONPath<Context._Member, _CodableJSONBRepresentation<Member>?>
  where
    Context: _JSONPathContext,
    QueryValue == _CodableJSONBRepresentation<Object>,
    Member.QueryOutput == Member
  {
    JSONPath<Context._Member, _CodableJSONBRepresentation<Member>?>(
      components: components + [.member(Object.columns[keyPath: keyPath].name)]
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      QueryValue._Object.TableColumns, CaseColumn<QueryValue._Object, Member>
    >
  ) -> JSONPath<Context._Case, Member>
  where Context: _JSONPathContext, QueryValue: _JSONObjectRepresentation {
    let name = QueryValue._Object.columns[keyPath: keyPath].name
    return JSONPath<Context._Case, Member>(
      components: components + [.member(name)],
      caseName: name
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      QueryValue._Object.TableColumns, CaseColumn<QueryValue._Object, Member>
    >
  ) -> JSONPath<Context._Case, Member.QueryOutput>
  where
    Context: _JSONPathContext,
    QueryValue: _JSONObjectRepresentation,
    Member.QueryOutput: QueryBindable
  {
    let name = QueryValue._Object.columns[keyPath: keyPath].name
    return JSONPath<Context._Case, Member.QueryOutput>(
      components: components + [.member(name)],
      caseName: name
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      QueryValue.Wrapped._Object.TableColumns, CaseColumn<QueryValue.Wrapped._Object, Member>
    >
  ) -> JSONPath<_JSONPathCase?, Member>
  where
    QueryValue: StructuredQueriesCore._OptionalProtocol,
    QueryValue.Wrapped: _JSONObjectRepresentation
  {
    let name = QueryValue.Wrapped._Object.columns[keyPath: keyPath].name
    return JSONPath<_JSONPathCase?, Member>(
      components: components + [.member(name)],
      caseName: name
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      QueryValue.Wrapped._Object.TableColumns, CaseColumn<QueryValue.Wrapped._Object, Member>
    >
  ) -> JSONPath<_JSONPathCase?, Member.QueryOutput>
  where
    QueryValue: StructuredQueriesCore._OptionalProtocol,
    QueryValue.Wrapped: _JSONObjectRepresentation,
    Member.QueryOutput: QueryBindable
  {
    let name = QueryValue.Wrapped._Object.columns[keyPath: keyPath].name
    return JSONPath<_JSONPathCase?, Member.QueryOutput>(
      components: components + [.member(name)],
      caseName: name
    )
  }

  public subscript<Object: Table & Codable, Member: Table & Codable>(
    dynamicMember keyPath: KeyPath<Object.TableColumns, CaseColumnGroup<Object, Member>>
  ) -> JSONPath<Context._Case, _CodableJSONRepresentation<Member>>
  where
    Context: _JSONPathContext,
    QueryValue == _CodableJSONRepresentation<Object>,
    Member.QueryOutput == Member
  {
    let name = Object.columns[keyPath: keyPath].name
    return JSONPath<Context._Case, _CodableJSONRepresentation<Member>>(
      components: components + [.member(name)],
      caseName: name
    )
  }

  public subscript<Object: Table & Codable, Member: Table & Codable>(
    dynamicMember keyPath: KeyPath<Object.TableColumns, CaseColumnGroup<Object, Member>>
  ) -> JSONPath<Context._Case, _CodableJSONBRepresentation<Member>>
  where
    Context: _JSONPathContext,
    QueryValue == _CodableJSONBRepresentation<Object>,
    Member.QueryOutput == Member
  {
    let name = Object.columns[keyPath: keyPath].name
    return JSONPath<Context._Case, _CodableJSONBRepresentation<Member>>(
      components: components + [.member(name)],
      caseName: name
    )
  }
}

private struct JSONFunctionExpression<QueryValue>: QueryExpression {
  let base: QueryFragment
  let decode: (QueryFragment) -> QueryFragment

  var queryFragment: QueryFragment {
    _isSelecting ? decode(base) : base
  }
}

private protocol _JSONMutationExpression: QueryExpression
where QueryValue: QueryRepresentable {
  var function: QueryFragment { get }
  var base: QueryFragment { get }
  var arguments: [QueryFragment] { get }
  init(function: QueryFragment, base: QueryFragment, arguments: [QueryFragment])
}

extension _JSONMutationExpression {
  public var queryFragment: QueryFragment {
    let fragment: QueryFragment =
      "\(function)(\(base), \(arguments.joined(separator: ", ")))"
    return _isSelecting ? QueryValue.queryFragment(decoding: fragment) : fragment
  }

  fileprivate func appending(_ argument: QueryFragment) -> Self {
    Self(function: function, base: base, arguments: arguments + [argument])
  }
}

public struct _JSONInsertExpression<QueryValue: QueryRepresentable>: _JSONMutationExpression {
  let function: QueryFragment
  let base: QueryFragment
  let arguments: [QueryFragment]
}

extension _JSONInsertExpression where QueryValue: _JSONRepresentable {
  public func jsonInsert<Member: QueryBindable & StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathMember, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: QueryBindable {
    appending(.jsonArguments(path, .jsonEncoded(value)))
  }

  public func jsonAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where Member._Element: QueryBindable {
    appending(.jsonArguments(path, appending: "[#]", .jsonEncoded(value)))
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue> {
    appending(.jsonArguments(path, appending: "[#]", .jsonEncoded(value)))
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation, Member.Wrapped._Element: QueryBindable {
    appending(.jsonArguments(path, appending: "[#]", .jsonEncoded(value)))
  }

  @_documentation(visibility: private)
  public func jsonAppend<Context: _RequiredJSONPathContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation {
    appending(.jsonArguments(path, appending: "[#]", .jsonEncoded(value)))
  }
}

extension _JSONInsertExpression
where QueryValue: _JSONRepresentable & _JSONArrayRepresentation {
  @_documentation(visibility: private)
  public func jsonAppend(
    _ value: some QueryExpression<QueryValue._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where QueryValue._Element: QueryBindable {
    jsonAppend(\.self, value)
  }

  @_documentation(visibility: private)
  public func jsonAppend(
    _ value: some QueryExpression<QueryValue._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue> {
    jsonAppend(\.self, value)
  }
}

extension _JSONInsertExpression where QueryValue: _JSONBRepresentable {
  public func jsonbInsert<Member: QueryBindable & StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathMember, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: QueryBindable {
    appending(.jsonArguments(path, .jsonEncoded(value)))
  }

  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where Member._Element: QueryBindable {
    appending(.jsonArguments(path, appending: "[#]", .jsonEncoded(value)))
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue> {
    appending(.jsonArguments(path, appending: "[#]", .jsonEncoded(value)))
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation, Member.Wrapped._Element: QueryBindable {
    appending(.jsonArguments(path, appending: "[#]", .jsonEncoded(value)))
  }

  @_documentation(visibility: private)
  public func jsonbAppend<Context: _RequiredJSONPathContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue>
  where Member.Wrapped: _JSONArrayRepresentation {
    appending(.jsonArguments(path, appending: "[#]", .jsonEncoded(value)))
  }
}

extension _JSONInsertExpression
where QueryValue: _JSONBRepresentable & _JSONArrayRepresentation {
  @_documentation(visibility: private)
  public func jsonbAppend(
    _ value: some QueryExpression<QueryValue._Element>
  ) -> _JSONInsertExpression<QueryValue>
  where QueryValue._Element: QueryBindable {
    jsonbAppend(\.self, value)
  }

  @_documentation(visibility: private)
  public func jsonbAppend(
    _ value: some QueryExpression<QueryValue._ElementRepresentation>
  ) -> _JSONInsertExpression<QueryValue> {
    jsonbAppend(\.self, value)
  }
}

public struct _JSONRemoveExpression<QueryValue: QueryRepresentable>: _JSONMutationExpression {
  let function: QueryFragment
  let base: QueryFragment
  let arguments: [QueryFragment]
}

extension _JSONRemoveExpression where QueryValue: _JSONRepresentable {
  public func jsonRemove<Context: _JSONPathMemberContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> _JSONRemoveExpression<QueryValue> {
    appending(.jsonArguments(path))
  }

  public func jsonRemove<Context: _JSONPathElementContext, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> _JSONRemoveExpression<QueryValue> {
    appending(.jsonArguments(path))
  }
}

extension _JSONRemoveExpression where QueryValue: _JSONBRepresentable {
  public func jsonbRemove<Context: _JSONPathMemberContext, Member: StructuredQueriesCore._OptionalProtocol>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> _JSONRemoveExpression<QueryValue> {
    appending(.jsonArguments(path))
  }

  public func jsonbRemove<Context: _JSONPathElementContext, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> _JSONRemoveExpression<QueryValue> {
    appending(.jsonArguments(path))
  }
}

public struct _JSONReplaceExpression<QueryValue: QueryRepresentable>: _JSONMutationExpression {
  let function: QueryFragment
  let base: QueryFragment
  let arguments: [QueryFragment]
}

extension _JSONReplaceExpression where QueryValue: _JSONRepresentable {
  public func jsonReplace<Context: _JSONPathMemberContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> _JSONReplaceExpression<QueryValue>
  where Member: StructuredQueriesCore._OptionalProtocol, Member.Wrapped: QueryBindable {
    appending(.jsonArguments(path, .jsonEncoded(value)))
  }

  public func jsonReplace<Context: _JSONPathElementContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONReplaceExpression<QueryValue> {
    appending(.jsonArguments(path, .jsonEncoded(value)))
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func jsonReplace<
    Context: _JSONPathMemberContext & _OptionalJSONPathContext, Member: QueryBindable
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONReplaceExpression<QueryValue> {
    appending(.jsonArguments(path, .jsonEncoded(value)))
  }
}

extension _JSONReplaceExpression where QueryValue: _JSONBRepresentable {
  public func jsonbReplace<Context: _JSONPathMemberContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member.Wrapped>
  ) -> _JSONReplaceExpression<QueryValue>
  where Member: StructuredQueriesCore._OptionalProtocol, Member.Wrapped: QueryBindable {
    appending(.jsonArguments(path, .jsonEncoded(value)))
  }

  public func jsonbReplace<Context: _JSONPathElementContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONReplaceExpression<QueryValue> {
    appending(.jsonArguments(path, .jsonEncoded(value)))
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func jsonbReplace<
    Context: _JSONPathMemberContext & _OptionalJSONPathContext, Member: QueryBindable
  >(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONReplaceExpression<QueryValue> {
    appending(.jsonArguments(path, .jsonEncoded(value)))
  }
}

public struct _JSONSetExpression<QueryValue: QueryRepresentable>: _JSONMutationExpression {
  let function: QueryFragment
  let base: QueryFragment
  let arguments: [QueryFragment]
}

extension _JSONSetExpression where QueryValue: _JSONRepresentable {
  public func jsonSet<Context: _RequiredJSONPathContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONSetExpression<QueryValue> {
    appending(.jsonSetArguments("json_object", path, .jsonEncoded(value)))
  }

  @_documentation(visibility: private)
  public func jsonSet<Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathCase, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONSetExpression<QueryValue> {
    appending(.jsonSetArguments("json_object", path, .jsonEncoded(value)))
  }
}

extension _JSONSetExpression where QueryValue: _JSONBRepresentable {
  public func jsonbSet<Context: _RequiredJSONPathContext, Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONSetExpression<QueryValue> {
    appending(.jsonSetArguments("jsonb_object", path, .jsonEncoded(value)))
  }

  @_documentation(visibility: private)
  public func jsonbSet<Member: QueryBindable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<_JSONPathCase, Member>>,
    _ value: some QueryExpression<Member>
  ) -> _JSONSetExpression<QueryValue> {
    appending(.jsonSetArguments("jsonb_object", path, .jsonEncoded(value)))
  }
}

public enum _JSONPathRoot {}
public enum _JSONPathMember {}
public enum _JSONPathElement {}
public enum _JSONPathCase {}

public protocol _JSONPathContext {
  associatedtype _Member = _JSONPathMember
  associatedtype _Element = _JSONPathElement
  associatedtype _Case = _JSONPathCase
}

extension _JSONPathRoot: _JSONPathContext {}
extension _JSONPathMember: _JSONPathContext {}
extension _JSONPathElement: _JSONPathContext {}

extension _JSONPathCase: _JSONPathContext {
  public typealias _Member = _JSONPathMember?
  public typealias _Element = _JSONPathElement?
  public typealias _Case = _JSONPathCase?
}

extension Optional: _JSONPathContext {
  public typealias _Member = _JSONPathMember?
  public typealias _Element = _JSONPathElement?
  public typealias _Case = _JSONPathCase?
}

public protocol _OptionalJSONPathContext {}
extension Optional: _OptionalJSONPathContext {}
extension _JSONPathCase: _OptionalJSONPathContext {}

public protocol _RequiredJSONPathContext {}
extension _JSONPathRoot: _RequiredJSONPathContext {}
extension _JSONPathMember: _RequiredJSONPathContext {}
extension _JSONPathElement: _RequiredJSONPathContext {}

public protocol _JSONPathMemberContext {}
extension _JSONPathMember: _JSONPathMemberContext {}
extension _JSONPathCase: _JSONPathMemberContext {}
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

  fileprivate static func jsonSetArguments<Root, Context, Member>(
    _ objectFunction: QueryFragment,
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>,
    _ value: QueryFragment
  ) -> QueryFragment {
    let path = JSONPath()[keyPath: path]
    guard let caseName = path.caseName
    else {
      return "\(quote: path.pathString, delimiter: .text), \(value)"
    }
    return """
      \(quote: "$" + path.components.dropLast().joined(), delimiter: .text), \
      \(objectFunction)(\(quote: caseName, delimiter: .text), \(value))
      """
  }

  fileprivate static func jsonArguments<Root, Context, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>,
    appending suffix: String = ""
  ) -> QueryFragment {
    "\(quote: JSONPath()[keyPath: path].pathString + suffix, delimiter: .text)"
  }

  fileprivate static func jsonArguments<Root, Context, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>,
    appending suffix: String = "",
    _ value: QueryFragment
  ) -> QueryFragment {
    "\(jsonArguments(path, appending: suffix)), \(value)"
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
