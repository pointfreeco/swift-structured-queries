/// A type representing a database table's columns.
///
/// Don't conform to this protocol directly. Instead, use the `@Table` and `@Column` macros to
/// generate a conformance.
@dynamicMemberLookup
public protocol TableDefinition<QueryValue>: QueryExpression where QueryValue: Table {
  /// An array of this table's columns.
  static var allColumns: [any TableColumnExpression] { get }
}

extension TableDefinition {
  public var queryFragment: QueryFragment {
    Self.allColumns.map(\.queryFragment).joined(separator: ", ")
  }
}
