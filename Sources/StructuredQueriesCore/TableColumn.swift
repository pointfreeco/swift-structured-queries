/// A type representing a table column.
///
/// This protocol has a single conformance, ``TableColumn``, and simply provides type erasure over
/// a table's columns. You should not conform to this protocol directly.
public protocol TableColumnExpression<Root, Value>: QueryExpression where Value == QueryValue {
  associatedtype Root: Table
  associatedtype Value: QueryRepresentable & QueryExpression

  /// The name of the table column.
  var name: String { get }

  /// The default value of the table column.
  var defaultValue: Value.QueryOutput? { get }

  /// The table model key path associated with this table column.
  var keyPath: KeyPath<Root, Value.QueryOutput> { get }

  func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Root, Name>, Value>
}

/// A type representing a table column.
///
/// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros to
/// generate values of this type.
@dynamicMemberLookup
public struct TableColumn<Root: Table, Value: QueryRepresentable & QueryExpression>:
  TableColumnExpression,
  Sendable
where Value.QueryOutput: Sendable {
  public typealias QueryValue = Value

  public let name: String

  public let defaultValue: Value.QueryOutput?

  let _keyPath: KeyPath<Root, Value.QueryOutput> & Sendable

  public var keyPath: KeyPath<Root, Value.QueryOutput> {
    _keyPath
  }

  public init(
    _ name: String,
    keyPath: KeyPath<Root, Value.QueryOutput> & Sendable,
    default defaultValue: Value.QueryOutput? = nil
  ) {
    self.name = name
    self.defaultValue = defaultValue
    self._keyPath = keyPath
  }

  public init(
    _ name: String,
    keyPath: KeyPath<Root, Value.QueryOutput> & Sendable,
    default defaultValue: Value? = nil
  ) where Value == Value.QueryOutput {
    self.name = name
    self.defaultValue = defaultValue
    self._keyPath = keyPath
  }

  public func decode(_ decoder: inout some QueryDecoder) throws -> Value.QueryOutput {
    try Value(decoder: &decoder).queryOutput
  }

  public var queryFragment: QueryFragment {
    "\(Root.self).\(quote: name)"
  }

  public func _aliased<Name>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Root, Name>, Value> {
    TableColumn<TableAlias<Root, Name>, Value>(
      name,
      keyPath: \.[member: \Value.self, column: _keyPath]
    )
  }
}

extension TableColumn where Value: Table {
  public subscript<Member>(dynamicMember keyPath: KeyPath<Value, Member> & Sendable) -> TableColumn<Value, Member> where Member.QueryOutput == Member {
    for column in Value.TableColumns.allColumns {
      func open(_ column: some TableColumnExpression) -> Bool {
        column.keyPath == keyPath
      }
      if open(column) {
        return TableColumn<Value, Member>(
          column.name,
          keyPath: keyPath
        )
      }
    }
    fatalError()
  }
}
