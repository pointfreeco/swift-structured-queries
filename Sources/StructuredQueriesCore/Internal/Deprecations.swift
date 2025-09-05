import Foundation

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
