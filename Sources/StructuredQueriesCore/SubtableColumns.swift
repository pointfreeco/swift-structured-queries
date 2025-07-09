@dynamicMemberLookup
public struct SubtableColumns<Root: Table, Value: Table>: QueryExpression {
  public typealias QueryValue = Value

  public static func allColumns(keyPath: KeyPath<Root, Value> & Sendable) -> [any TableColumnExpression] {
    return Value.TableColumns.allColumns.map { column in
      func open<R, V>(
        _ column: some TableColumnExpression<R, V>
      ) -> any TableColumnExpression {
        let keyPath = keyPath.appending(
          path: unsafeDowncast(column.keyPath, to: KeyPath<Value, V.QueryOutput>.self)
        )
        return TableColumn<Root, V>(
          column.name,
          keyPath: keyPath.unsafeSendable(),
          default: column.defaultValue
        )
      }
      return open(column)
    }
  }

  let keyPath: KeyPath<Root, Value> & Sendable

  public init(keyPath: KeyPath<Root, Value> & Sendable) {
    self.keyPath = keyPath
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.TableColumns, TableColumn<Value, Member>> & Sendable
  ) -> TableColumn<Root, Member> {
    let column = Value.columns[keyPath: keyPath]
    return TableColumn<Root, Member>(
      column.name,
      keyPath: self.keyPath.appending(path: column._keyPath).unsafeSendable(),
      default: column.defaultValue
    )
  }

  public var queryFragment: QueryFragment {
    Value.columns.queryFragment
  }
}
