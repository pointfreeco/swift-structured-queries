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
          SELECT json_object('id', json_quote("photos"."id"), 'width', json_quote("photos"."width"), 'height', json_quote("photos"."height"))
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

    // TODO: 'json_object' should nest column groups to match their 'Codable' conformances.
    @Test func jsonGroupArrayDecodes() {
      withKnownIssue {
        assertQuery(
          Photo.select { $0.jsonGroupArray() }
        ) {
          """
          SELECT json_group_array(json_object('id', json_quote("photos"."id"), 'width', json_quote("photos"."width"), 'height', json_quote("photos"."height")))
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
