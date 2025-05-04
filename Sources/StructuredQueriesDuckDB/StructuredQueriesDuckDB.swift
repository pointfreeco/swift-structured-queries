import DuckDB
import Foundation
import StructuredQueries

struct DuckDBDecoder: QueryDecoder {
  var resultSet: ResultSet.Iterator

  mutating func decode(_ columnType: Int.Type) throws -> Int? {
    //try row?.next()?.decode(Int.self)
    let tmp = resultSet.next()
    let tmp2 = tmp!.cast(to: Int.self)
    tmp2
    return nil
  }
}

func foo() throws {
  let database = try Database(store: .inMemory)
  let connection = try database.connect()
  let resultSet = try PreparedStatement(connection: connection, queryFragment: "SELECT * FROM reminders")
    .execute()

  
}

extension PreparedStatement {
  convenience init(connection: Connection, queryFragment: QueryFragment) throws {
    try self.init(connection: connection, query: queryFragment.string)
    for (position, binding) in queryFragment.bindings.enumerated() {
      switch binding {
      case .blob(let value):
        try self.bind(Data(value), at: position)
      case .double(let value):
        try self.bind(value, at: position)
      case .int(let value):
        try self.bind(value, at: position)
      case .null:
        fatalError("TODO")
      case .text(let value):
        try self.bind(value, at: position)
      case .invalid(let value):
        throw value
      }
    }
  }
}
