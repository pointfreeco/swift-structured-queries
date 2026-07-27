import Foundation
public import StructuredQueriesCore

extension QueryExpression where QueryValue: _AnyJSONRepresentable & _JSONArrayRepresentation {
  /// A select statement that iterates over the elements of this JSON array expression using the
  /// `json_each` table-valued function.
  ///
  /// The resulting statement can be filtered, ordered, and selected from like any other. Elements
  /// that are JSON objects have their fields addressed in a type-safe, schema-safe fashion:
  ///
  /// ```swift
  /// Trip.where {
  ///   !$0.geofence.jsonEach()
  ///     .where { $0.latitude < 0 }
  ///     .exists()
  /// }
  /// // SELECT … FROM "trips"
  /// // WHERE NOT (EXISTS (
  /// //   SELECT … FROM json_each("trips"."geofence")
  /// //   WHERE (json_extract("json_each"."value", '$."latitude"') < 0.0)
  /// // ))
  /// ```
  ///
  /// Scalar elements have no fields to project, and are addressed through
  /// ``JSONEach/TableColumns/value``:
  ///
  /// ```swift
  /// Reminder.where {
  ///   $0.tags.jsonEach()
  ///     .where { $0.value.eq("urgent") }
  ///     .exists()
  /// }
  /// // SELECT … FROM "reminders"
  /// // WHERE EXISTS (
  /// //   SELECT "json_each"."value"
  /// //   FROM json_each("reminders"."tags")
  /// //   WHERE (("json_each"."value") = ('urgent'))
  /// // )
  /// ```
  ///
  /// - Returns: A select statement over the elements of this JSON array.
  public func jsonEach() -> SelectOf<JSONEach<Int, QueryValue._Element>>
  where QueryValue._Element: QueryRepresentable {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }
}

extension QueryExpression
where QueryValue: _AnyJSONRepresentable & _JSONDictionaryRepresentation {
  /// A select statement that iterates over the values of this JSON object expression using the
  /// `json_each` table-valued function.
  ///
  /// Works like ``jsonEach()-(())`` over a JSON array, except each row's
  /// ``JSONEach/TableColumns/key`` is the object's member name rather than an array index:
  ///
  /// ```swift
  /// Product.where {
  ///   $0.inventory.jsonEach()
  ///     .where { $0.key.eq("SFO") && $0.onHand.eq(0) }
  ///     .exists()
  /// }
  /// // SELECT … FROM "products"
  /// // WHERE EXISTS (
  /// //   SELECT … FROM json_each("products"."inventory")
  /// //   WHERE (("json_each"."key") = ('SFO'))
  /// //     AND ((json_extract("json_each"."value", '$."onHand"')) = (0))
  /// // )
  /// ```
  ///
  /// - Returns: A select statement over the values of this JSON object.
  public func jsonEach() -> SelectOf<JSONEach<QueryValue._Key, QueryValue._Value>>
  where QueryValue._Value: QueryRepresentable {
    JSONEach.select(from: "json_each(\(argumentFragment))")
  }
}

extension QueryExpression where QueryValue: _AnyJSONRepresentable {
  /// A select statement that iterates over the elements of a JSON array at the given path in
  /// this JSON expression using the `json_each` table-valued function.
  ///
  /// ```swift
  /// Profile.where {
  ///   $0.author.jsonEach(\.links)
  ///     .where { $0.isActive }
  ///     .exists()
  /// }
  /// // SELECT … FROM "profiles"
  /// // WHERE EXISTS (
  /// //   SELECT … FROM json_each("profiles"."author", '$."links"')
  /// //   WHERE json_extract("json_each"."value", '$."isActive"')
  /// // )
  /// ```
  ///
  /// - Parameter path: A key path from the JSON expression to an array.
  /// - Returns: A select statement over the elements of the JSON array at the given path.
  public func jsonEach<Context, Member: _JSONArrayRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Int, Member._Element>>
  where Member._Element: QueryRepresentable {
    JSONEach.select(from: jsonEachFragment(path))
  }

  /// A select statement that iterates over the values of a JSON object at the given path in this
  /// JSON expression using the `json_each` table-valued function.
  ///
  /// - Parameter path: A key path from the JSON expression to an object.
  /// - Returns: A select statement over the values of the JSON object at the given path.
  public func jsonEach<Context, Member: _JSONDictionaryRepresentation>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Member._Key, Member._Value>>
  where Member._Value: QueryRepresentable {
    JSONEach.select(from: jsonEachFragment(path))
  }
}

/// A table representing SQLite's `json_each` table-valued function iterating over a JSON array
/// of `Element` values.
///
/// Statements of this table are created by applying
/// ``StructuredQueriesCore/QueryExpression/jsonEach()`` to a JSON array expression. Its columns
/// are derived from `Element`'s columns, with each member rendered as a `json_extract` of the
/// current array element.
///
/// > Note: This table has no meaning independent of a JSON array expression, so avoid using its
/// > static entry points (`all`, `where`, etc.) directly. Always derive statements from
/// > `jsonEach()`.
public struct JSONEach<Key: QueryRepresentable, Element: QueryRepresentable & Codable>: Table {
  public static var tableName: String { "json_each" }

  public static var columns: TableColumns { TableColumns() }

  public static var _columnWidth: Int {
    (Element.self as? any Table.Type)?._columnWidth ?? 1
  }

  let element: Element

  package subscript<Member: QueryRepresentable>(
    member _: KeyPath<Member, Member>,
    column keyPath: KeyPath<Element, Member.QueryOutput>
  ) -> Member.QueryOutput {
    element[keyPath: keyPath]
  }

  fileprivate static func select(from tableReference: QueryFragment) -> SelectOf<JSONEach> {
    var select = all.asSelect()
    select._tableReference = tableReference
    return select
  }

  @dynamicMemberLookup
  public struct TableColumns: TableDefinition, Sendable {
    public typealias QueryValue = JSONEach

    public static var allColumns: [any TableColumnExpression] {
      func openTable<T: Table>(_: T.Type) -> [any TableColumnExpression] {
        func open<Column: TableColumnExpression>(
          _ column: Column
        ) -> any TableColumnExpression {
          _JSONEachColumn<JSONEach, Column.Value>(
            column.name,
            keyPath:
              \.[
                member: \Column.Value.self,
                column: column.keyPath as! KeyPath<Element, Column.Value.QueryOutput>
              ]
          )
        }
        return T.TableColumns.allColumns.map { open($0) }
      }
      func openScalar<V: QueryRepresentable & QueryBindable>(_: V.Type)
        -> [any TableColumnExpression]
      {
        [
          _JSONEachValueColumn<JSONEach, V>(
            keyPath: \JSONEach.element as! KeyPath<JSONEach, V.QueryOutput>
          )
        ]
      }
      if let elementType = Element.self as? any Table.Type {
        return openTable(elementType)
      } else if let elementType = Element.self as? any (QueryRepresentable & QueryBindable).Type {
        return openScalar(elementType)
      } else {
        // TODO: Report issue?
        return []
      }
    }

    public static var writableColumns: [any WritableTableColumnExpression] { [] }

    /// The key of the current element in the JSON collection.
    public var key: SQLQueryExpression<Key> {
      SQLQueryExpression("\(JSONEach.self).\(quote: "key")")
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

extension JSONEach.TableColumns where Element: Table {
  /// The current element of the JSON collection as a JSON expression.
  public var value: SQLQueryExpression<_CodableJSONRepresentation<Element>> {
    SQLQueryExpression("\(JSONEach.self).\(quote: "value")")
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Element.TableColumns, TableColumn<Element, Member>>
  ) -> _JSONEachColumn<JSONEach, Member> {
    let column = Element.columns[keyPath: keyPath]
    return _JSONEachColumn(
      column.name,
      keyPath: \.[member: \Member.self, column: column.keyPath]
    )
  }
}

extension JSONEach.TableColumns where Element: QueryBindable, Element.QueryOutput == Element {
  /// The current element of the JSON collection.
  public var value: SQLQueryExpression<Element> {
    SQLQueryExpression("\(JSONEach.self).\(quote: "value")")
  }
}

extension JSONEach: QueryRepresentable {
  public typealias QueryOutput = Element

  public init(queryOutput: Element) {
    self.element = queryOutput
  }

  public var queryOutput: Element {
    element
  }
}

extension JSONEach: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(queryOutput: Element(decoder: &decoder))
  }
}

extension JSONEach: Sendable where Key: Sendable, Element: Sendable {}

/// A column of a ``JSONEach`` table.
///
/// A value of this type is returned from dynamic member lookup on ``JSONEach/TableColumns``. It
/// renders as a `json_extract` of the corresponding field of the current JSON array element.
public struct _JSONEachColumn<Root: Table, Value: QueryRepresentable & QueryBindable>:
  TableColumnExpression
{
  public typealias QueryValue = Value

  public let name: String

  public let defaultValue: Value.QueryOutput?

  public let keyPath: KeyPath<Root, Value.QueryOutput>

  init(
    _ name: String,
    keyPath: KeyPath<Root, Value.QueryOutput>,
    default defaultValue: Value.QueryOutput? = nil
  ) {
    self.name = name
    self.keyPath = keyPath
    self.defaultValue = defaultValue
  }

  public var queryFragment: QueryFragment {
    let column: QueryFragment = Value._queryFragment(
      jsonDecoding: """
        json_extract(\(Root.self).\(quote: "value"), \(quote: jsonPath, delimiter: .text))
        """
    )
    return _isSelecting ? Value.queryFragment(decoding: column) : column
  }

  private var jsonPath: String {
    let escapedName =
      name
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "$.\"\(escapedName)\""
  }

  public func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Root, Name>, Value> {
    _JSONEachColumn<TableAlias<Root, Name>, Value>(
      name,
      keyPath: \.[member: \Value.self, column: keyPath]
    )
  }
}

/// A column of a ``JSONEach`` table over scalar elements.
///
/// A value of this type renders as the `value` column of the current row, decoded as `Value`.
public struct _JSONEachValueColumn<Root: Table, Value: QueryRepresentable & QueryBindable>:
  TableColumnExpression
{
  public typealias QueryValue = Value

  public let name = "value"

  public let defaultValue: Value.QueryOutput? = nil

  public let keyPath: KeyPath<Root, Value.QueryOutput>

  init(keyPath: KeyPath<Root, Value.QueryOutput>) {
    self.keyPath = keyPath
  }

  public var queryFragment: QueryFragment {
    let column: QueryFragment = "\(Root.self).\(quote: "value")"
    return _isSelecting ? Value.queryFragment(decoding: column) : column
  }

  public func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Root, Name>, Value> {
    _JSONEachValueColumn<TableAlias<Root, Name>, Value>(
      keyPath: \.[member: \Value.self, column: keyPath]
    )
  }
}

extension QueryExpression {
  fileprivate var argumentFragment: QueryFragment {
    $_isSelecting.withValue(false) { queryFragment }
  }

  fileprivate func jsonEachFragment<Root, Context, Member>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, Root>, JSONPath<Context, Member>>
  ) -> QueryFragment {
    """
    json_each(\
    \(argumentFragment), \
    \(quote: JSONPath()[keyPath: path].pathString, delimiter: .text)\
    )
    """
  }
}
