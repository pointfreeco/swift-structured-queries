public protocol _TableColumnExpression<Root, Value>: QueryExpression where Value == QueryValue {
  associatedtype Root: Table
  associatedtype Value: QueryRepresentable

  var _names: [String] { get }

  /// The table model key path associated with this table column.
  var keyPath: KeyPath<Root, Value.QueryOutput> { get }
}

/// A type representing a table column.
///
/// This protocol provides type erasure over a table's columns. You should not conform to this
/// protocol directly.
public protocol TableColumnExpression<Root, Value>: _TableColumnExpression
where Value: QueryBindable {
  /// The name of the table column.
  var name: String { get }

  /// The default value of the table column.
  var defaultValue: Value.QueryOutput? { get }

  func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Root, Name>, Value>
}

extension TableColumnExpression {
  public var _names: [String] { [name] }
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
/// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros
/// to generate values of this type.
public struct TableColumn<Root: Table, Value: QueryRepresentable & QueryBindable>:
  WritableTableColumnExpression
{
  public typealias QueryValue = Value

  public let name: String

  public let defaultValue: Value.QueryOutput?

  public let keyPath: KeyPath<Root, Value.QueryOutput>

  public init(
    _ name: String,
    keyPath: KeyPath<Root, Value.QueryOutput>,
    default defaultValue: Value.QueryOutput? = nil
  ) {
    self.name = name
    self.defaultValue = defaultValue
    self.keyPath = keyPath
  }

  public init(
    _ name: String,
    keyPath: KeyPath<Root, Value>,
    default defaultValue: Value? = nil
  ) where Value == Value.QueryOutput {
    self.name = name
    self.defaultValue = defaultValue
    self.keyPath = keyPath
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
      keyPath: \.[member: \Value.self, column: keyPath]
    )
  }

  public var _allColumns: [any TableColumnExpression] { [self] }

  public var _writableColumns: [any WritableTableColumnExpression] { [self] }
}

public enum _TableColumn<Root: Table, Value: QueryRepresentable> {
  public static func `for`(
    _ name: String,
    keyPath: KeyPath<Root, Value.QueryOutput>,
    default defaultValue: Value.QueryOutput? = nil
  ) -> TableColumn<Root, Value>
  where Value: QueryBindable {
    TableColumn(name, keyPath: keyPath, default: defaultValue)
  }

  public static func `for`(
    _ name: String,
    keyPath: KeyPath<Root, Value>,
    default defaultValue: Value? = nil
  ) -> TableColumn<Root, Value>
  where Value: QueryBindable, Value == Value.QueryOutput {
    TableColumn(name, keyPath: keyPath, default: defaultValue)
  }

  public static func `for`(
    _: String,
    keyPath: KeyPath<Root, Value>,
    default _: Value? = nil
  ) -> ColumnGroup<Root, Value>
  where Value: Table, Value == Value.QueryOutput {
    ColumnGroup(keyPath: keyPath)
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
/// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros
/// to generate values of this type.
public struct GeneratedColumn<Root: Table, Value: QueryRepresentable & QueryBindable>:
  TableColumnExpression
{
  public typealias QueryValue = Value

  public let name: String

  public let defaultValue: Value.QueryOutput?

  public let keyPath: KeyPath<Root, Value.QueryOutput>

  public init(
    _ name: String,
    keyPath: KeyPath<Root, Value.QueryOutput>,
    default defaultValue: Value.QueryOutput? = nil
  ) {
    self.name = name
    self.defaultValue = defaultValue
    self.keyPath = keyPath
  }

  public init(
    _ name: String,
    keyPath: KeyPath<Root, Value.QueryOutput>,
    default defaultValue: Value? = nil
  ) where Value == Value.QueryOutput {
    self.name = name
    self.defaultValue = defaultValue
    self.keyPath = keyPath
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
      keyPath: \.[member: \Value.self, column: keyPath]
    )
  }

  public var _allColumns: [any TableColumnExpression] { [self] }
}
