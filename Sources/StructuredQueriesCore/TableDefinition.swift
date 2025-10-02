/// A type representing a database table's columns.
///
/// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros
/// to generate values of this type. See <doc:DefiningYourSchema> for more information.
@dynamicMemberLookup
public protocol TableDefinition<QueryValue>: QueryExpression where QueryValue: Table {
  /// An array of this table's columns.
  static var allColumns: [any TableColumnExpression] { get }

  /// An array of this table's writable (non-generated) columns.
  static var writableColumns: [any WritableTableColumnExpression] { get }
}

extension TableDefinition {
  public var queryFragment: QueryFragment {
    Self.allColumns.map(\.queryFragment).joined(separator: ", ")
  }

  // NB: Without this identity subscript, a more confusing error is produced for missing columns:
  //
  // > Referencing subscript 'subscript(dynamicMember:)' on 'TableDefinition' requires that 'T'
  // > conform to 'TableDraft'
  @_disfavoredOverload
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Self, Member>
  ) -> Member {
    self[keyPath: keyPath]
  }

  public static var _columnWidth: Int {
    QueryValue._columnWidth
  }

  public var _allColumns: [any QueryExpression] {
    Self.allColumns
  }
}
