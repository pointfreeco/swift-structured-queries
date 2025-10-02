extension Never: Table {
  public struct TableColumns: TableDefinition {
    public typealias QueryValue = Never

    public static var allColumns: [any TableColumnExpression] { [] }

    public static var writableColumns: [any WritableTableColumnExpression] { [] }
  }

  public struct Selection: TableExpression {
    public typealias QueryValue = Never

    public var allColumns: [any QueryExpression] { [] }
  }

  public static var columns: TableColumns {
    TableColumns()
  }

  public static let tableName = "nevers"

  public init(decoder: inout some QueryDecoder) throws {
    throw NotDecodable()
  }

  private struct NotDecodable: Error {}
}
