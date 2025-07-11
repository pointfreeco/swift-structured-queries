/// A collection of updates used in an update clause.
///
/// A mutable value of this type is passed to the `updates` closure of `Table.update`, as well as
/// the `doUpdate` closure of `Table.insert`.
///
/// To learn more, see <doc:UpdateStatements>.
@dynamicMemberLookup
public struct Updates<Base: Table> {
  private var updates: [(String, QueryFragment)] = []

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
