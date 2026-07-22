import Dependencies
import Foundation
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

private enum Ranking: Int {
  case low, medium, high
}

@Table
private struct Item {
  let id: Int
  @Column(as: Ranking.RawRepresentation.self)
  var ranking: Ranking
  @Column(as: Ranking?.RawRepresentation.self)
  var backupRanking: Ranking?
}

extension SnapshotTests {
  @MainActor
  @Suite struct RawRepresentationTests {
    let db: Database

    init() throws {
      db = try Database()
      try db.execute(
        #sql(
          """
          CREATE TABLE "items" (
            "id" INTEGER PRIMARY KEY,
            "ranking" INTEGER NOT NULL,
            "backupRanking" INTEGER
          )
          """
        )
      )
    }

    @Test func decoding() throws {
      try withDependencies {
        $0.defaultDatabase = db
      } operation: {
        try db.execute(
          #sql(
            """
            INSERT INTO "items" ("id", "ranking", "backupRanking")
            VALUES (1, 2, NULL), (2, 0, 2)
            """
          )
        )
        let items = try db.execute(Item.all)
        #expect(items.map(\.ranking) == [.high, .low])
        #expect(items.map(\.backupRanking) == [nil, .high])
      }
    }

    @Test func binding() throws {
      try withDependencies {
        $0.defaultDatabase = db
      } operation: {
        assertQuery(
          Item.insert {
            Item.Draft(id: 1, ranking: .medium, backupRanking: .high)
          }
          .returning(\.self)
        ) {
          """
          INSERT INTO "items"
          ("id", "ranking", "backupRanking")
          VALUES
          (1, 1, 2)
          RETURNING "id", "ranking", "backupRanking"
          """
        } results: {
          """
          ┌────────────────────────┐
          │ Item(                  │
          │   id: 1,               │
          │   ranking: .medium,    │
          │   backupRanking: .high │
          │ )                      │
          └────────────────────────┘
          """
        }
      }
    }
  }
}
