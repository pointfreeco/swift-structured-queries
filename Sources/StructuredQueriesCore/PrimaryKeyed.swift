/// A type representing a database table with a primary key.
public protocol PrimaryKeyedTable<PrimaryKey>: Table
where TableColumns: PrimaryKeyedTableDefinition<PrimaryKey> {
  /// A type representing this table's primary key.
  ///
  /// For auto-incrementing tables, this is typically `Int`.
  associatedtype PrimaryKey: QueryBindable
  where PrimaryKey.QueryValue == PrimaryKey, PrimaryKey.QueryValue.QueryOutput: Sendable

  /// A type that represents this type, but with an optional primary key.
  ///
  /// This type can be used to stage an inserted row.
  associatedtype Draft: TableDraft where Draft.PrimaryTable == Self
}

// A type representing a draft to be saved to a table with a primary key.
public protocol TableDraft: Table {
  /// A type that represents the table with a primary key.
  associatedtype PrimaryTable: PrimaryKeyedTable where PrimaryTable.Draft == Self

  /// Creates a draft from a primary keyed table.
  init(_ primaryTable: PrimaryTable)
}

/// A type representing a database table's columns.
///
/// Don't conform to this protocol directly. Instead, use the `@Table` and `@Column` macros to
/// generate a conformance.
public protocol PrimaryKeyedTableDefinition<PrimaryKey>: TableDefinition
where QueryValue: PrimaryKeyedTable {
  /// A type representing this table's primary key.
  ///
  /// For auto-incrementing tables, this is typically `Int`.
  associatedtype PrimaryKey: QueryBindable
  where PrimaryKey.QueryValue == PrimaryKey, PrimaryKey.QueryValue.QueryOutput: Sendable

  /// The column representing this table's primary key.
  var primaryKey: TableColumn<QueryValue, PrimaryKey> { get }
}

extension PrimaryKeyedTableDefinition {
  /// A query expression representing the number of rows in this table.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: An expression representing the number of rows in this table.
  public func count(
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<Int> {
    primaryKey.count(filter: filter)
  }
}

extension PrimaryKeyedTable {
  /// A where clause filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A `WHERE` clause.
  public static func find(_ primaryKey: TableColumns.PrimaryKey.QueryOutput) -> Where<Self> {
    Self.where { $0.primaryKey.eq(TableColumns.PrimaryKey(queryOutput: primaryKey)) }
  }
}

extension Where where From: PrimaryKeyedTable {
  /// Adds a primary key condition to a where clause.
  ///
  /// - Parameter primaryKey: A primary key.
  /// - Returns: A where clause with the added primary key.
  public func find(_ primaryKey: From.TableColumns.PrimaryKey.QueryOutput) -> Self {
    self.where { $0.primaryKey.eq(From.TableColumns.PrimaryKey(queryOutput: primaryKey)) }
  }
}

extension Update where From: PrimaryKeyedTable {
  /// An update statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: An update statement filtered by the given key.
  public func find(_ primaryKey: From.TableColumns.PrimaryKey.QueryOutput) -> Self {
    self.where { $0.primaryKey.eq(From.TableColumns.PrimaryKey(queryOutput: primaryKey)) }
  }
}

extension Delete where From: PrimaryKeyedTable {
  /// A delete statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A delete statement filtered by the given key.
  public func find(_ primaryKey: From.TableColumns.PrimaryKey.QueryOutput) -> Self {
    self.where { $0.primaryKey.eq(From.TableColumns.PrimaryKey(queryOutput: primaryKey)) }
  }
}

extension Select where From: PrimaryKeyedTable {
  /// A select statement filtered by a primary key.
  ///
  /// - Parameter primaryKey: A primary key identifying a table row.
  /// - Returns: A select statement filtered by the given key.
  public func find(_ primaryKey: From.TableColumns.PrimaryKey.QueryOutput) -> Self {
    self.and(From.find(primaryKey))
  }
}
