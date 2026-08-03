/// A collection of updates used in an update clause.
///
/// A mutable value of this type is passed to the `updates` closure of `Table.update`, as well as
/// the `doUpdate` closure of `Table.insert`.
///
/// To learn more, see <doc:UpdateStatements>.
@dynamicMemberLookup
public struct Updates<Base: Table> {
  package var updates: [(String, QueryFragment)] = []

  init(_ body: (inout Self) -> Void) {
    body(&self)
  }

  var isEmpty: Bool {
    updates.isEmpty
  }

  mutating func set(
    _ column: some TableColumnExpression,
    _ value: QueryFragment
  ) {
    updates.append((column.name, value))
  }

  public subscript<Value>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, TableColumn<Base, Value>>
  ) -> any QueryExpression<Value> {
    get { Base.columns[keyPath: keyPath] }
    set { updates.append((Base.columns[keyPath: keyPath].name, newValue.queryFragment)) }
  }

  @_disfavoredOverload
  public subscript<Value>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, TableColumn<Base, Value>>
  ) -> SQLQueryExpression<Value> {
    get { SQLQueryExpression(Base.columns[keyPath: keyPath]) }
    set { updates.append((Base.columns[keyPath: keyPath].name, newValue.queryFragment)) }
  }

  @_disfavoredOverload
  @available(
    *,
    unavailable,
    message: """
      Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
      """
  )
  public subscript<Value: QueryExpression>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, TableColumn<Base, Value>>
  ) -> Value.QueryOutput {
    get { fatalError() }
    set {}
  }

  public subscript<Value: Table>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, ColumnGroup<Base, Value>>
  ) -> UpdatesGroup<Base, Value> {
    get { UpdatesGroup(group: Base.columns[keyPath: keyPath]) }
    set { updates.append(contentsOf: newValue.updates) }
  }

  public subscript<Value>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, OptionalColumnGroup<Base, Value>>
  ) -> UpdatesGroup<Base, Value?> {
    get { UpdatesGroup<Base, Value?>(group: Base.columns[keyPath: keyPath].base) }
    set { updates.append(contentsOf: newValue.updates) }
  }

  @_disfavoredOverload
  public subscript<Value>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, OptionalColumnGroup<Base, Value>>
  ) -> Value.QueryOutput? {
    @available(
      *,
      unavailable,
      message: """
        Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
        """
    )
    get { fatalError() }
    set {
      func open<R, V>(
        _ column: some WritableTableColumnExpression<R, V>
      ) -> QueryFragment {
        V(
          queryOutput: Value?(queryOutput: newValue)[
            keyPath: column.keyPath as! KeyPath<Value?, V.QueryOutput>
          ]
        )
        .queryFragment
      }
      updates.append(
        contentsOf: Optional<Value>.TableColumns.writableColumns.map { column in
          (column.name, open(column))
        }
      )
    }
  }

  @_disfavoredOverload
  public subscript<Value: QueryExpression>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, ColumnGroup<Base, Value>>
  ) -> Value.QueryOutput {
    @available(
      *,
      unavailable,
      message: """
        Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
        """
    )
    get { fatalError() }
    set {
      func open<Root, V>(
        _ column: some WritableTableColumnExpression<Root, V>
      ) -> QueryFragment {
        V(
          queryOutput: Value(queryOutput: newValue)[
            keyPath: column.keyPath as! KeyPath<Value, V.QueryOutput>
          ]
        )
        .queryFragment
      }
      updates.append(
        contentsOf: Value.TableColumns.writableColumns.map { column in
          (column.name, open(column))
        }
      )
    }
  }
}

extension Updates: QueryExpression {
  public typealias QueryValue = Never

  public var queryFragment: QueryFragment {
    "SET \(updates.map { "\(quote: $0) = \($1)" }.joined(separator: ", "))"
  }
}

/// A collection of updates to a group of columns.
///
/// A value of this type is produced when an update clause navigates into a column group, _e.g._
/// the `$0.group` of `$0.group.property = value`. Its members are looked up directly on the
/// group's generated table definition.
@dynamicMemberLookup
public struct UpdatesGroup<Base: Table, Values: Table> where Values.QueryOutput: Table {
  package let group: ColumnGroup<Base, Values>
  package var updates: [(String, QueryFragment)] = []

  package init(group: ColumnGroup<Base, Values>) {
    self.group = group
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, TableColumn<Values.QueryOutput, Member>>
  ) -> any QueryExpression<Member> {
    get { group[dynamicMember: keyPath] }
    set { updates.append((group[dynamicMember: keyPath].name, newValue.queryFragment)) }
  }

  @_disfavoredOverload
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, TableColumn<Values.QueryOutput, Member>>
  ) -> SQLQueryExpression<Member> {
    get { SQLQueryExpression(group[dynamicMember: keyPath]) }
    set { updates.append((group[dynamicMember: keyPath].name, newValue.queryFragment)) }
  }

  @_disfavoredOverload
  @available(
    *,
    unavailable,
    message: """
      Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
      """
  )
  public subscript<Member: QueryExpression>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, TableColumn<Values.QueryOutput, Member>>
  ) -> Member.QueryOutput {
    get { fatalError() }
    set {}
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, ColumnGroup<Values.QueryOutput, Member>>
  ) -> UpdatesGroup<Base, Member> {
    get { UpdatesGroup<Base, Member>(group: group[dynamicMember: keyPath]) }
    set { updates.append(contentsOf: newValue.updates) }
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, OptionalColumnGroup<Values.QueryOutput, Member>>
  ) -> UpdatesGroup<Base, Member?> {
    get { UpdatesGroup<Base, Member?>(group: group[dynamicMember: keyPath].base) }
    set { updates.append(contentsOf: newValue.updates) }
  }

  @_disfavoredOverload
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Values.TableColumns, ColumnGroup<Values.QueryOutput, Member>>
  ) -> Member.QueryOutput {
    @available(
      *,
      unavailable,
      message: """
        Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
        """
    )
    get { fatalError() }
    set {
      func open<R, V>(
        _ column: some WritableTableColumnExpression<R, V>
      ) -> QueryFragment {
        V(
          queryOutput: Member(queryOutput: newValue)[
            keyPath: column.keyPath as! KeyPath<Member, V.QueryOutput>
          ]
        )
        .queryFragment
      }
      updates.append(
        contentsOf: Member.TableColumns.writableColumns.map { column in
          (column.name, open(column))
        }
      )
    }
  }
}
