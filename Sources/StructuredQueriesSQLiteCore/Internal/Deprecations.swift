import Foundation
import StructuredQueriesCore

// NB: Deprecated after 0.5.1:

extension Table {
  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.insert { row }'"
  )
  public static func insert(
    or conflictResolution: ConflictResolution,
    _ row: Self,
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(or: conflictResolution, [row], onConflict: doUpdate)
  }

  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.insert { rows }'"
  )
  public static func insert(
    or conflictResolution: ConflictResolution,
    _ rows: [Self],
    onConflict doUpdate: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(or: conflictResolution, values: { rows }, onConflict: doUpdate)
  }

  @available(*, deprecated, renamed: "insert(or:_:values:onConflictDoUpdate:)")
  public static func insert(
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflict updates: ((inout Updates<Self>) -> Void)?
  ) -> InsertOf<Self> {
    insert(or: conflictResolution, columns, values: values, onConflictDoUpdate: updates)
  }

  @available(*, deprecated, renamed: "insert(or:_:values:onConflictDoUpdate:)")
  public static func insert<V1, each V2>(
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflict updates: ((inout Updates<Self>) -> Void)?
  ) -> InsertOf<Self> {
    insert(or: conflictResolution, columns, values: values, onConflictDoUpdate: updates)
  }

  @available(*, deprecated, renamed: "insert(or:_:select:onConflictDoUpdate:)")
  public static func insert<
    V1, each V2, From, Joins
  >(
    or conflictResolution: ConflictResolution,
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> Select<(V1, repeat each V2), From, Joins>,
    onConflict updates: ((inout Updates<Self>) -> Void)?
  ) -> InsertOf<Self> {
    insert(or: conflictResolution, columns, select: selection, onConflictDoUpdate: updates)
  }
}

extension PrimaryKeyedTable {
  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.insert { draft }'"
  )
  public static func insert(
    or conflictResolution: ConflictResolution,
    _ row: Draft,
    onConflict updates: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(or: conflictResolution, values: { row }, onConflictDoUpdate: updates)
  }

  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.insert { drafts }'"
  )
  public static func insert(
    or conflictResolution: ConflictResolution,
    _ rows: [Draft],
    onConflict updates: ((inout Updates<Self>) -> Void)? = nil
  ) -> InsertOf<Self> {
    insert(or: conflictResolution, values: { rows }, onConflictDoUpdate: updates)
  }

  @available(
    *, deprecated, message: "Use a trailing closure, instead: 'Table.upsert { draft }'"
  )
  public static func upsert(
    or conflictResolution: ConflictResolution,
    _ row: Draft
  ) -> InsertOf<Self> {
    upsert(or: conflictResolution) { row }
  }
}

// NB: Deprecated after 0.3.0:

extension Date {
  @available(
    *,
    deprecated,
    message: "ISO-8601 text is the default representation and is no longer explicitly needed."
  )
  public struct ISO8601Representation: QueryRepresentable {
    public var queryOutput: Date

    public var iso8601String: String {
      queryOutput.iso8601String
    }

    public init(queryOutput: Date) {
      self.queryOutput = queryOutput
    }

    public init(iso8601String: String) throws {
      try self.init(queryOutput: Date(iso8601String: iso8601String))
    }
  }
}

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date? {
  public typealias ISO8601Representation = Date.ISO8601Representation?
}

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date.ISO8601Representation: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(queryOutput.iso8601String)
  }
}

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date.ISO8601Representation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(queryOutput: Date(iso8601String: String(decoder: &decoder)))
  }
}

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date.ISO8601Representation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID {
  public struct LowercasedRepresentation: QueryRepresentable {
    public var queryOutput: UUID

    public init(queryOutput: UUID) {
      self.queryOutput = queryOutput
    }
  }
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID? {
  public typealias LowercasedRepresentation = UUID.LowercasedRepresentation?
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID.LowercasedRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(queryOutput.uuidString.lowercased())
  }
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID.LowercasedRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    guard let uuid = try UUID(uuidString: String(decoder: &decoder)) else {
      throw InvalidString()
    }
    self.init(queryOutput: uuid)
  }

  private struct InvalidString: Error {}
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID.LowercasedRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}
