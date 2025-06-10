public protocol _OptionalProtocol<Wrapped> {
  associatedtype Wrapped
  var _wrapped: Wrapped? { get }
  static var _none: Self { get }
  static func _some(_ wrapped: Wrapped) -> Self
}

extension Optional: _OptionalProtocol {
  public var _wrapped: Wrapped? { self }
  public static var _none: Self { .none }
  public static func _some(_ wrapped: Wrapped) -> Self { .some(wrapped) }
}

public protocol _OptionalPromotable<_Optionalized> {
  associatedtype _Optionalized: _OptionalProtocol = Self?
}

extension Optional: _OptionalPromotable {
  public typealias _Optionalized = Self
}

extension [UInt8]: _OptionalPromotable where Element: _OptionalPromotable {}

extension Optional: QueryBindable where Wrapped: QueryBindable {
  public typealias QueryValue = Wrapped.QueryValue?

  public var queryBinding: QueryBinding {
    self?.queryBinding ?? .null
  }
}

extension Optional: QueryDecodable where Wrapped: QueryDecodable {
  @inlinable
  public init(decoder: inout some QueryDecoder) throws {
    do {
      self = try Wrapped(decoder: &decoder)
    } catch QueryDecodingError.missingRequiredColumn {
      self = nil
    }
  }
}

extension Optional: QueryExpression where Wrapped: QueryExpression {
  public typealias QueryValue = Wrapped.QueryValue?

  public var queryFragment: QueryFragment {
    self?.queryFragment ?? "NULL"
  }
}

extension Optional: QueryRepresentable where Wrapped: QueryRepresentable {
  public typealias QueryOutput = Wrapped.QueryOutput?

  @inlinable
  public init(queryOutput: Wrapped.QueryOutput?) {
    if let queryOutput {
      self = Wrapped(queryOutput: queryOutput)
    } else {
      self = nil
    }
  }

  @inlinable
  public var queryOutput: Wrapped.QueryOutput? {
    self?.queryOutput
  }
}

extension Optional: Table where Wrapped: Table {
  public static var tableName: String {
    Wrapped.tableName
  }

  public static var tableAlias: String? {
    Wrapped.tableAlias
  }

  public static var columns: TableColumns {
    TableColumns()
  }

  fileprivate subscript<Member: QueryRepresentable>(
    member _: KeyPath<Member, Member> & Sendable,
    column keyPath: KeyPath<Wrapped, Member.QueryOutput> & Sendable
  ) -> Member.QueryOutput? {
    self?[keyPath: keyPath]
  }

  @dynamicMemberLookup
  public struct TableColumns: TableDefinition {
    public typealias QueryValue = Optional

    public static var allColumns: [any TableColumnExpression] {
      Wrapped.TableColumns.allColumns
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Wrapped.TableColumns, TableColumn<Wrapped, Member>>
    ) -> TableColumn<Optional, Member?> {
      let column = Wrapped.columns[keyPath: keyPath]
      return TableColumn<Optional, Member?>(
        column.name,
        keyPath: \.[member: \Member.self, column: column._keyPath]
      )
    }

    public subscript<Member: QueryExpression>(
      dynamicMember keyPath: KeyPath<Wrapped.TableColumns, Member>
    ) -> some QueryExpression<Member.QueryValue?> {
      Member?.some(Wrapped.columns[keyPath: keyPath])
    }

    public subscript<QueryValue>(
      dynamicMember keyPath: KeyPath<Wrapped.TableColumns, some QueryExpression<QueryValue?>>
    ) -> some QueryExpression<QueryValue?> {
      Wrapped.columns[keyPath: keyPath]
    }
  }
}

extension Optional: PrimaryKeyedTable where Wrapped: PrimaryKeyedTable {
  public typealias Draft = Wrapped.Draft?
}

extension Optional: TableDraft where Wrapped: TableDraft {
  public typealias PrimaryTable = Wrapped.PrimaryTable?
  public init(_ primaryTable: Wrapped.PrimaryTable?) {
    self = primaryTable.map(Wrapped.init)
  }
}

extension Optional.TableColumns: PrimaryKeyedTableDefinition
where Wrapped.TableColumns: PrimaryKeyedTableDefinition {
  public typealias PrimaryKey = Wrapped.TableColumns.PrimaryKey?

  public var primaryKey: TableColumn<Optional, Wrapped.TableColumns.PrimaryKey.QueryValue?> {
    self[dynamicMember: \.primaryKey]
  }
}
