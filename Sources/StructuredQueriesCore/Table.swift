/// A type representing a database table.
///
/// Don't conform to this protocol directly. Instead, use the `@Table` and `@Column` macros to
/// generate a conformance.
@dynamicMemberLookup
public protocol Table: QueryRepresentable where TableColumns.QueryValue == Self {
  /// A type that describes this table's columns.
  associatedtype TableColumns: TableDefinition

  /// A type that describes the default results of requesting all rows from the table.
  associatedtype DefaultScope: SelectStatement<(), Self, ()>

  /// A value that describes this table's columns.
  static var columns: TableColumns { get }

  /// The table's name.
  static var tableName: String { get }

  /// A table alias.
  ///
  /// This property should always return `nil` unless called on a ``TableAlias``.
  static var tableAlias: String? { get }

  /// The table schema's name.
  static var schemaName: String? { get }

  /// A select statement for this table.
  ///
  /// The default implementation of this property returns a fully unscoped query for the table
  /// (_i.e._ ``unscoped``). To override the default scope of all queries, provide your own
  /// implementation of `all`. For example, if you only perform "soft" deletion of table rows, you
  /// can provide a custom implementation that filters out these deleted rows by default:
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   static let all = Self.where { !$0.isDeleted }
  ///
  ///   let id: Int
  ///   var name = ""
  ///   var isDeleted = false
  /// }
  ///
  /// Item.where { name.contains("red") }
  /// // SELECT … FROM "items"
  /// // WHERE (NOT "items"."isDeleted")    -- Automatically applied from 'all'
  /// // AND ("items"."name" LIKE '%red%')
  /// ```
  static var all: DefaultScope { get }
}

extension Table where DefaultScope == Where<Self> {
  public static var all: DefaultScope {
    Where()
  }
}

extension Table {
  /// A select statement on the table with no constraints.
  ///
  /// A ``Table``'s ``Table/all`` method can be overridden so that it provides a default set of
  /// constraints to fetch data from the table. For example, a reminder with an `isDeleted` field
  /// may want to define its `all` as adding the `WHERE` clause to select reminders that are not
  /// deleted:
  ///
  /// ```swift
  /// @Table
  /// struct Reminder {
  ///   static let all = Self.where { !$0.isDeleted }
  ///
  ///   let id: Int
  ///   var title = ""
  ///   var isDeleted = false
  /// }
  ///
  /// Reminder.select(\.id)
  /// // SELECT "reminders"."id" FROM "reminders"
  /// // WHERE (NOT "reminders"."isDeleted")
  /// ```
  ///
  /// If you want to remove this default scope in order to select absolutely all reminders, you can
  /// use the ``Table/unscoped`` property:
  ///
  /// ```swift
  /// Reminder.unscoped.select(\.id)
  /// // SELECT "reminders"."id" FROM "reminders"
  /// ```
  public static var unscoped: Where<Self> {
    Where(unscoped: true)
  }

  public static var tableAlias: String? {
    nil
  }

  public static var schemaName: String? {
    nil
  }

  /// Returns a table column to the resulting value of a given key path.
  ///
  /// Allows, _e.g._ `Reminder.columns.id` to be abbreviated `Reminder.id`, which is useful when
  /// constructing statements using the `#sql` macro:
  ///
  /// ```swift
  /// #sql("SELECT \(Reminder.id) FROM \(Reminder.self)", as: Int.self)
  /// // SELECT "reminders"."id" FROM "reminders
  /// ```
  public static subscript<Member>(
    dynamicMember keyPath: KeyPath<TableColumns, TableColumn<Self, Member>>
  ) -> TableColumn<Self, Member> {
    columns[keyPath: keyPath]
  }
}
