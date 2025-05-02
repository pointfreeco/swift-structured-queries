import Foundation
import PostgresNIO
import StructuredQueries

struct PostgresDecoder: QueryDecoder {
  var rows: PostgresRowSequence.AsyncIterator
  var row: PostgresRow.Iterator?

  mutating func decode(_ columnType: Int.Type) throws -> Int? {
    try row?.next()?.decode(Int.self)
  }

  mutating func decode(_ columnType: Int64.Type) throws -> Int64? {
    try row?.next()?.decode(Int64.self)
  }

  mutating func decode(_ columnType: String.Type) throws -> String? {
    try row?.next()?.decode(String.self)
  }

  mutating func decode(_ columnType: [UInt8].Type) throws -> [UInt8]? {
    try row?.next()?.decode([UInt8].self)
  }

  mutating func decode(_ columnType: Double.Type) throws -> Double? {
    let tmp = row?.next()
    return try tmp?.decode(Double.self)
  }

  mutating func decode(_ columnType: Date.Type) throws -> Date? {
    try row?.next()?.decode(Date.self)
  }

  mutating func next() async throws -> Bool {
    row = try await rows.next()?.makeIterator()
    return row != nil
  }
}

@available(macOS 15.0, *)
extension PostgresClient {
  public func query<S: SelectStatement, each J: Table>(
    _ query: S
  ) throws -> some AsyncSequence<(S.From.QueryOutput, repeat (each J).QueryOutput), any Error>
  where S.QueryValue == (), S.Joins == (repeat each J), repeat (each J).QueryOutput: Sendable, S.From.QueryOutput: Sendable {
    let tmp = query.selectStar().asSelect()
    let tmp2 = try self.query(tmp)
    return tmp2
  }

  public func query<S: SelectStatement>(_ query: S) throws -> some AsyncSequence<S.From.QueryOutput, any Error>
  where S.QueryValue == (), S.Joins == (), S.From.QueryOutput: Sendable {
    try self.query(query.selectStar().asSelect())
  }

  public func query<S: Statement>(_ query: S) throws -> some AsyncSequence<S.QueryValue.QueryOutput, any Error>
  where S.QueryValue: QueryRepresentable, S.QueryValue.QueryOutput: Sendable {
    let queryFragment = query.query
    let postgresQuery = try PostgresQuery(queryFragment: queryFragment)
    return AsyncThrowingStream { continuation in
      Task {
        let rows = try await self.query(postgresQuery)
        var decoder = PostgresDecoder(rows: rows.makeAsyncIterator())
        while try await decoder.next() {
          continuation.yield(with: Result { try decoder.decodeColumns(S.QueryValue.self) })
        }
        continuation.finish()
      }
    }
  }

  @available(macOS 15.0, *)
  public func query<each V: QueryRepresentable>(
    _ query: some Statement<(repeat each V)>
  ) throws -> some AsyncSequence<(repeat (each V).QueryOutput), any Error>
  where repeat (each V).QueryOutput: Sendable
  {
    let queryFragment = query.query
    let postgresQuery = try PostgresQuery(queryFragment: queryFragment)
    return AsyncThrowingStream { continuation in
      Task {
        let rows = try await self.query(postgresQuery)
        var decoder = PostgresDecoder(rows: rows.makeAsyncIterator())
        while try await decoder.next() {
          continuation.yield(with: Result { try decoder.decodeColumns((repeat each V).self) })
        }
        continuation.finish()
      }
    }
  }
}

extension PostgresQuery {
  init(queryFragment: QueryFragment) throws {
    try self.init(
      unsafeSQL: queryFragment.string,
      binds: queryFragment.postgresBindings
    )
  }
}

extension QueryFragment {
  var postgresBindings: PostgresBindings {
    get throws {
      var postgresBindings = PostgresBindings()
      for binding in bindings {
        switch binding {
        case .blob(let value):
          postgresBindings.append(value)
        case .double(let value):
          postgresBindings.append(value)
        case .int(let value):
          postgresBindings.append(value)
        case .null:
          postgresBindings.appendNull()
        case .text(let value):
          postgresBindings.append(value)
        case .invalid(let value):
          throw value
        }
      }
      return postgresBindings
    }
  }
}
