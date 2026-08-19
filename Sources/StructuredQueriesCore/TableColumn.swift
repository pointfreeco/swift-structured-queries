public protocol _TableColumnExpression<Root, Value>: QueryExpression where Value == QueryValue {
  associatedtype Root: Table
  associatedtype Value: QueryRepresentable

  var _names: [String] { get }

  /// The default value of the table column.
  var defaultValue: Value.QueryOutput? { get }

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

  func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Root, Name>, Value>
}

extension TableColumnExpression {
  public var _names: [String] { [name] }

  package var returningFragment: QueryFragment {
    Value.queryFragment(decoding: "\(quote: name)")
  }
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

  @usableFromInline
  let _defaultValue: () -> Value.QueryOutput?

  @usableFromInline
  let _keyPath: () -> KeyPath<Root, Value.QueryOutput>

  public var defaultValue: Value.QueryOutput? { _defaultValue() }

  public var keyPath: KeyPath<Root, Value.QueryOutput> { _keyPath() }

  @inlinable
  public init(
    _ name: String,
    keyPath: @autoclosure @escaping () -> KeyPath<Root, Value.QueryOutput>,
    default defaultValue: @autoclosure @escaping () -> Value.QueryOutput? = nil
  ) {
    self.name = name
    self._defaultValue = defaultValue
    self._keyPath = keyPath
  }

  @inlinable
  public init(
    _ name: String,
    keyPath: @autoclosure @escaping () -> KeyPath<Root, Value>,
    default defaultValue: @autoclosure @escaping () -> Value? = nil
  ) where Value == Value.QueryOutput {
    self.name = name
    self._defaultValue = defaultValue
    self._keyPath = keyPath
  }

  public var queryFragment: QueryFragment {
    let column: QueryFragment = "\(Root.self).\(quote: name)"
    return _isSelecting ? Value.queryFragment(decoding: column) : column
  }

  public func _aliased<Name>(
    _ alias: Name.Type
  ) -> any WritableTableColumnExpression<TableAlias<Root, Name>, Value> {
    TableColumn<TableAlias<Root, Name>, Value>(
      name,
      keyPath: \.[member: \Value.self, column: keyPath]
    )
  }

  public var _allColumns: TableColumnList<any TableColumnExpression> { [self] }

  public var _writableColumns: TableColumnList<any WritableTableColumnExpression> { [self] }
}

public enum _TableColumn<Root: Table, Value: QueryRepresentable> {
  @inlinable
  public static func `for`(
    _ name: String,
    keyPath: @autoclosure @escaping () -> KeyPath<Root, Value.QueryOutput>,
    default defaultValue: @autoclosure @escaping () -> Value.QueryOutput? = nil
  ) -> TableColumn<Root, Value>
  where Value: QueryBindable {
    TableColumn(name, keyPath: keyPath(), default: defaultValue())
  }

  @inlinable
  public static func `for`(
    _ name: String,
    keyPath: @autoclosure @escaping () -> KeyPath<Root, Value>,
    default defaultValue: @autoclosure @escaping () -> Value? = nil
  ) -> TableColumn<Root, Value>
  where Value: QueryBindable, Value == Value.QueryOutput {
    TableColumn(name, keyPath: keyPath(), default: defaultValue())
  }

  @_disfavoredOverload
  public static func `for`(
    _ name: String,
    keyPath: @autoclosure @escaping () -> KeyPath<Root, Value.QueryOutput>,
    default defaultValue: @autoclosure @escaping () -> Value.QueryOutput? = nil
  ) -> ColumnGroup<Root, Value>
  where Value: Table, Value.QueryOutput: Table {
    ColumnGroup(name, keyPath: keyPath(), default: defaultValue())
  }

  @_disfavoredOverload
  public static func `for`(
    _ name: String,
    keyPath: KeyPath<Root, Value>,
    default defaultValue: Value? = nil
  ) -> ColumnGroup<Root, Value>
  where Value: Table, Value == Value.QueryOutput {
    ColumnGroup(name, keyPath: keyPath, default: defaultValue)
  }

  public static func `for`<Wrapped>(
    _ name: String,
    keyPath: @autoclosure @escaping () -> KeyPath<Root, Value.QueryOutput>,
    default defaultValue: @autoclosure @escaping () -> Value.QueryOutput? = nil
  ) -> OptionalColumnGroup<Root, Wrapped>
  where Value == Wrapped?, Wrapped: Table, Wrapped.QueryOutput: Table {
    OptionalColumnGroup(base: ColumnGroup(name, keyPath: keyPath(), default: defaultValue()))
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

  @usableFromInline
  let _defaultValue: () -> Value.QueryOutput?

  @usableFromInline
  let _keyPath: () -> KeyPath<Root, Value.QueryOutput>

  public var defaultValue: Value.QueryOutput? { _defaultValue() }

  public var keyPath: KeyPath<Root, Value.QueryOutput> { _keyPath() }

  @inlinable
  public init(
    _ name: String,
    keyPath: @autoclosure @escaping () -> KeyPath<Root, Value.QueryOutput>,
    default defaultValue: @autoclosure @escaping () -> Value.QueryOutput? = nil
  ) {
    self.name = name
    self._defaultValue = defaultValue
    self._keyPath = keyPath
  }

  @inlinable
  public init(
    _ name: String,
    keyPath: @autoclosure @escaping () -> KeyPath<Root, Value.QueryOutput>,
    default defaultValue: @autoclosure @escaping () -> Value? = nil
  ) where Value == Value.QueryOutput {
    self.name = name
    self._defaultValue = defaultValue
    self._keyPath = keyPath
  }

  public var queryFragment: QueryFragment {
    let column: QueryFragment = "\(Root.self).\(quote: name)"
    return _isSelecting ? Value.queryFragment(decoding: column) : column
  }

  public func _aliased<Name>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Root, Name>, Value> {
    TableColumn<TableAlias<Root, Name>, Value>(
      name,
      keyPath: \.[member: \Value.self, column: keyPath]
    )
  }

  public var _allColumns: TableColumnList<any TableColumnExpression> { [self] }
}
