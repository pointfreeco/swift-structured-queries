import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesCore
import StructuredQueriesSQLite
import StructuredQueriesSQLiteCore
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

#if canImport(Darwin)
  import SQLite3
#else
  import _StructuredQueriesSQLite3
#endif

extension SnapshotTests {
  @Suite struct MapTests {
    @Dependency(\.defaultDatabase) var database

    @Test func mapWithDatabaseFunction() throws {
      $increment.install(database.handle)
      try database.execute(
        """
        CREATE TABLE "optionalIntegers" (
          "value" INTEGER
        ) STRICT
        """)
      try database.execute(
        """
        INSERT INTO "optionalIntegers" ("value") VALUES (1), (NULL), (3)
        """)

      assertQuery(
        OptionalInteger.select {
          $0.value.map { $increment($0) }
        }
      ) {
        """
        SELECT CASE "optionalIntegers"."value" IS NULL WHEN 1 THEN NULL ELSE "increment"("optionalIntegers"."value") END
        FROM "optionalIntegers"
        """
      } results: {
        """
        ┌─────┐
        │ 2   │
        │ nil │
        │ 4   │
        └─────┘
        """
      }
    }
  }
}

@Table struct OptionalInteger {
  let value: Int?
}
@DatabaseFunction(isDeterministic: true)
private func increment(_ value: Int) -> Int {
  value + 1
}
