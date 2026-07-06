import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

@Table
struct Location {
  @Column(lazyInitializable: true)
  var latitude: Double
  @Column(lazyInitializable: true)
  var longitude: Double
  var name: String
}

extension SnapshotTests {
  @Suite struct NonPrimaryKeyedDraftTests {
    func draftOfDraftIsNever() {
      let _: Never.Type = Location.Draft.Draft.self
    }

    @Test func insertDraftWithUninitializedColumns() {
      assertInlineSnapshot(
        of: Location.insert { Location.Draft(name: "Home") },
        as: .sql
      ) {
        """
        INSERT INTO "locations"
        ("latitude", "longitude", "name")
        VALUES
        (NULL, NULL, 'Home')
        """
      }
    }

    @Test func insertDraftFromRow() {
      let location = Location(latitude: 1, longitude: 2, name: "Home")
      assertInlineSnapshot(
        of: Location.insert { Location.Draft(location) },
        as: .sql
      ) {
        """
        INSERT INTO "locations"
        ("latitude", "longitude", "name")
        VALUES
        (1.0, 2.0, 'Home')
        """
      }
    }

    @Test func liveInsertLetsDatabaseFillUninitializedColumns() throws {
      let db = try Database()
      try db.execute(
        #sql(
          """
          CREATE TABLE "locations" (
            "latitude" REAL NOT NULL ON CONFLICT REPLACE DEFAULT 0,
            "longitude" REAL NOT NULL ON CONFLICT REPLACE DEFAULT 0,
            "name" TEXT NOT NULL
          )
          """
        )
      )
      try db.execute(Location.insert { Location.Draft(name: "Home") })
      let location = try #require(try db.execute(Location.all).first)
      #expect(location.latitude == 0)
      #expect(location.longitude == 0)
      #expect(location.name == "Home")
    }
  }
}
