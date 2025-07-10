extension Never: Table {
  public typealias QueryValue = Never

  public struct TableColumns: TableDefinition {
    public typealias QueryValue = Never

    public static var allColumns: [any TableColumnExpression] { [] }
  }

  public static var columns: TableColumns {
    TableColumns()
  }

  public static let tableName = "nevers"

  public var queryFragment: QueryFragment {
    fatalError()
  }

  public init(decoder: inout some QueryDecoder) throws {
    throw NotDecodable()
  }

  private struct NotDecodable: Error {}
}
