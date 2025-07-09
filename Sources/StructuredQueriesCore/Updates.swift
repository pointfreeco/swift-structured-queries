/// A collection of updates used in an update clause.
///
/// A mutable value of this type is passed to the `updates` closure of `Table.update`, as well as
/// the `doUpdate` closure of `Table.insert`.
///
/// To learn more, see <doc:UpdateStatements>.
@dynamicMemberLookup
public struct Updates<Base: Table> {
  private var updates: [(String, QueryFragment)] = []

  package init(_ body: (inout Self) -> Void) {
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
  public subscript<Value: QueryExpression>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, some TableColumnExpression<Base, Value>>
  ) -> Value.QueryOutput {
    @available(*, unavailable)
    get { fatalError() }
    set {
      updates.append(
        (Base.columns[keyPath: keyPath].name, Value(queryOutput: newValue).queryFragment)
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

extension Updates {
  public subscript<Member: Table>(
    dynamicMember keyPath: KeyPath<Base.TableColumns, SubtableColumns<Base, Member>>
  ) -> Updates<Member.QueryValue> {
    get { Updates<Member.QueryValue> { _ in } }
    set { updates.append(contentsOf: newValue.updates) }
  }
}

@dynamicMemberLookup
public struct SubtableColumns<Root: Table, Value: Table>: QueryExpression {
  public typealias QueryValue = Value

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
