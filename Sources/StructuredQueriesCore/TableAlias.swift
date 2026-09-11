import Foundation

/// A type identifying a table alias.
///
/// Conform to this protocol to provide an alias to a table.
///
/// This protocol contains a single, optional requirement, ``aliasName``, which is the string used
/// in the `AS` clause to identify the table alias. When this requirement is omitted, it will
/// default to a lowercase, plural version of the type name, similar to how the `@Table` macro
/// generates a default table name (_e.g._ `RemindersList` becomes `"remindersLists"`).
///
/// ```swift
/// enum Referrer: AliasName {}
///
/// Referrer.aliasName  // "referrers"
/// ```
///
/// See ``Table/as(_:)`` for more information on using this conformance.
public protocol AliasName {
  /// The string used to alias a table, _e.g._ `"tableName" AS "aliasName"`.
  static var aliasName: String { get }
}

extension AliasName {
  public static var aliasName: String {
    _typeName(Self.self, qualified: false).lowerCamelCased().pluralized()
  }
}

extension Table {
  /// A table alias of this table type.
  ///
  /// This is useful for building queries where a table is joined multiple times. For example, a
  /// "users" table may have an optional `referrerID` column that points to another row in the
  /// table:
  ///
  /// ```swift
  /// @Table
  /// struct User {
  ///   let id: Int
  ///   var name = ""
  ///   var referrerID: Int?
  /// }
  /// ```
  ///
  /// …and you may want to join on this constraint.
  ///
  /// To do so, define an ``AliasName`` for referrers and then build the appropriate query using
  /// `as`:
  ///
  /// ```swift
  /// enum Referrer: AliasName {}
  ///
  /// let usersWithReferrers = User
  ///   .join(User.as(Referrer.self).all) { $0.referrerID == $1.id }
  ///   .select { ($0.name, $1.name) }
  /// // SELECT "users"."name", "referrers"."name"
  /// // FROM "users"
  /// // JOIN "users" AS "referrers"
  /// // ON "users"."referrerID" = "referrers"."id"
  /// ```
  ///
  /// Table aliases are representable in selections by providing the type to the `@Column` macro:
  ///
  /// ```swift
  /// @Selection
  /// struct UserWithReferrer {
  ///   let user: User
  ///   @Column(as: TableAlias<User, Referrer>.self)
  ///   let referrer: User
  /// }
  ///
  /// let usersWithReferrers = User
  ///   .join(User.as(Referrer.self).all) { $0.referrerID == $1.id }
  ///   .select { UserWithReferrer.Columns(user: $0, referrer: $1) }
  /// ```
  ///
  /// To alias a statement after it has been built, see ``SelectStatement/as(_:)``.
  ///
  /// - Parameter aliasName: An alias name for this table.
  /// - Returns: A table alias of this table type.
  public static func `as`<Name: AliasName>(_ aliasName: Name.Type) -> TableAlias<Self, Name>.Type {
    TableAlias.self
  }
}

/// An aliased table.
///
/// This type is returned from ``Table/as(_:)``.
public struct TableAlias<
  Base,
  Name: AliasName  // We should use a value generic here when it's possible.
>: _OptionalPromotable {
  let base: Base

  package subscript<Member: QueryRepresentable>(
    member _: KeyPath<Member, Member>,
    column keyPath: KeyPath<Base, Member.QueryOutput>
  ) -> Member.QueryOutput {
    base[keyPath: keyPath]
  }
}

extension TableAlias: Table, PartialSelectStatement, Statement where Base: Table {
  public typealias Draft = TableAlias<Base.Draft, Name>

  public static var columns: TableColumns {
    TableColumns()
  }

  public static var tableName: String {
    Base.tableName
  }

  public static var tableAlias: String? {
    Name.aliasName
  }

  public static var all: SelectOf<Self> {
    Base.all.as(Name.self)
  }

  @dynamicMemberLookup
  public struct TableColumns: Sendable, TableDefinition {
    public typealias QueryValue = TableAlias

    public static var allColumns: [any TableColumnExpression] {
      #if compiler(>=6.1)
        return Base.TableColumns.allColumns.map { $0._aliased(Name.self) }
      #else
        func open(_ column: some TableColumnExpression) -> any TableColumnExpression {
          column._aliased(Name.self)
        }
        return Base.TableColumns.allColumns.map { open($0) }
      #endif
    }

    public static var writableColumns: [any WritableTableColumnExpression] {
      #if compiler(>=6.1)
        return Base.TableColumns.writableColumns.map { $0._aliased(Name.self) }
      #else
        func open(
          _ column: some WritableTableColumnExpression
        ) -> any WritableTableColumnExpression {
          column._aliased(Name.self)
        }
        return Base.TableColumns.writableColumns.map { open($0) }
      #endif
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, TableColumn<Base, Member>>
    ) -> TableColumn<TableAlias, Member> {
      let column = Base.columns[keyPath: keyPath]
      return TableColumn<TableAlias, Member>(
        column.name,
        keyPath: \.[member: \Member.self, column: column.keyPath]
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, GeneratedColumn<Base, Member>>
    ) -> GeneratedColumn<TableAlias, Member> {
      let column = Base.columns[keyPath: keyPath]
      return GeneratedColumn<TableAlias, Member>(
        column.name,
        keyPath: \.[member: \Member.self, column: column.keyPath]
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, ColumnGroup<Base, Member>>
    ) -> ColumnGroup<TableAlias, Member> {
      let column = Base.columns[keyPath: keyPath]
      return ColumnGroup<TableAlias, Member>(
        column.name,
        keyPath: \.[member: \Member.self, column: column.keyPath]
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, OptionalColumnGroup<Base, Member>>
    ) -> OptionalColumnGroup<TableAlias, Member> {
      let column = Base.columns[keyPath: keyPath]
      return OptionalColumnGroup(
        base: ColumnGroup<TableAlias, Member?>(
          column.name,
          keyPath: \.[member: \Member?.self, column: column.keyPath]
        )
      )
    }
  }

  public struct Selection: TableExpression {
    public typealias QueryValue = TableAlias

    fileprivate var base: Base.Selection

    public init(_ base: Base.Selection) {
      self.base = base
    }

    public var allColumns: [any QueryExpression] {
      base.allColumns
    }
  }
}

extension TableAlias: _Selection where Base: _Selection {}

extension TableAlias: PrimaryKeyedTable where Base: PrimaryKeyedTable {}

extension TableAlias: TableDraft where Base: TableDraft {
  public typealias SourceTable = TableAlias<Base.SourceTable, Name>
  public init(_ primaryTable: TableAlias<Base.SourceTable, Name>) {
    self.init(base: Base(primaryTable.base))
  }
}

extension TableAlias.TableColumns: PrimaryKeyedTableDefinition
where Base.TableColumns: PrimaryKeyedTableDefinition {
  public typealias PrimaryKey = Base.PrimaryKey

  public struct PrimaryColumn: _TableColumnExpression {
    public typealias Root = TableAlias

    public typealias Value = Base.PrimaryKey

    public var _names: [String] {
      Base.columns.primaryKey._names
    }

    public var defaultValue: Base.PrimaryKey.QueryOutput? {
      Base.columns.primaryKey.defaultValue
    }

    public var keyPath: KeyPath<TableAlias, Base.PrimaryKey.QueryOutput> {
      \.[member: \Base.PrimaryKey.self, column: Base.columns.primaryKey.keyPath]
    }

    public var queryFragment: QueryFragment {
      Base.columns.primaryKey._names
        .map { "\(TableAlias.self).\(quote: $0)" }
        .joined(separator: ", ")
    }
  }

  public var primaryKey: PrimaryColumn {
    PrimaryColumn()
  }
}

extension TableAlias.TableColumns.PrimaryColumn: TableColumnExpression
where Base.TableColumns.PrimaryColumn: TableColumnExpression {
  public var name: String {
    Base.columns.primaryKey.name
  }

  public func _aliased<N: AliasName>(
    _ alias: N.Type
  ) -> any TableColumnExpression<TableAlias<TableAlias, N>, Base.PrimaryKey> {
    GeneratedColumn(name, keyPath: \.[member: \Value.self, column: keyPath])
  }
}

extension TableAlias.TableColumns.PrimaryColumn: WritableTableColumnExpression
where Base.TableColumns.PrimaryColumn: WritableTableColumnExpression {
  public func _aliased<N: AliasName>(
    _ alias: N.Type
  ) -> any WritableTableColumnExpression<TableAlias<TableAlias, N>, Base.PrimaryKey> {
    TableColumn(name, keyPath: \.[member: \Value.self, column: keyPath])
  }
}

extension TableAlias: QueryExpression where Base: QueryExpression {
  public typealias QueryValue = Self

  public var queryFragment: QueryFragment {
    base.queryFragment
  }

  public static var _columnWidth: Int {
    Base._columnWidth
  }

  public var _allColumns: [any QueryExpression] {
    base._allColumns
  }
}

extension TableAlias: QueryBindable where Base: QueryBindable {
  public var queryBinding: QueryBinding {
    base.queryBinding
  }
}

extension TableAlias: QueryDecodable where Base: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws(QueryDecodingError) {
    try self.init(base: Base(decoder: &decoder))
  }
}

extension TableAlias: QueryRepresentable where Base: QueryRepresentable {
  public typealias QueryOutput = Base.QueryOutput

  public init(queryOutput: Base.QueryOutput) {
    self.init(base: Base(queryOutput: queryOutput))
  }

  public var queryOutput: Base.QueryOutput {
    base.queryOutput
  }
}

extension TableAlias: Sendable where Base: Sendable {}

extension TableAlias: Equatable where Base: Equatable {}

extension TableAlias: Hashable where Base: Hashable {}

extension TableAlias: Decodable where Base: Decodable {
  public init(from decoder: any Decoder) throws {
    do {
      self.init(base: try decoder.singleValueContainer().decode(Base.self))
    } catch {
      self.init(base: try Base(from: decoder))
    }
  }
}

extension TableAlias: Encodable where Base: Encodable {
  public func encode(to encoder: any Encoder) throws {
    do {
      var container = encoder.singleValueContainer()
      try container.encode(self.base)
    } catch {
      try self.base.encode(to: encoder)
    }
  }
}

extension QueryFragment {
  package func aliasing<T: Table, Name: AliasName>(
    _ table: T.Type,
    as alias: Name.Type
  ) -> QueryFragment {
    var query = self
    let key = ObjectIdentifier(T.self)
    for index in query.segments.indices {
      guard
        case .identifier(var identifier) = query.segments[index],
        identifier.key == key
      else { continue }
      identifier.name = Name.aliasName
      identifier.key = ObjectIdentifier(TableAlias<T, Name>.self)
      query.segments[index] = .identifier(identifier)
    }
    return query
  }
}
