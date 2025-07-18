/// A type representing a table column.
///
/// This protocol has a single conformance, ``TableColumn``, and simply provides type erasure over
/// a table's columns. You should not conform to this protocol directly.
public protocol TableColumnExpression<Root, Value>: QueryExpression where Value == QueryValue {
  associatedtype Root: Table
  associatedtype Value: QueryRepresentable & QueryBindable

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

/// A type representing a _writable_ table column, _i.e._ not a generated column.
public protocol WritableTableColumnExpression<Root, Value>: TableColumnExpression {
  func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any WritableTableColumnExpression<TableAlias<Root, Name>, Value>
}

extension WritableTableColumnExpression {
  public func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Root, Name>, Value> {
    _aliased(alias)
  }
}

/// A type representing a table column.
///
/// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros to
/// generate values of this type.
public struct TableColumn<Root: Table, Value: QueryRepresentable & QueryBindable>:
  WritableTableColumnExpression,
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
  ) -> any WritableTableColumnExpression<TableAlias<Root, Name>, Value> {
    TableColumn<TableAlias<Root, Name>, Value>(
      name,
      keyPath: \.[member: \Value.self, column: _keyPath]
    )
  }
}

/// A type that describes how a table column is generated (_e.g._, SQLite generated columns).
///
/// You provide a value of this type to a `@Column` macro to differentiate between generated columns
/// that are physically stored in the database table and those that are "virtual".
///
/// ```swift
/// @Column(generated: .stored)
/// ```
public enum GeneratedColumnStorage {
  case virtual, stored
}

/// A type representing a generated column.
///
/// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros to
/// generate values of this type.
public struct GeneratedColumn<Root: Table, Value: QueryRepresentable & QueryBindable>:
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
