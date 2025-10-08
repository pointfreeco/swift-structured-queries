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
    self._allColumns.map(\.queryFragment).joined(separator: ", ")
  }

  public static var _columnWidth: Int {
    Wrapped._columnWidth
  }

  public var _allColumns: [any QueryExpression] {
    self?._allColumns
      ?? Array(
        repeating: SQLQueryExpression("NULL") as any QueryExpression,
        count: Self._columnWidth
      )
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

extension Optional: Table, PartialSelectStatement, Statement where Wrapped: Table {
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
    member _: KeyPath<Member, Member>,
    column keyPath: KeyPath<Wrapped, Member.QueryOutput>
  ) -> Member.QueryOutput? {
    self?[keyPath: keyPath]
  }

  @dynamicMemberLookup
  public struct TableColumns: TableDefinition {
    public typealias QueryValue = Optional

    public static var allColumns: [any TableColumnExpression] {
      func open<Root, Value>(
        _ column: some TableColumnExpression<Root, Value>
      ) -> any TableColumnExpression {
        guard let column = column as? TableColumn<Wrapped, Value>
        else {
          let column = column as! GeneratedColumn<Wrapped, Value>
          return GeneratedColumn<Optional, Value?>(
            column.name,
            keyPath: \.[member: \Value.self, column: column.keyPath],
            default: column.defaultValue
          )
        }
        return TableColumn<Optional, Value?>(
          column.name,
          keyPath: \.[member: \Value.self, column: column.keyPath],
          default: column.defaultValue
        )
      }
      return Wrapped.TableColumns.allColumns.map { open($0) }
    }

    public static var writableColumns: [any WritableTableColumnExpression] {
      func open<Root, Value>(
        _ column: some WritableTableColumnExpression<Root, Value>
      ) -> any WritableTableColumnExpression {
        let column = column as! TableColumn<Wrapped, Value>
        return TableColumn<Optional, Value?>(
          column.name,
          keyPath: \.[member: \Value.self, column: column.keyPath],
          default: column.defaultValue
        )
      }
      return Wrapped.TableColumns.writableColumns.map { open($0) }
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Wrapped.TableColumns, TableColumn<Wrapped, Member>>
    ) -> TableColumn<Optional, Member?> {
      let column = Wrapped.columns[keyPath: keyPath]
      return TableColumn<Optional, Member?>(
        column.name,
        keyPath: \.[member: \Member.self, column: column.keyPath]
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Wrapped.TableColumns, GeneratedColumn<Wrapped, Member>>
    ) -> GeneratedColumn<Optional, Member?> {
      let column = Wrapped.columns[keyPath: keyPath]
      return GeneratedColumn<Optional, Member?>(
        column.name,
        keyPath: \.[member: \Member.self, column: column.keyPath]
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Wrapped.TableColumns, ColumnGroup<Wrapped, Member>>
    ) -> ColumnGroup<Optional, Member?> {
      ColumnGroup<Optional, Member?>(
        keyPath: \.[member: \Member.self, column: Wrapped.columns[keyPath: keyPath].keyPath]
      )
    }

    public subscript<Member: QueryExpression>(
      dynamicMember keyPath: KeyPath<Wrapped.TableColumns, Member>
    ) -> some QueryExpression<Member.QueryValue?> {
      Member?.some(Wrapped.columns[keyPath: keyPath])
    }

    @_disfavoredOverload
    public subscript<QueryValue>(
      dynamicMember keyPath: KeyPath<Wrapped.TableColumns, some QueryExpression<QueryValue?>>
    ) -> some QueryExpression<QueryValue?> {
      Wrapped.columns[keyPath: keyPath]
    }
  }

  public typealias Selection = Wrapped.Selection?
}

extension Optional: _Selection where Wrapped: _Selection {}

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
  public typealias PrimaryKey = Wrapped.PrimaryKey?

  public struct PrimaryColumn: _TableColumnExpression {
    public typealias Root = Optional

    public typealias Value = Wrapped.PrimaryKey?

    public var _names: [String] {
      Wrapped.columns.primaryKey._names
    }

    public var keyPath: KeyPath<Wrapped?, Wrapped.PrimaryKey.QueryOutput?> {
      \.[member: \Wrapped.PrimaryKey.self, column: Wrapped.columns.primaryKey.keyPath]
    }

    public var queryFragment: QueryFragment {
      Wrapped.columns.primaryKey.queryFragment
    }
  }

  public var primaryKey: PrimaryColumn {
    PrimaryColumn()
  }
}

extension Optional.TableColumns.PrimaryColumn: TableColumnExpression
where Wrapped.TableColumns.PrimaryColumn: TableColumnExpression {
  public var name: String {
    Wrapped.columns.primaryKey.name
  }

  public var defaultValue: Wrapped.PrimaryKey.QueryOutput?? {
    Wrapped.columns.primaryKey.defaultValue
  }

  public func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any TableColumnExpression<TableAlias<Optional, Name>, Wrapped.PrimaryKey?> {
    GeneratedColumn(name, keyPath: \.[member: \Value.self, column: keyPath])
  }
}

extension Optional.TableColumns.PrimaryColumn: WritableTableColumnExpression
where Wrapped.TableColumns.PrimaryColumn: WritableTableColumnExpression {
  public func _aliased<Name: AliasName>(
    _ alias: Name.Type
  ) -> any WritableTableColumnExpression<TableAlias<Optional, Name>, Wrapped.PrimaryKey?> {
    TableColumn(name, keyPath: \.[member: \Value.self, column: keyPath])
  }
}

extension Optional: TableExpression where Wrapped: TableExpression {
  public var allColumns: [any QueryExpression] {
    self?.allColumns
      ?? Wrapped.QueryValue.TableColumns.allColumns.map {
        SQLQueryExpression("NULL AS \(quote: $0.name)")
      }
  }
}

extension QueryExpression where QueryValue: _OptionalProtocol {
  /// Creates and optionalizes a new expression from this one by applying an unwrapped version of
  /// this expression to a given closure.
  ///
  /// ```swift
  /// Reminder.where {
  ///   $0.dueDate.map { $0 > Date() }
  /// }
  /// // SELECT … FROM "reminders"
  /// // WHERE "reminders"."dueDate" > '2018-01-29 00:08:00.000'
  /// ```
  ///
  /// - Parameter transform: A closure that takes an unwrapped version of this expression.
  /// - Returns: The result of the transform function, optionalized.
  public func map<T>(
    _ transform: (SQLQueryExpression<QueryValue.Wrapped>) -> some QueryExpression<T>
  ) -> some QueryExpression<T?> {
    SQLQueryExpression(transform(SQLQueryExpression(queryFragment)).queryFragment)
  }

  /// Creates a new optional expression from this one by applying an unwrapped version of this
  /// expression to a given closure.
  ///
  /// ```swift
  /// Reminder.select {
  ///   $0.dueDate.flatMap { $0.max() }
  /// }
  /// // SELECT max("reminders"."dueDate") FROM "reminders"
  /// // => [Date?]
  /// ```
  ///
  /// - Parameter transform: A closure that takes an unwrapped version of this expression.
  /// - Returns: The result of the transform function.
  public func flatMap<T>(
    _ transform: (SQLQueryExpression<QueryValue.Wrapped>) -> some QueryExpression<T?>
  ) -> some QueryExpression<T?> {
    SQLQueryExpression(transform(SQLQueryExpression(queryFragment)).queryFragment)
  }
}
