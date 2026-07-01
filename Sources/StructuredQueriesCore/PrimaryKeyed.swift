/// A type representing a database table with a primary key.
public protocol PrimaryKeyedTable<PrimaryKey>: Table
where
  TableColumns: PrimaryKeyedTableDefinition<PrimaryKey>,
  Draft: TableDraft,
  Draft.SourceTable == Self
{
  /// A type representing this table's primary key.
  ///
  /// For auto-incrementing tables, this is typically `Int`.
  associatedtype PrimaryKey: QueryRepresentable & QueryExpression
  where PrimaryKey.QueryValue == PrimaryKey
}

// A type representing a draft to be saved to a table.
public protocol TableDraft: Table {
  /// A type that represents the table this draft stages a row for.
  associatedtype SourceTable: Table where SourceTable.Draft == Self

  /// Creates a draft from a persisted table row.
  init(_ source: SourceTable)
}

extension TableDraft where SourceTable: PrimaryKeyedTable {
  public typealias PrimaryKey = SourceTable.PrimaryKey
}

extension TableDraft {
  public static subscript(
    dynamicMember keyPath: KeyPath<SourceTable.Type, some Statement<SourceTable>>
  ) -> some Statement<Self> {
    SQLQueryExpression("\(SourceTable.self[keyPath: keyPath])")
  }

  public static subscript(
    dynamicMember keyPath: KeyPath<SourceTable.Type, some SelectStatementOf<SourceTable>>
  ) -> SelectOf<Self> {
    unsafeBitCast(SourceTable.self[keyPath: keyPath].asSelect(), to: SelectOf<Self>.self)
  }

  public static var all: SelectOf<Self> {
    unsafeBitCast(SourceTable.all.asSelect(), to: SelectOf<Self>.self)
  }

  public static var schemaName: String? { SourceTable.schemaName }

  public static var tableName: String { SourceTable.tableName }
}

/// A type representing a database table's columns.
///
/// Don't conform to this protocol directly. Instead, use the `@Table` and `@Column` macros to
/// generate a conformance. See <doc:PrimaryKeyedTables> for more information.
public protocol PrimaryKeyedTableDefinition<PrimaryKey>: TableDefinition
where QueryValue: PrimaryKeyedTable {
  /// A type representing this table's primary key.
  ///
  /// For auto-incrementing tables, this is typically `Int`.
  associatedtype PrimaryKey: QueryRepresentable & QueryExpression
  where PrimaryKey.QueryValue == PrimaryKey

  associatedtype PrimaryColumn: _TableColumnExpression<QueryValue, PrimaryKey>

  /// The column representing this table's primary key.
  var primaryKey: PrimaryColumn { get }
}

extension TableDefinition where QueryValue: TableDraft {
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<QueryValue.SourceTable.TableColumns, Member>
  ) -> Member {
    QueryValue.SourceTable.columns[keyPath: keyPath]
  }
}

extension PrimaryKeyedTableDefinition where PrimaryColumn: TableColumnExpression {
  /// A query expression representing the number of rows in this table.
  ///
  /// - Parameters:
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: An expression representing the number of rows in this table.
  public func count(
    distinct isDistinct: Bool = false,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<Int> {
    primaryKey.count(distinct: isDistinct, filter: filter)
  }
}

extension PrimaryKeyedTable {
  /// A where clause filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A `WHERE` clause.
  public static func find(
    _ primaryKey: some QueryExpression<PrimaryKey>
  ) -> Where<Self> {
    find([primaryKey])
  }

  /// A where clause filtered by primary keys.
  ///
  /// - Parameter primaryKey: Primary keys identifying table rows.
  /// - Returns: A `WHERE` clause.
  public static func find(
    _ primaryKeys: some Sequence<some QueryExpression<PrimaryKey>>
  ) -> Where<Self> {
    Self.where { $0.primaryKey.in(primaryKeys) }
  }

  public var primaryKey: PrimaryKey.QueryOutput {
    self[keyPath: Self.columns.primaryKey.keyPath]
  }
}

extension TableDraft where SourceTable: PrimaryKeyedTable {
  /// A where clause filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A `WHERE` clause.
  public static func find(
    _ primaryKey: some QueryExpression<SourceTable.PrimaryKey>
  ) -> Where<Self> {
    find([primaryKey])
  }

  /// A where clause filtered by primary keys.
  ///
  /// - Parameter primaryKeys: Primary keys identifying table rows.
  /// - Returns: A `WHERE` clause.
  public static func find(
    _ primaryKeys: some Sequence<some QueryExpression<SourceTable.PrimaryKey>>
  ) -> Where<Self> {
    Self.where { $0.primaryKey.in(primaryKeys) }
  }
}

extension Where where From: PrimaryKeyedTable {
  /// Adds a primary key condition to a where clause.
  ///
  /// - Parameter primaryKey: A primary key.
  /// - Returns: A where clause with the added primary key.
  public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>) -> Self {
    find([primaryKey])
  }

  /// Adds a primary key condition to a where clause.
  ///
  /// - Parameter primaryKeys: A sequence of primary keys.
  /// - Returns: A where clause with the added primary keys condition.
  public func find(
    _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
  ) -> Self {
    self.where { $0.primaryKey.in(primaryKeys) }
  }
}

extension Where where From: TableDraft, From.SourceTable: PrimaryKeyedTable {
  /// Adds a primary key condition to a where clause.
  ///
  /// - Parameter primaryKey: A primary key.
  /// - Returns: A where clause with the added primary key.
  public func find(_ primaryKey: some QueryExpression<From.SourceTable.PrimaryKey>)
    -> Self
  {
    find([primaryKey])
  }

  /// Adds a primary key condition to a where clause.
  ///
  /// - Parameter primaryKeys: A sequence of primary keys.
  /// - Returns: A where clause with the added primary keys condition.
  public func find(
    _ primaryKeys: some Sequence<some QueryExpression<From.SourceTable.PrimaryKey>>
  ) -> Self {
    self.where { $0.primaryKey.in(primaryKeys) }
  }
}

extension Select where From: PrimaryKeyedTable {
  /// A select statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A select statement filtered by the given key.
  public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>) -> Self {
    and(From.find(primaryKey))
  }

  /// A select statement filtered by a sequence of primary keys.
  ///
  /// - Parameter primaryKeys: A sequence of primary keys.
  /// - Returns: A select statement filtered by the given keys.
  public func find(
    _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
  ) -> Self {
    and(From.find(primaryKeys))
  }
}

extension Select where From: TableDraft, From.SourceTable: PrimaryKeyedTable {
  /// A select statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A select statement filtered by the given key.
  public func find(
    _ primaryKey: some QueryExpression<From.SourceTable.PrimaryKey>
  ) -> Self {
    and(From.find(primaryKey))
  }

  /// A select statement filtered by a sequence of primary keys.
  ///
  /// - Parameter primaryKeys: A sequence of primary keys.
  /// - Returns: A select statement filtered by the given keys.
  public func find(
    _ primaryKeys: some Sequence<some QueryExpression<From.SourceTable.PrimaryKey>>
  ) -> Self {
    and(From.find(primaryKeys))
  }
}

extension Update where From: PrimaryKeyedTable {
  /// An update statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: An update statement filtered by the given key.
  public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>) -> Self {
    find([primaryKey])
  }

  /// An update statement filtered by a sequence of primary keys.
  ///
  /// - Parameter primaryKeys: A sequence of primary keys.
  /// - Returns: An update statement filtered by the given keys.
  public func find(
    _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
  ) -> Self {
    self.where { $0.primaryKey.in(primaryKeys) }
  }
}

extension Update where From: TableDraft, From.SourceTable: PrimaryKeyedTable {
  /// An update statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: An update statement filtered by the given key.
  public func find(_ primaryKey: some QueryExpression<From.SourceTable.PrimaryKey>)
    -> Self
  {
    find([primaryKey])
  }

  /// An update statement filtered by a sequence of primary keys.
  ///
  /// - Parameter primaryKeys: A sequence of primary keys.
  /// - Returns: An update statement filtered by the given keys.
  public func find(
    _ primaryKeys: some Sequence<some QueryExpression<From.SourceTable.PrimaryKey>>
  ) -> Self {
    self.where { $0.primaryKey.in(primaryKeys) }
  }
}

extension Delete where From: PrimaryKeyedTable {
  /// A delete statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A delete statement filtered by the given key.
  public func find(_ primaryKey: some QueryExpression<From.PrimaryKey>) -> Self {
    find([primaryKey])
  }

  /// A delete statement filtered by a sequence of primary keys.
  ///
  /// - Parameter primaryKeys: A sequence of primary keys.
  /// - Returns: A delete statement filtered by the given keys.
  public func find(
    _ primaryKeys: some Sequence<some QueryExpression<From.PrimaryKey>>
  ) -> Self {
    self.where { $0.primaryKey.in(primaryKeys) }
  }
}

extension Delete where From: TableDraft, From.SourceTable: PrimaryKeyedTable {
  /// A delete statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A delete statement filtered by the given key.
  public func find(_ primaryKey: some QueryExpression<From.SourceTable.PrimaryKey>)
    -> Self
  {
    find([primaryKey])
  }

  /// A delete statement filtered by a sequence of primary keys.
  ///
  /// - Parameter primaryKeys: A sequence of primary keys.
  /// - Returns: A delete statement filtered by the given keys.
  public func find(
    _ primaryKeys: some Sequence<some QueryExpression<From.SourceTable.PrimaryKey>>
  ) -> Self {
    self.where { $0.primaryKey.in(primaryKeys) }
  }
}
