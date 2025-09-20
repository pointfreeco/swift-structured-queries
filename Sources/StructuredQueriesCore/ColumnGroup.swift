@dynamicMemberLookup
public struct ColumnGroup<Root: Table, Values: Table>: QueryExpression {
  public typealias QueryValue = Values

  public static func allColumns(keyPath: KeyPath<Root, Values>) -> [any TableColumnExpression] {
    return Values.TableColumns.allColumns.map { column in
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

  public static func writableColumns(
    keyPath: KeyPath<Root, Values>
  ) -> [any WritableTableColumnExpression] {
    return Values.TableColumns.writableColumns.map { column in
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

  let keyPath: KeyPath<Root, Values>

  public init(keyPath: KeyPath<Root, Values>) {
    self.keyPath = keyPath
  }

  public var queryFragment: QueryFragment {
    ColumnGroup.allColumns(keyPath: keyPath).map(\.queryFragment).joined(separator: ", ")
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, TableColumn<Values, Member>> & Sendable
  ) -> TableColumn<Root, Member> {
    let column = Values.columns[keyPath: keyPath]
    return TableColumn<Root, Member>(
      column.name,
      keyPath: self.keyPath.appending(path: column.keyPath),
      default: column.defaultValue
    )
  }
}
