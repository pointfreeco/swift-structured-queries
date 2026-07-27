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
        Trip.insert {
          [
            Trip.Draft(
              title: "Northern",
              geofence: [
                Coordinate(latitude: 40.7, longitude: -74.0, label: "home"),
                Coordinate(latitude: 51.5, longitude: -0.1, label: "away"),
              ]
            ),
            Trip.Draft(
              title: "Mixed",
              geofence: [
                Coordinate(latitude: 40.7, longitude: -74.0, label: "home"),
                Coordinate(latitude: -33.9, longitude: 151.2, label: "away"),
              ]
            ),
            Trip.Draft(title: "Empty"),
          ]
        }
      )
    }

    @Test func exists() {
      assertQuery(
        Trip
          .where {
            !$0.geofence.jsonEach()
              .where { $0.latitude < 0 }
              .exists()
          }
          .select(\.title)
      ) {
        """
        SELECT "trips"."title"
        FROM "trips"
        WHERE (NOT (EXISTS (
          SELECT json_extract("json_each"."value", '$."latitude"'), json_extract("json_each"."value", '$."longitude"'), json_extract("json_each"."value", '$."label"')
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
        Trip.select { ($0.title, $0.geofence.jsonEach().select { $0.latitude.max() }) }
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
                .select(\.label)
                .order { $0.latitude.desc() }
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
          .select { ($0.title, $1.label) }
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
          .select { ($0.title, $1.label) }
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

    @Test func dictionaryKeys() throws {
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
        Product.insert {
          [
            Product.Draft(inventory: ["SFO": Stock(onHand: 0), "JFK": Stock(onHand: 4)]),
            Product.Draft(inventory: ["SFO": Stock(onHand: 7)]),
          ]
        }
      )
      assertQuery(
        Product
          .where {
            $0.inventory.jsonEach()
              .where { $0.key.eq("SFO") && $0.onHand.eq(0) }
              .exists()
          }
          .select(\.id)
      ) {
        """
        SELECT "products"."id"
        FROM "products"
        WHERE (EXISTS (
          SELECT json_extract("json_each"."value", '$."onHand"')
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
        Product.insert { Product.Draft(inventory: ["JFK": Stock(onHand: 4)]) }
      )
      assertQuery(
        Product
          .join(Product.columns.inventory.jsonEach()) { _, _ in true }
          .select { ($1.key, $1.onHand) }
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

    @Test func nestedPath() throws {
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
        Profile.insert {
          [
            Profile.Draft(
              author: Author(
                name: "Blob",
                links: [
                  Link(homepage: "https://pointfree.co", isActive: true),
                  Link(homepage: "https://example.com", isActive: false),
                ]
              )
            ),
            Profile.Draft(
              author: Author(
                name: "Blob Jr.",
                links: [
                  Link(homepage: "https://example.org", isActive: false)
                ]
              )
            ),
          ]
        }
      )
      assertQuery(
        Profile
          .where {
            $0.author.jsonEach(\.links)
              .where { $0.isActive }
              .exists()
          }
          .select { $0.author.jsonExtract(\.name) }
      ) {
        """
        SELECT json_extract("profiles"."author", '$."name"')
        FROM "profiles"
        WHERE (EXISTS (
          SELECT json_extract("json_each"."value", '$."homepage"'), json_extract("json_each"."value", '$."isActive"')
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
