/// A group of table columns.
///
/// Don't create instances of this value directly. Instead, use the `@Table` and `@Columns` macros
/// to generate values of this type.
@dynamicMemberLookup
public struct ColumnGroup<Root: Table, Values: Table>: _TableColumnExpression
where Values.QueryOutput == Values {
  public typealias Value = Values

  public var _names: [String] { Values.TableColumns.allColumns.map(\.name) }

  public typealias QueryValue = Values

  public let keyPath: KeyPath<Root, Values>

  public init(keyPath: KeyPath<Root, Values>) {
    self.keyPath = keyPath
  }

  public var queryFragment: QueryFragment {
    _allColumns.map(\.queryFragment).joined(separator: ", ")
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, TableColumn<Values, Member>>
  ) -> TableColumn<Root, Member> {
    let column = Values.columns[keyPath: keyPath]
    return TableColumn<Root, Member>(
      column.name,
      keyPath: self.keyPath.appending(path: column.keyPath),
      default: column.defaultValue
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, GeneratedColumn<Values, Member>>
  ) -> GeneratedColumn<Root, Member> {
    let column = Values.columns[keyPath: keyPath]
    return GeneratedColumn<Root, Member>(
      column.name,
      keyPath: self.keyPath.appending(path: column.keyPath),
      default: column.defaultValue
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, ColumnGroup<Values, Member>>
  ) -> ColumnGroup<Root, Member> {
    let column = Values.columns[keyPath: keyPath]
    return ColumnGroup<Root, Member>(
      keyPath: self.keyPath.appending(path: column.keyPath)
    )
  }

  public var _allColumns: [any TableColumnExpression] {
    Values.TableColumns.allColumns.map { column in
      func open<R, V>(
        _ column: some TableColumnExpression<R, V>
      ) -> any TableColumnExpression {
        let keyPath = keyPath.appending(
          path: unsafeDowncast(column.keyPath, to: KeyPath<Values, V.QueryOutput>.self)
        )
        return TableColumn<Root, V>(
          column.name,
          keyPath: keyPath,
          default: column.defaultValue
        )
      }
      return open(column)
    }
  }

  public var _writableColumns: [any WritableTableColumnExpression] {
    Values.TableColumns.writableColumns.map { column in
      func open<R, V>(
        _ column: some WritableTableColumnExpression<R, V>
      ) -> any WritableTableColumnExpression {
        let keyPath = keyPath.appending(
          path: unsafeDowncast(column.keyPath, to: KeyPath<Values, V.QueryOutput>.self)
        )
        return TableColumn<Root, V>(
          column.name,
          keyPath: keyPath,
          default: column.defaultValue
        )
      }
      return open(column)
    }
  }
}
