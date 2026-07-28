import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

@Selection private struct Dimensions: Codable {
  var width = 0
  var height = 0
}

@Table private struct Photo: Codable {
  let id: Int
  var dimensions: Dimensions
}

@Table private struct Album: Codable {
  let id: Int
  @Column(as: [Photo].JSONRepresentation.self)
  var photos: [Photo] = []
}

extension SnapshotTests {
  @MainActor
  @Suite struct NestedStructJSONTests {
    @Dependency(\.defaultDatabase) var db

    init() throws {
      try db.execute(
        """
        CREATE TABLE "photos" (
          "id" INTEGER PRIMARY KEY,
          "width" INTEGER NOT NULL,
          "height" INTEGER NOT NULL
        )
        """
      )
      try db.execute(
        Photo.insert {
          Photo(id: 1, dimensions: Dimensions(width: 800, height: 600))
        }
      )
    }

    // TODO: 'json_object' should nest column groups to match their 'Codable' conformances.
    @Test func jsonObjectDecodes() {
      withKnownIssue {
        assertQuery(
          Photo.select { $0.jsonObject() }
        ) {
          """
          SELECT json_object('id', json_quote("photos"."id"), json_object('dimensions', 'width', json_quote("photos"."width"), 'height', json_quote("photos"."height")))
          FROM "photos"
          """
        } results: {
          """
          ┌───────────────────────────┐
          │ Photo(                    │
          │   id: 1,                  │
          │   dimensions: Dimensions( │
          │     width: 800,           │
          │     height: 600           │
          │   )                       │
          │ )                         │
          └───────────────────────────┘
          """
        }
      }
    }

    @Test func jsonEachExtractsColumnGroups() throws {
      try db.execute(
        """
        CREATE TABLE "albums" (
          "id" INTEGER PRIMARY KEY,
          "photos" TEXT NOT NULL
        )
        """
      )
      try db.execute(
        Album.insert {
          Album(id: 1, photos: [Photo(id: 1, dimensions: Dimensions(width: 800, height: 600))])
        }
      )
      assertQuery(
        Album.join(Album.columns.photos.jsonEach()) { _, _ in true }.select { $1 }
      ) {
        """
        SELECT "json_each"."key", "json_each"."value"
        FROM "albums"
        JOIN json_each("albums"."photos") ON 1
        """
      } results: {
        """
        ┌─────────────────────────────┐
        │ JSONEach(                   │
        │   key: 0,                   │
        │   value: Photo(             │
        │     id: 1,                  │
        │     dimensions: Dimensions( │
        │       width: 800,           │
        │       height: 600           │
        │     )                       │
        │   )                         │
        │ )                           │
        └─────────────────────────────┘
        """
      }
    }

    // TODO: 'json_object' should nest column groups to match their 'Codable' conformances.
    @Test func jsonGroupArrayDecodes() {
      withKnownIssue {
        assertQuery(
          Photo.select { $0.jsonGroupArray() }
        ) {
          """
          SELECT json_group_array(json_object('id', json_quote("photos"."id"), json_object('dimensions', 'width', json_quote("photos"."width"), 'height', json_quote("photos"."height"))))
          FROM "photos"
          """
        } results: {
          """
          ┌─────────────────────────────┐
          │ [                           │
          │   [0]: Photo(               │
          │     id: 1,                  │
          │     dimensions: Dimensions( │
          │       width: 800,           │
          │       height: 600           │
          │     )                       │
          │   )                         │
          │ ]                           │
          └─────────────────────────────┘
          """
        }
      }
    }
  }
}
