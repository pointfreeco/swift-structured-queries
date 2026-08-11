import Foundation

// NB: Deprecated after 0.33.3:

extension Table {
  @available(*, deprecated, message: "Use 'limit(_:)' and 'offset(_:)', instead.")
  public static func limit(
    _ maxLength: (TableColumns) -> some QueryExpression<Int>,
    offset: ((TableColumns) -> some QueryExpression<Int>)?
  ) -> SelectOf<Self> {
    Where().limit(maxLength, offset: offset)
  }

  @available(*, deprecated, message: "Use 'limit(_:)' and 'offset(_:)', instead.")
  public static func limit(_ maxLength: Int, offset: Int?) -> SelectOf<Self> {
    Where().limit(maxLength, offset: offset)
  }
}

extension Where {
  @available(*, deprecated, message: "Use 'limit(_:)' and 'offset(_:)', instead.")
  public func limit(
    _ maxLength: (From.TableColumns) -> some QueryExpression<Int>,
    offset: ((From.TableColumns) -> some QueryExpression<Int>)?
  ) -> SelectOf<From> {
    asSelect().limit(maxLength, offset: offset)
  }

  @available(*, deprecated, message: "Use 'limit(_:)' and 'offset(_:)', instead.")
  public func limit(_ maxLength: Int, offset: Int?) -> SelectOf<From> {
    asSelect().limit(maxLength, offset: offset)
  }
}

extension Select {
  @_disfavoredOverload
  @available(*, deprecated, message: "Use 'limit(_:)' and 'offset(_:)', instead.")
  public func limit<each J: Table>(
    _ maxLength: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<Int>,
    offset: ((From.TableColumns, repeat (each J).TableColumns) -> any QueryExpression<Int>)?
  ) -> Self
  where Joins == (repeat each J) {
    limit(maxLength(From.columns, repeat (each J).columns))
      .offset(offset?(From.columns, repeat (each J).columns))
  }

  @_disfavoredOverload
  @available(*, deprecated, message: "Use 'limit(_:)' and 'offset(_:)', instead.")
  public func limit(
    _ maxLength: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<Int>,
    offset: ((From.TableColumns, Joins.TableColumns) -> any QueryExpression<Int>)?
  ) -> Self
  where Joins: Table {
    limit(maxLength(From.columns, Joins.columns))
      .offset(offset?(From.columns, Joins.columns))
  }

  @available(*, deprecated, message: "Use 'limit(_:)' and 'offset(_:)', instead.")
  public func limit<each J: Table>(_ maxLength: Int, offset: Int?) -> Self
  where Joins == (repeat each J) {
    limit(maxLength).offset(offset)
  }
}

// NB: Deprecated after 0.33.1:

extension QueryExpression where QueryValue == String {
  @available(*, deprecated, message: "Prefer 'like(\"\\(other)%\")' instead")
  public func hasPrefix(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    like("\(other)%")
  }

  @available(*, deprecated, message: "Prefer 'like(\"%\\(other)\")' instead")
  public func hasSuffix(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    like("%\(other)")
  }

  @_disfavoredOverload
  @available(*, deprecated, message: "Prefer 'like(\"%\\(other)%\")' instead")
  public func contains(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    return like("%\(other)%")
  }
}

extension Sequence where Element: QueryBindable {
  @available(*, deprecated, message: "Prefer 'element.in(self)' instead")
  public func contains(
    _ element: some QueryExpression<Element.QueryValue>
  ) -> some QueryExpression<Bool> {
    element.in(self)
  }
}

extension ClosedRange where Bound: QueryBindable {
  @available(
    *,
    deprecated,
    message: "Prefer 'element.between(lowerBound, and: upperBound)' instead"
  )
  public func contains(
    _ element: some QueryExpression<Bound.QueryValue>
  ) -> some QueryExpression<Bool> {
    element.between(lowerBound, and: upperBound)
  }
}

// NB: Deprecated after 0.32.0:

extension TableDraft {
  @available(*, deprecated, renamed: "SourceTable")
  public typealias PrimaryTable = SourceTable
}

// NB: Deprecated after 0.6.0:

extension QueryFragment {
  @available(
    *,
    deprecated,
    message: "Use 'QueryFragment.segments' to build up a SQL string and bindings in a single loop."
  )
  public var string: String {
    segments.reduce(into: "") { string, segment in
      switch segment {
      case .sql(let sql):
        string.append(sql)
      case .binding:
        string.append("?")
      }
    }
  }

  @available(
    *,
    deprecated,
    message: "Use 'QueryFragment.segments' to build up a SQL string and bindings in a single loop."
  )
  public var bindings: [QueryBinding] {
    segments.reduce(into: []) { bindings, segment in
      switch segment {
      case .sql:
        break
      case .binding(let binding):
        bindings.append(binding)
      }
    }
  }
}

// NB: Deprecated after 0.5.1:

extension Table {
  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.insert { row }'"
  )
  public static func insert(
    _ row: Self,
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert([row], onConflict: doUpdate)
  }

  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.insert { rows }'"
  )
  public static func insert(
    _ rows: [Self],
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(values: { rows }, onConflict: doUpdate)
  }

  @available(*, deprecated, renamed: "insert(_:values:onConflictDoUpdate:)")
  public static func insert(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflict updates: ((inout Updates<Self>) -> Void)?
  ) -> InsertOf<Self> {
    insert(columns, values: values, onConflictDoUpdate: updates)
  }

  @available(*, deprecated, renamed: "insert(_:values:onConflictDoUpdate:)")
  public static func insert<V1, each V2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflict updates: ((inout Updates<Self>) -> Void)?
  ) -> InsertOf<Self> {
    insert(columns, values: values, onConflictDoUpdate: updates)
  }

  @available(*, deprecated, renamed: "insert(_:select:onConflictDoUpdate:)")
  public static func insert<
    V1, each V2, From, Joins
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> Select<(V1, repeat each V2), From, Joins>,
    onConflict updates: ((inout Updates<Self>) -> Void)?
  ) -> InsertOf<Self> {
    insert(columns, select: selection, onConflictDoUpdate: updates)
  }
}

extension PrimaryKeyedTable {
  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.insert { draft }'"
  )
  public static func insert(
    _ row: Draft,
    onConflict updates: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(values: { row }, onConflictDoUpdate: updates)
  }

  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.insert { drafts }'"
  )
  public static func insert(
    _ rows: [Draft],
    onConflict updates: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(values: { rows }, onConflictDoUpdate: updates)
  }

  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.upsert { draft }'"
  )
  public static func upsert(_ row: Draft) -> InsertOf<Self> {
    upsert { row }
  }
}

// NB: Deprecated after 0.1.1:

@available(*, deprecated, message: "Use 'MyCodableType.JSONRepresentation', instead.")
public typealias JSONRepresentation<Value: Codable> = _CodableJSONRepresentation<Value>
