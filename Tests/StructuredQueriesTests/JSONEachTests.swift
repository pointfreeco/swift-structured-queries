import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @MainActor
  @Suite struct JSONEachTests {
    @Dependency(\.defaultDatabase) var db

    init() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "trips" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "title" TEXT NOT NULL,
            "geofence" TEXT NOT NULL
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "taggedItems" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "title" TEXT NOT NULL,
            "tags" TEXT NOT NULL
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "products" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "inventory" TEXT NOT NULL
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "posts" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "reactions" TEXT NOT NULL,
            "writer" TEXT NOT NULL
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "routes" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "waypoints" TEXT
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "profiles" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "author" TEXT NOT NULL
          )
          """
        )
      )
      try db.execute(
        Trip.insert {
          Trip.Draft(
            title: "Northern",
            geofence: [
              Coordinate(latitude: 40.7, longitude: -74.0, label: "home"),
              Coordinate(latitude: 51.5, longitude: -0.1, label: "away"),
            ]
          )
          Trip.Draft(
            title: "Mixed",
            geofence: [
              Coordinate(latitude: 40.7, longitude: -74.0, label: "home"),
              Coordinate(latitude: -33.9, longitude: 151.2, label: "away"),
            ]
          )
          Trip.Draft(title: "Empty")
        }
      )
    }

    @Test func exists() {
      assertQuery(
        Trip
          .where {
            !$0.geofence.jsonEach()
              .where { $0.value.jsonExtract(\.latitude) < 0 }
              .exists()
          }
          .select(\.title)
      ) {
        """
        SELECT "trips"."title"
        FROM "trips"
        WHERE (NOT (EXISTS (
          SELECT "json_each"."key", "json_each"."value"
          FROM json_each("trips"."geofence")
          WHERE ((json_extract("json_each"."value", '$."latitude"')) < (0.0))
        )))
        """
      } results: {
        """
        ┌────────────┐
        │ "Northern" │
        │ "Empty"    │
        └────────────┘
        """
      }
    }

    @Test func count() {
      assertQuery(
        Trip.select { ($0.title, $0.geofence.jsonEach().count()) }
      ) {
        """
        SELECT "trips"."title", (
          SELECT count(*)
          FROM json_each("trips"."geofence")
        )
        FROM "trips"
        """
      } results: {
        """
        ┌────────────┬───┐
        │ "Northern" │ 2 │
        │ "Mixed"    │ 2 │
        │ "Empty"    │ 0 │
        └────────────┴───┘
        """
      }
    }

    @Test func aggregateOfElements() {
      assertQuery(
        Trip.select { ($0.title, $0.geofence.jsonEach().select { $0.value.jsonExtract(\.latitude).max() }) }
      ) {
        """
        SELECT "trips"."title", (
          SELECT max(json_extract("json_each"."value", '$."latitude"'))
          FROM json_each("trips"."geofence")
        )
        FROM "trips"
        """
      } results: {
        """
        ┌────────────┬──────┐
        │ "Northern" │ 51.5 │
        │ "Mixed"    │ 40.7 │
        │ "Empty"    │ nil  │
        └────────────┴──────┘
        """
      }
    }

    @Test func orderAndLimit() {
      assertQuery(
        Trip
          .where { $0.geofence.jsonArrayLength() > 0 }
          .select {
            (
              $0.title,
              $0.geofence.jsonEach()
                .select { $0.value.jsonExtract(\.label) }
                .order { $0.value.jsonExtract(\.latitude).desc() }
                .limit(1)
            )
          }
      ) {
        """
        SELECT "trips"."title", (
          SELECT json_extract("json_each"."value", '$."label"')
          FROM json_each("trips"."geofence")
          ORDER BY json_extract("json_each"."value", '$."latitude"') DESC
          LIMIT 1
        )
        FROM "trips"
        WHERE ((json_array_length("trips"."geofence")) > (0))
        """
      } results: {
        """
        ┌────────────┬────────┐
        │ "Northern" │ "away" │
        │ "Mixed"    │ "home" │
        └────────────┴────────┘
        """
      }
    }

    @Test func keyAndValue() {
      assertQuery(
        Trip
          .where { $0.geofence.jsonArrayLength() > 0 }
          .select {
            (
              $0.title,
              $0.geofence.jsonEach()
                .where { $0.key.eq(0) }
                .select { $0.value.jsonExtract(\.label) }
            )
          }
      ) {
        """
        SELECT "trips"."title", (
          SELECT json_extract("json_each"."value", '$."label"')
          FROM json_each("trips"."geofence")
          WHERE (("json_each"."key") = (0))
        )
        FROM "trips"
        WHERE ((json_array_length("trips"."geofence")) > (0))
        """
      } results: {
        """
        ┌────────────┬────────┐
        │ "Northern" │ "home" │
        │ "Mixed"    │ "home" │
        └────────────┴────────┘
        """
      }
    }

    @Test func join() {
      assertQuery(
        Trip
          .join(Trip.columns.geofence.jsonEach()) { _, _ in true }
          .select { ($0.title, $1.value.jsonExtract(\.label)) }
      ) {
        """
        SELECT "trips"."title", json_extract("json_each"."value", '$."label"')
        FROM "trips"
        JOIN json_each("trips"."geofence") ON 1
        """
      } results: {
        """
        ┌────────────┬────────┐
        │ "Northern" │ "home" │
        │ "Northern" │ "away" │
        │ "Mixed"    │ "home" │
        │ "Mixed"    │ "away" │
        └────────────┴────────┘
        """
      }
    }

    @Test func leftJoin() {
      assertQuery(
        Trip
          .leftJoin(Trip.columns.geofence.jsonEach()) { _, _ in true }
          .select { ($0.title, $1.value.jsonExtract(\.label)) }
      ) {
        """
        SELECT "trips"."title", json_extract("json_each"."value", '$."label"')
        FROM "trips"
        LEFT JOIN json_each("trips"."geofence") ON 1
        """
      } results: {
        """
        ┌────────────┬────────┐
        │ "Northern" │ "home" │
        │ "Northern" │ "away" │
        │ "Mixed"    │ "home" │
        │ "Mixed"    │ "away" │
        │ "Empty"    │ nil    │
        └────────────┴────────┘
        """
      }
    }

    @Test func scalarElements() throws {
      try db.execute(
        TaggedItem.insert {
          TaggedItem.Draft(title: "Groceries", tags: ["home", "urgent"])
          TaggedItem.Draft(title: "Taxes", tags: ["work"])
        }
      )
      assertQuery(
        TaggedItem
          .where { $0.tags.jsonEach().where { $0.value.eq("urgent") }.exists() }
          .select(\.title)
      ) {
        """
        SELECT "taggedItems"."title"
        FROM "taggedItems"
        WHERE (EXISTS (
          SELECT "json_each"."key", "json_each"."value"
          FROM json_each("taggedItems"."tags")
          WHERE (("json_each"."value") = ('urgent'))
        ))
        """
      } results: {
        """
        ┌─────────────┐
        │ "Groceries" │
        └─────────────┘
        """
      }
    }

    @Test func scalarElementsJoin() throws {
      try db.execute(
        TaggedItem.insert { TaggedItem.Draft(title: "Groceries", tags: ["home", "urgent"]) }
      )
      assertQuery(
        TaggedItem
          .join(TaggedItem.columns.tags.jsonEach()) { _, _ in true }
          .select { ($0.title, $1.key, $1.value) }
      ) {
        """
        SELECT "taggedItems"."title", "json_each"."key", "json_each"."value"
        FROM "taggedItems"
        JOIN json_each("taggedItems"."tags") ON 1
        """
      } results: {
        """
        ┌─────────────┬───┬──────────┐
        │ "Groceries" │ 0 │ "home"   │
        │ "Groceries" │ 1 │ "urgent" │
        └─────────────┴───┴──────────┘
        """
      }
    }

    @Test func dictionaryKeys() throws {
      try db.execute(
        Product.insert {
          Product.Draft(inventory: ["SFO": Stock(onHand: 0), "JFK": Stock(onHand: 4)])
          Product.Draft(inventory: ["SFO": Stock(onHand: 7)])
        }
      )
      assertQuery(
        Product
          .where {
            $0.inventory.jsonEach()
              .where { $0.key.eq("SFO") && $0.value.jsonExtract(\.onHand).eq(0) }
              .exists()
          }
          .select(\.id)
      ) {
        """
        SELECT "products"."id"
        FROM "products"
        WHERE (EXISTS (
          SELECT "json_each"."key", "json_each"."value"
          FROM json_each("products"."inventory")
          WHERE ((("json_each"."key") = ('SFO')) AND ((json_extract("json_each"."value", '$."onHand"')) = (0)))
        ))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
      }
    }

    @Test func dictionaryKeyAndValue() throws {
      try db.execute(
        Product.insert { Product.Draft(inventory: ["JFK": Stock(onHand: 4)]) }
      )
      assertQuery(
        Product
          .join(Product.columns.inventory.jsonEach()) { _, _ in true }
          .select { ($1.key, $1.value.jsonExtract(\.onHand)) }
      ) {
        """
        SELECT "json_each"."key", json_extract("json_each"."value", '$."onHand"')
        FROM "products"
        JOIN json_each("products"."inventory") ON 1
        """
      } results: {
        """
        ┌───────┬───┐
        │ "JFK" │ 4 │
        └───────┴───┘
        """
      }
    }

    @Test func scalarDictionaryValues() throws {
      try db.execute(
        Post.insert {
          Post.Draft(reactions: ["🎉": 12], writer: Writer())
          Post.Draft(reactions: ["👍": 3], writer: Writer())
        }
      )
      assertQuery(Post.where { $0.reactions.jsonEach().where { $0.value > 10 }.exists() }.select(\.id)) {
        """
        SELECT "posts"."id"
        FROM "posts"
        WHERE (EXISTS (
          SELECT "json_each"."key", "json_each"."value"
          FROM json_each("posts"."reactions")
          WHERE (("json_each"."value") > (10))
        ))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
      }
    }

    @Test func scalarArrayAtPath() throws {
      try db.execute(
        Post.insert {
          Post.Draft(writer: Writer(tags: ["swift", "sql"]))
          Post.Draft(writer: Writer(tags: ["ruby"]))
        }
      )
      assertQuery(
        Post.where { $0.writer.jsonEach(\.tags).where { $0.value.eq("swift") }.exists() }.select(\.id)
      ) {
        """
        SELECT "posts"."id"
        FROM "posts"
        WHERE (EXISTS (
          SELECT "json_each"."key", "json_each"."value"
          FROM json_each("posts"."writer", '$."tags"')
          WHERE (("json_each"."value") = ('swift'))
        ))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
      }
    }

    @Test func scalarDictionaryAtPath() throws {
      try db.execute(
        Post.insert {
          Post.Draft(writer: Writer(scores: ["swift": 9]))
          Post.Draft(writer: Writer(scores: ["swift": 2]))
        }
      )
      assertQuery(
        Post
          .where {
            $0.writer.jsonEach(\.scores).where { $0.key.eq("swift") && $0.value > 5 }.exists()
          }
          .select(\.id)
      ) {
        """
        SELECT "posts"."id"
        FROM "posts"
        WHERE (EXISTS (
          SELECT "json_each"."key", "json_each"."value"
          FROM json_each("posts"."writer", '$."scores"')
          WHERE ((("json_each"."key") = ('swift')) AND (("json_each"."value") > (5)))
        ))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
      }
    }

    @Test func decodesKeyAndValueRow() {
      assertQuery(
        Trip
          .where { $0.title.eq("Northern") }
          .join(Trip.columns.geofence.jsonEach()) { _, _ in true }
          .select { $1 }
      ) {
        """
        SELECT "json_each"."key", "json_each"."value"
        FROM "trips"
        JOIN json_each("trips"."geofence") ON 1
        WHERE (("trips"."title") = ('Northern'))
        """
      } results: {
        """
        ┌───────────────────────┐
        │ JSONEach(             │
        │   key: 0,             │
        │   value: Coordinate(  │
        │     latitude: 40.7,   │
        │     longitude: -74.0, │
        │     label: "home"     │
        │   )                   │
        │ )                     │
        ├───────────────────────┤
        │ JSONEach(             │
        │   key: 1,             │
        │   value: Coordinate(  │
        │     latitude: 51.5,   │
        │     longitude: -0.1,  │
        │     label: "away"     │
        │   )                   │
        │ )                     │
        └───────────────────────┘
        """
      }
    }

    @Test func optionalColumn() throws {
      try db.execute(
        Route.insert {
          Route.Draft(waypoints: [Coordinate(latitude: 1, longitude: 2, label: "a")])
          Route.Draft(waypoints: nil)
        }
      )
      assertQuery(
        Route.select { ($0.id, $0.waypoints.jsonEach().count()) }
      ) {
        """
        SELECT "routes"."id", (
          SELECT count(*)
          FROM json_each("routes"."waypoints")
        )
        FROM "routes"
        """
      } results: {
        """
        ┌───┬───┐
        │ 1 │ 1 │
        │ 2 │ 0 │
        └───┴───┘
        """
      }
    }

    @Test func nestedPath() throws {
      try db.execute(
        Profile.insert {
          Profile.Draft(
            author: Author(
              name: "Blob",
              links: [
                Link(homepage: "https://pointfree.co", isActive: true),
                Link(homepage: "https://example.com", isActive: false),
              ]
            )
          )
          Profile.Draft(
            author: Author(
              name: "Blob Jr.",
              links: [
                Link(homepage: "https://example.org", isActive: false)
              ]
            )
          )
        }
      )
      assertQuery(
        Profile
          .where {
            $0.author.jsonEach(\.links)
              .where { $0.value.jsonExtract(\.isActive) }
              .exists()
          }
          .select { $0.author.jsonExtract(\.name) }
      ) {
        """
        SELECT json_extract("profiles"."author", '$."name"')
        FROM "profiles"
        WHERE (EXISTS (
          SELECT "json_each"."key", "json_each"."value"
          FROM json_each("profiles"."author", '$."links"')
          WHERE (json_extract("json_each"."value", '$."isActive"'))
        ))
        """
      } results: {
        """
        ┌────────┐
        │ "Blob" │
        └────────┘
        """
      }
    }

    @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
    @Test func jsonbEachJoin() {
      assertQuery(
        Trip
          .join(Trip.columns.geofence.jsonbEach()) { _, _ in true }
          .select { ($0.title, $1.key, $1.value.jsonExtract(\.label)) }
      ) {
        """
        SELECT "trips"."title", "jsonb_each"."key", json_extract("jsonb_each"."value", '$."label"')
        FROM "trips"
        JOIN jsonb_each("trips"."geofence") ON 1
        """
      } results: {
        """
        ┌────────────┬───┬────────┐
        │ "Northern" │ 0 │ "home" │
        │ "Northern" │ 1 │ "away" │
        │ "Mixed"    │ 0 │ "home" │
        │ "Mixed"    │ 1 │ "away" │
        └────────────┴───┴────────┘
        """
      }
    }

    @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
    @Test func jsonbEachDecodesValue() {
      assertQuery(
        Trip
          .join(Trip.columns.geofence.jsonbEach()) { _, _ in true }
          .select { $1.value }
      ) {
        """
        SELECT json("jsonb_each"."value")
        FROM "trips"
        JOIN jsonb_each("trips"."geofence") ON 1
        """
      } results: {
        """
        ┌─────────────────────┐
        │ Coordinate(         │
        │   latitude: 40.7,   │
        │   longitude: -74.0, │
        │   label: "home"     │
        │ )                   │
        ├─────────────────────┤
        │ Coordinate(         │
        │   latitude: 51.5,   │
        │   longitude: -0.1,  │
        │   label: "away"     │
        │ )                   │
        ├─────────────────────┤
        │ Coordinate(         │
        │   latitude: 40.7,   │
        │   longitude: -74.0, │
        │   label: "home"     │
        │ )                   │
        ├─────────────────────┤
        │ Coordinate(         │
        │   latitude: -33.9,  │
        │   longitude: 151.2, │
        │   label: "away"     │
        │ )                   │
        └─────────────────────┘
        """
      }
    }
  }
}

@Table
private struct Trip: Codable, Equatable {
  let id: Int
  var title = ""
  @Column(as: [Coordinate].JSONRepresentation.self)
  var geofence: [Coordinate] = []
}

@Selection
private struct Coordinate: Codable, Equatable {
  var latitude = 0.0
  var longitude = 0.0
  var label = ""
}

@Table
private struct Profile: Codable, Equatable {
  let id: Int
  @Column(as: Author.JSONRepresentation.self)
  var author = Author()
}

@Selection
private struct Author: Codable, Equatable {
  var name = ""
  @Column(as: [Link].JSONRepresentation.self)
  var links: [Link] = []
}

@Selection
private struct Link: Codable, Equatable {
  var homepage = ""
  var isActive = false
}

@Table
private struct Product: Codable, Equatable {
  let id: Int
  @Column(as: [String: Stock].JSONRepresentation.self)
  var inventory: [String: Stock] = [:]
}

@Selection
private struct Stock: Codable, Equatable {
  var onHand = 0
}

@Table
private struct TaggedItem: Codable, Equatable {
  let id: Int
  var title = ""
  @Column(as: [String].JSONRepresentation.self)
  var tags: [String] = []
}

@Table
private struct Post: Codable, Equatable {
  let id: Int
  @Column(as: [String: Int].JSONRepresentation.self)
  var reactions: [String: Int] = [:]
  @Column(as: Writer.JSONRepresentation.self)
  var writer = Writer()
}

@Selection
private struct Writer: Codable, Equatable {
  var name = ""
  @Column(as: [String].JSONRepresentation.self)
  var tags: [String] = []
  @Column(as: [String: Int].JSONRepresentation.self)
  var scores: [String: Int] = [:]
}


@Table
private struct Route: Codable, Equatable {
  let id: Int
  @Column(as: [Coordinate].JSONRepresentation?.self)
  var waypoints: [Coordinate]?
}
