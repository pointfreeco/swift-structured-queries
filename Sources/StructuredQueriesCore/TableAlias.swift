import Foundation
import StructuredQueriesSupport

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
  Base: Table,
  Name: AliasName  // We should use a value generic here when it's possible.
>: _OptionalPromotable, Table {
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
    var select = unsafeBitCast(Base.all.asSelect(), to: SelectOf<Self>.self)
    select.clauses.columns = select.clauses.columns.map {
      SQLQueryExpression($0.queryFragment.replacingOccurrences(of: Base.self, with: Name.self))
    }
    select.clauses.where = select.clauses.where
      .map { $0.replacingOccurrences(of: Base.self, with: Name.self) }
    select.clauses.group = select.clauses.group
      .map { $0.replacingOccurrences(of: Base.self, with: Name.self) }
    select.clauses.having = select.clauses.having
      .map { $0.replacingOccurrences(of: Base.self, with: Name.self) }
    select.clauses.order = select.clauses.order
      .map { $0.replacingOccurrences(of: Base.self, with: Name.self) }
    return select
  }

  let base: Base

  subscript<Member: QueryRepresentable>(
    member _: KeyPath<Member, Member> & Sendable,
    column keyPath: KeyPath<Base, Member.QueryOutput> & Sendable
  ) -> Member.QueryOutput {
    base[keyPath: keyPath]
  }

  @dynamicMemberLookup
  public struct TableColumns: TableDefinition {
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

    public typealias QueryValue = TableAlias

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, TableColumn<Base, Member>>
    ) -> TableColumn<TableAlias, Member> {
      let column = Base.columns[keyPath: keyPath]
      return TableColumn<TableAlias, Member>(
        column.name,
        keyPath: \.[member: \Member.self, column: column._keyPath]
      )
    }
  }
}

extension TableAlias: PrimaryKeyedTable where Base: PrimaryKeyedTable {
  public typealias Draft = TableAlias<Base.Draft, Name>
}

extension TableAlias: TableDraft where Base: TableDraft {
  public typealias PrimaryTable = TableAlias<Base.PrimaryTable, Name>
  public init(_ primaryTable: TableAlias<Base.PrimaryTable, Name>) {
    self.init(base: Base(primaryTable.base))
  }
}

extension TableAlias.TableColumns: PrimaryKeyedTableDefinition
where Base.TableColumns: PrimaryKeyedTableDefinition {
  public typealias PrimaryKey = Base.TableColumns.PrimaryKey

  public var primaryKey: TableColumn<TableAlias, Base.TableColumns.PrimaryKey.QueryValue> {
    self[dynamicMember: \.primaryKey]
  }
}

extension TableAlias: QueryExpression where Base: QueryExpression {
  public typealias QueryValue = Base.QueryValue

  public var queryFragment: QueryFragment {
    base.queryFragment
  }
}

extension TableAlias: QueryBindable where Base: QueryBindable {
  public var queryBinding: QueryBinding {
    base.queryBinding
  }
}

extension TableAlias: QueryDecodable where Base: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(base: Base(decoder: &decoder))
  }
}

extension TableAlias: QueryRepresentable where Base: QueryRepresentable {
  public typealias QueryOutput = Base

  public init(queryOutput: Base) {
    self.init(base: queryOutput)
  }

  public var queryOutput: Base {
    base
  }
}

extension TableAlias: Sendable where Base: Sendable {}

extension TableAlias: Equatable where Base: Equatable {}

extension TableAlias: Hashable where Base: Hashable {}

extension TableAlias: Decodable where Base: Decodable {
  public init(from decoder: Decoder) throws {
    do {
      self.init(base: try decoder.singleValueContainer().decode(Base.self))
    } catch {
      self.init(base: try Base(from: decoder))
    }
  }
}

extension TableAlias: Encodable where Base: Encodable {
  public func encode(to encoder: Encoder) throws {
    do {
      var container = encoder.singleValueContainer()
      try container.encode(self.base)
    } catch {
      try self.base.encode(to: encoder)
    }
  }
}

extension QueryFragment {
  fileprivate func replacingOccurrences<T: Table, A: AliasName>(
    of _: T.Type, with _: A.Type
  ) -> QueryFragment {
    var query = self
    for index in query.segments.indices {
      switch query.segments[index] {
      case .sql(let sql):
        query.segments[index] = .sql(
          sql.replacingOccurrences(of: T.tableName.quoted(), with: A.aliasName.quoted())
        )
      case .binding:
        continue
      }
    }
    return query
  }
}
