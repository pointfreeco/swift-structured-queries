/// A group of table columns representing an optional selection member.
///
/// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros
/// to generate values of this type.
@dynamicMemberLookup
public struct OptionalColumnGroup<Root: Table, Values: Table>: _TableColumnExpression
where Values.QueryOutput: Table {
  public typealias QueryValue = Values?
  public typealias Value = Values?

  package let base: ColumnGroup<Root, Values?>

  package init(base: ColumnGroup<Root, Values?>) {
    self.base = base
  }

  package var name: String { base.name }

  public var _names: [String] { base._names }

  public var defaultValue: Values.QueryOutput?? { base.defaultValue }

  public var keyPath: KeyPath<Root, Values.QueryOutput?> { base.keyPath }

  public var queryFragment: QueryFragment { base.queryFragment }

  public var _allColumns: [any TableColumnExpression] { base._allColumns }

  public var _writableColumns: [any WritableTableColumnExpression] { base._writableColumns }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      Values.QueryOutput.TableColumns, TableColumn<Values.QueryOutput, Member>
    >
  ) -> TableColumn<Root, Member?> {
    let column = Values.QueryOutput.columns[keyPath: keyPath]
    return TableColumn<Root, Member?>(
      column.name,
      keyPath: base.keyPath.appending(path: \.[member: \Member.self, column: column.keyPath])
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      Values.QueryOutput.TableColumns, ColumnGroup<Values.QueryOutput, Member>
    >
  ) -> OptionalColumnGroup<Root, Member> {
    let column = Values.QueryOutput.columns[keyPath: keyPath]
    return OptionalColumnGroup<Root, Member>(
      base: ColumnGroup<Root, Member?>(
        column.name,
        keyPath: base.keyPath.appending(path: \.[member: \Member.self, column: column.keyPath])
      )
    )
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<
      Values.QueryOutput.TableColumns, OptionalColumnGroup<Values.QueryOutput, Member>
    >
  ) -> OptionalColumnGroup<Root, Member> {
    let column = Values.QueryOutput.columns[keyPath: keyPath]
    return OptionalColumnGroup<Root, Member>(
      base: ColumnGroup<Root, Member?>(
        column.name,
        keyPath: base.keyPath.appending(
          path: \.[flattenedMember: \Member.self, column: column.keyPath]
        )
      )
    )
  }
}

extension Optional where Wrapped: Table {
  subscript<Member: QueryRepresentable>(
    flattenedMember _: KeyPath<Member, Member>,
    column keyPath: KeyPath<Wrapped, Member.QueryOutput?>
  ) -> Member.QueryOutput? {
    self?[keyPath: keyPath] ?? nil
  }
}
