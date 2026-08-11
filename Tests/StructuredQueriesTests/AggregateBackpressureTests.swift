import Dependencies
import Foundation
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct AggregateBackpressureTests {
    @Dependency(\.defaultDatabase) var database

    @DatabaseFunction
    func sumAll(_ values: some Sequence<Int>) -> Int {
      values.reduce(0, &+)
    }

    // Takes one element, then pauses long enough for the producer to fill the buffer and
    // block, so that returning strands a waiting producer unless it is signalled.
    @DatabaseFunction
    func firstValue(_ values: some Sequence<Int>) -> Int? {
      var iterator = values.makeIterator()
      let first = iterator.next()
      Thread.sleep(forTimeInterval: 0.1)
      return first
    }

    private func makeRows(_ count: Int) throws {
      try database.execute(
        #sql(
          """
          CREATE TEMP TABLE rows AS
          WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM c WHERE x < \(raw: count))
          SELECT x FROM c
          """
        )
      )
    }

    @Test(.timeLimit(.minutes(1)))
    func aggregatesEveryRowWhenProducerOutrunsConsumer() throws {
      $sumAll.install(database.handle)
      try makeRows(5000)
      let result = try database.execute(#sql("SELECT sumAll(x) FROM rows", as: Int.self))
      #expect(result == [5000 * 5001 / 2])
    }

    @Test(.timeLimit(.minutes(1)))
    func earlyReturnDoesNotStallProducer() throws {
      $firstValue.install(database.handle)
      try makeRows(5000)
      let result = try database.execute(#sql("SELECT firstValue(x) FROM rows", as: Int?.self))
      #expect(result == [1])
    }

    @Test(.timeLimit(.minutes(1)))
    func groupedAggregationKeepsAccumulatorsSeparate() throws {
      $sumAll.install(database.handle)
      try makeRows(5000)
      let results = try database.execute(
        #sql(
          "SELECT sumAll(x) FROM rows GROUP BY x % 2 ORDER BY x % 2",
          as: Int.self
        )
      )
      let evens = stride(from: 2, through: 5000, by: 2).reduce(0, +)
      let odds = stride(from: 1, through: 4999, by: 2).reduce(0, +)
      #expect(results == [evens, odds])
    }

    @Test func aggregatesEmptyInput() throws {
      $sumAll.install(database.handle)
      try makeRows(5000)
      let result = try database.execute(
        #sql("SELECT sumAll(x) FROM rows WHERE x < 0", as: Int.self)
      )
      #expect(result == [0])
    }
  }
}
