import Foundation
public import StructuredQueriesCore

extension QueryExpression where QueryValue: _AnyJSONRepresentable & _JSONArrayRepresentation {
  /// A select statement that iterates over the elements of this JSON array expression using the
  /// `json_each` table-valued function.
  ///
  /// The resulting statement can be filtered, ordered, and selected from like any other, with
  /// each element's fields addressed in a type-safe, schema-safe fashion:
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
  /// - Returns: A select statement over the elements of this JSON array.
  public func jsonEach<Element: Codable>() -> SelectOf<JSONEach<Element>>
  where QueryValue._ElementRepresentation: _JSONObjectRepresentation<Element> {
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
  /// - Parameter path: A key path from the JSON expression to an array of objects.
  /// - Returns: A select statement over the elements of the JSON array at the given path.
  public func jsonEach<Context, Member: _JSONArrayRepresentation, Element: Codable>(
    _ path: KeyPath<JSONPath<_JSONPathRoot, QueryValue>, JSONPath<Context, Member>>
  ) -> SelectOf<JSONEach<Element>>
  where Member._ElementRepresentation: _JSONObjectRepresentation<Element> {
    JSONEach.select(
      from: """
        json_each(\
        \(argumentFragment), \
        \(quote: JSONPath()[keyPath: path].pathString, delimiter: .text)\
        )
        """
    )
  }
}

/// A table representing SQLite's `json_each` table-valued function iterating over a JSON array
/// of `Element` values.
///
/// Statements of this table are created by applying ``StructuredQueriesCore/QueryExpression/jsonEach()``
/// to a JSON array expression. Its columns are derived from `Element`'s columns, with each member
/// rendered as a `json_extract` of the current array element.
///
/// > Note: This table has no meaning independent of a JSON array expression, so avoid using its
/// > static entry points (`all`, `where`, etc.) directly. Always derive statements from
/// > `jsonEach()`.
public struct JSONEach<Element: Table & Codable>: Table {
  public static var tableName: String { "json_each" }

  public static var columns: TableColumns { TableColumns() }

  public static var _columnWidth: Int { Element._columnWidth }

  let element: Element

  package subscript<Member: QueryRepresentable>(
    member _: KeyPath<Member, Member>,
    column keyPath: KeyPath<Element, Member.QueryOutput>
  ) -> Member.QueryOutput {
    element[keyPath: keyPath]
  }

  fileprivate static func select(from: QueryFragment) -> SelectOf<JSONEach> {
    var select = all.asSelect()
    select._from = from
    return select
  }

  @dynamicMemberLookup
  public struct TableColumns: TableDefinition, Sendable {
    public typealias QueryValue = JSONEach

    public static var allColumns: [any TableColumnExpression] {
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
      return Element.TableColumns.allColumns.map { open($0) }
    }

    public static var writableColumns: [any WritableTableColumnExpression] { [] }

    /// The index of the current element in the JSON array.
    public var key: SQLQueryExpression<Int> {
      SQLQueryExpression("\(JSONEach.self).\(quote: "key")")
    }

    /// The current element of the JSON array as a JSON expression.
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

  public struct Selection: TableExpression {
    public typealias QueryValue = JSONEach

    public var allColumns: [any QueryExpression]

    public init(allColumns: [any QueryExpression]) {
      self.allColumns = allColumns
    }
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

extension JSONEach: Sendable where Element: Sendable {}

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

extension QueryExpression {
  fileprivate var argumentFragment: QueryFragment {
    $_isSelecting.withValue(false) { queryFragment }
  }
}
