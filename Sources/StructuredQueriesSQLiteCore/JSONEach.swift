import Foundation
public import StructuredQueriesCore

extension QueryExpression where QueryValue: _AnyJSONRepresentable & _JSONArrayRepresentation {
  /// A select statement that iterates over the object elements of this JSON array expression
  /// using the `json_each` table-valued function.
  ///
  /// ```swift
  /// Trip.where {
  ///   !$0.geofence.jsonEach()
  ///     .where { $0.value.jsonExtract(\.latitude) < 0 }
  ///     .exists()
  /// }
  /// ```
  ///
  /// - Returns: A select statement over the elements of this JSON array.
  public func jsonEach() -> SelectOf<JSONEach<Int, QueryValue._ElementRepresentation>>
  where QueryValue._ElementRepresentation: _JSONObjectRepresentation & QueryBindable {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }

  /// A select statement that iterates over the scalar elements of this JSON array expression
  /// using the `json_each` table-valued function.
  ///
  /// ```swift
  /// Reminder.where {
  ///   $0.tags.jsonEach().where { $0.value.eq("urgent") }.exists()
  /// }
  /// ```
  ///
  /// - Returns: A select statement over the elements of this JSON array.
  public func jsonEach() -> SelectOf<JSONEach<Int, QueryValue._Element>>
  where QueryValue._Element: QueryRepresentable & QueryBindable {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }
}

extension QueryExpression
where QueryValue: _AnyJSONRepresentable & _JSONDictionaryRepresentation {
  /// A select statement that iterates over the object values of this JSON object expression using
  /// the `json_each` table-valued function.
  ///
  /// Each row's ``JSONEach/TableColumns/key`` is the object's member name.
  ///
  /// - Returns: A select statement over the values of this JSON object.
  public func jsonEach() -> SelectOf<JSONEach<QueryValue._Key, QueryValue._ValueRepresentation>>
  where
    QueryValue._Key: QueryBindable,
    QueryValue._ValueRepresentation: _JSONObjectRepresentation & QueryBindable
  {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }

  /// A select statement that iterates over the scalar values of this JSON object expression using
  /// the `json_each` table-valued function.
  ///
  /// - Returns: A select statement over the values of this JSON object.
  public func jsonEach() -> SelectOf<JSONEach<QueryValue._Key, QueryValue._Value>>
  where QueryValue._Key: QueryBindable, QueryValue._Value: QueryRepresentable & QueryBindable {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }
}

extension QueryExpression
where
  QueryValue: StructuredQueriesCore._OptionalProtocol,
  QueryValue.Wrapped: _JSONArrayRepresentation
{
  /// A select statement that iterates over the object elements of this optional JSON array
  /// expression using the `json_each` table-valued function.
  ///
  /// A `NULL` JSON expression iterates as an empty collection.
  ///
  /// - Returns: A select statement over the elements of this JSON array.
  public func jsonEach() -> SelectOf<JSONEach<Int, QueryValue.Wrapped._ElementRepresentation>>
  where QueryValue.Wrapped._ElementRepresentation: _JSONObjectRepresentation & QueryBindable {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }

  /// A select statement that iterates over the scalar elements of this optional JSON array
  /// expression using the `json_each` table-valued function.
  ///
  /// A `NULL` JSON expression iterates as an empty collection.
  ///
  /// - Returns: A select statement over the elements of this JSON array.
  public func jsonEach() -> SelectOf<JSONEach<Int, QueryValue.Wrapped._Element>>
  where QueryValue.Wrapped._Element: QueryRepresentable & QueryBindable {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }
}

extension QueryExpression
where
  QueryValue: StructuredQueriesCore._OptionalProtocol,
  QueryValue.Wrapped: _JSONDictionaryRepresentation
{
  /// A select statement that iterates over the object values of this optional JSON object
  /// expression using the `json_each` table-valued function.
  ///
  /// A `NULL` JSON expression iterates as an empty collection.
  ///
  /// - Returns: A select statement over the values of this JSON object.
  public func jsonEach()
    -> SelectOf<JSONEach<QueryValue.Wrapped._Key, QueryValue.Wrapped._ValueRepresentation>>
  where
    QueryValue.Wrapped._Key: QueryBindable,
    QueryValue.Wrapped._ValueRepresentation: _JSONObjectRepresentation & QueryBindable
  {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }

  /// A select statement that iterates over the scalar values of this optional JSON object
  /// expression using the `json_each` table-valued function.
  ///
  /// A `NULL` JSON expression iterates as an empty collection.
  ///
  /// - Returns: A select statement over the values of this JSON object.
  public func jsonEach()
    -> SelectOf<JSONEach<QueryValue.Wrapped._Key, QueryValue.Wrapped._Value>>
  where
    QueryValue.Wrapped._Key: QueryBindable,
    QueryValue.Wrapped._Value: QueryRepresentable & QueryBindable
  {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }
}

extension QueryExpression where QueryValue: _AnyJSONRepresentable {
  /// A select statement that iterates over the object elements of a JSON array at the given path.
  ///
  /// - Parameter path: A key path from the JSON expression to an array.
  /// - Returns: A select statement over the elements of the JSON array at the given path.
  public func jsonEach<Context, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Int, Member._ElementRepresentation>>
  where Member._ElementRepresentation: _JSONObjectRepresentation & QueryBindable {
    JSONEach.select(from: jsonEachFragment(path))
  }

  /// A select statement that iterates over the scalar elements of a JSON array at the given path.
  ///
  /// - Parameter path: A key path from the JSON expression to an array.
  /// - Returns: A select statement over the elements of the JSON array at the given path.
  public func jsonEach<Context, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Int, Member._Element>>
  where Member._Element: QueryRepresentable & QueryBindable {
    JSONEach.select(from: jsonEachFragment(path))
  }

  /// A select statement that iterates over the object values of a JSON object at the given path.
  ///
  /// - Parameter path: A key path from the JSON expression to an object.
  /// - Returns: A select statement over the values of the JSON object at the given path.
  public func jsonEach<Context, Member: _JSONDictionaryRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Member._Key, Member._ValueRepresentation>>
  where
    Member._Key: QueryBindable,
    Member._ValueRepresentation: _JSONObjectRepresentation & QueryBindable
  {
    JSONEach.select(from: jsonEachFragment(path))
  }

  /// A select statement that iterates over the scalar values of a JSON object at the given path.
  ///
  /// - Parameter path: A key path from the JSON expression to an object.
  /// - Returns: A select statement over the values of the JSON object at the given path.
  public func jsonEach<Context, Member: _JSONDictionaryRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Member._Key, Member._Value>>
  where Member._Key: QueryBindable, Member._Value: QueryRepresentable & QueryBindable {
    JSONEach.select(from: jsonEachFragment(path))
  }
}

extension QueryExpression where QueryValue: _AnyJSONRepresentable & _JSONArrayRepresentation {
  /// A select statement that iterates over the object elements of this JSON array expression
  /// using the `jsonb_each` table-valued function.
  ///
  /// Works like ``jsonEach()-(())``, except each element is decoded from SQLite's binary JSONB
  /// format instead of text JSON, avoiding a parse of the element's JSON.
  ///
  /// - Returns: A select statement over the elements of this JSON array.
  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  public func jsonbEach<Element: Table & Codable>()
    -> SelectOf<JSONEach<Int, _CodableJSONBRepresentation<Element>>>
  where QueryValue._ElementRepresentation: _JSONObjectRepresentation<Element> {
    JSONEach.select(from: "jsonb_each(\(argumentFragment))")
  }
}

extension QueryExpression
where QueryValue: _AnyJSONRepresentable & _JSONDictionaryRepresentation {
  /// A select statement that iterates over the object values of this JSON object expression using
  /// the `jsonb_each` table-valued function.
  ///
  /// - Returns: A select statement over the values of this JSON object.
  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  public func jsonbEach<Element: Table & Codable>()
    -> SelectOf<JSONEach<QueryValue._Key, _CodableJSONBRepresentation<Element>>>
  where
    QueryValue._Key: QueryBindable,
    QueryValue._ValueRepresentation: _JSONObjectRepresentation<Element>
  {
    JSONEach.select(from: "jsonb_each(\(argumentFragment))")
  }
}

extension QueryExpression
where
  QueryValue: StructuredQueriesCore._OptionalProtocol,
  QueryValue.Wrapped: _JSONArrayRepresentation
{
  /// A select statement that iterates over the object elements of this optional JSON array
  /// expression using the `jsonb_each` table-valued function.
  ///
  /// - Returns: A select statement over the elements of this JSON array.
  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  public func jsonbEach<Element: Table & Codable>()
    -> SelectOf<JSONEach<Int, _CodableJSONBRepresentation<Element>>>
  where QueryValue.Wrapped._ElementRepresentation: _JSONObjectRepresentation<Element> {
    JSONEach.select(from: "jsonb_each(\(argumentFragment))")
  }
}

extension QueryExpression
where
  QueryValue: StructuredQueriesCore._OptionalProtocol,
  QueryValue.Wrapped: _JSONDictionaryRepresentation
{
  /// A select statement that iterates over the object values of this optional JSON object
  /// expression using the `jsonb_each` table-valued function.
  ///
  /// - Returns: A select statement over the values of this JSON object.
  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  public func jsonbEach<Element: Table & Codable>()
    -> SelectOf<JSONEach<QueryValue.Wrapped._Key, _CodableJSONBRepresentation<Element>>>
  where
    QueryValue.Wrapped._Key: QueryBindable,
    QueryValue.Wrapped._ValueRepresentation: _JSONObjectRepresentation<Element>
  {
    JSONEach.select(from: "jsonb_each(\(argumentFragment))")
  }
}

extension QueryExpression where QueryValue: _AnyJSONRepresentable {
  /// A select statement that iterates over the object elements of a JSON array at the given path
  /// using the `jsonb_each` table-valued function.
  ///
  /// - Parameter path: A key path from the JSON expression to an array.
  /// - Returns: A select statement over the elements of the JSON array at the given path.
  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  public func jsonbEach<Context, Member: _JSONArrayRepresentation, Element: Table & Codable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Int, _CodableJSONBRepresentation<Element>>>
  where Member._ElementRepresentation: _JSONObjectRepresentation<Element> {
    JSONEach.select(from: jsonbEachFragment(path))
  }

  /// A select statement that iterates over the object values of a JSON object at the given path
  /// using the `jsonb_each` table-valued function.
  ///
  /// - Parameter path: A key path from the JSON expression to an object.
  /// - Returns: A select statement over the values of the JSON object at the given path.
  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  public func jsonbEach<Context, Member: _JSONDictionaryRepresentation, Element: Table & Codable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Member._Key, _CodableJSONBRepresentation<Element>>>
  where
    Member._Key: QueryBindable,
    Member._ValueRepresentation: _JSONObjectRepresentation<Element>
  {
    JSONEach.select(from: jsonbEachFragment(path))
  }
}

/// A table representing SQLite's `json_each` table-valued function iterating over a JSON
/// collection.
///
/// Statements of this table are created by applying
/// ``StructuredQueriesCore/QueryExpression/jsonEach()`` to a JSON expression. It has the two
/// columns `json_each` exposes: ``TableColumns/key`` and ``TableColumns/value``. Reach into the
/// fields of an object element with `jsonExtract` on ``TableColumns/value``.
///
/// > Note: This table has no meaning independent of a JSON expression, so avoid using its static
/// > entry points (`all`, `where`, etc.) directly. Always derive statements from `jsonEach()`.
public struct JSONEach<
  Key: QueryRepresentable & QueryBindable,
  Value: QueryRepresentable & QueryBindable
>: Table {
  public static var tableName: String { "json_each" }

  public static var columns: TableColumns { TableColumns() }

  public static var _columnWidth: Int { 2 }

  /// The key of the current element: its index in a JSON array, or its name in a JSON object.
  public let key: Key.QueryOutput

  /// The current element of the JSON collection.
  public let value: Value.QueryOutput

  fileprivate static func select(from tableReference: QueryFragment) -> SelectOf<JSONEach> {
    var select = all.asSelect()
    select._tableReference = tableReference
    return select
  }

  public struct TableColumns: TableDefinition, Sendable {
    public typealias QueryValue = JSONEach

    public static var allColumns: [any TableColumnExpression] {
      [TableColumns().key, TableColumns().value]
    }

    public static var writableColumns: [any WritableTableColumnExpression] { [] }

    /// The key of the current element: its index in a JSON array, or its name in a JSON object.
    public var key: GeneratedColumn<JSONEach, Key> {
      GeneratedColumn("key", keyPath: \JSONEach.key)
    }

    /// The current element of the JSON collection.
    public var value: GeneratedColumn<JSONEach, Value> {
      GeneratedColumn("value", keyPath: \JSONEach.value)
    }
  }

  public struct Selection: TableExpression {
    public typealias QueryValue = JSONEach

    public var allColumns: [any QueryExpression]

    public init(allColumns: [any QueryExpression]) {
      self.allColumns = allColumns
    }
  }
}

extension JSONEach: QueryRepresentable {
  public typealias QueryOutput = JSONEach
}

extension JSONEach: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    self.key = try Key(decoder: &decoder).queryOutput
    self.value = try Value(decoder: &decoder).queryOutput
  }
}

extension JSONEach: Sendable where Key.QueryOutput: Sendable, Value.QueryOutput: Sendable {}

extension JSONEach: Equatable where Key.QueryOutput: Equatable, Value.QueryOutput: Equatable {}

extension QueryExpression {
  fileprivate var argumentFragment: QueryFragment {
    $_isSelecting.withValue(false) { queryFragment }
  }

  fileprivate func jsonEachFragment<Root, Context, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> QueryFragment {
    eachFragment("json_each", path)
  }

  fileprivate func jsonbEachFragment<Root, Context, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> QueryFragment {
    eachFragment("jsonb_each", path)
  }

  private func eachFragment<Root, Context, Member>(
    _ function: QueryFragment,
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> QueryFragment {
    """
    \(function)(\
    \(argumentFragment), \
    \(quote: JSONPath()[keyPath: path].pathString, delimiter: .text)\
    )
    """
  }
}
