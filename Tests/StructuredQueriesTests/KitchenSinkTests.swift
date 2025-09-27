import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @MainActor
  @Suite struct KitchenSinkTests {
    @Dependency(\.defaultDatabase) var db

    init() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "kitchens" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "kitchenSinks" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "kitchenID" INTEGER,
            "bool" INTEGER NOT NULL DEFAULT 0,
            "optionalBool" INTEGER,
            "string" TEXT NOT NULL DEFAULT '',
            "optionalString" TEXT,
            "int" INTEGER NOT NULL DEFAULT 0,
            "optionalInt" INTEGER,
            "double" REAL NOT NULL DEFAULT 0.0,
            "optionalDouble" REAL,
            "rawRepresentable" TEXT NOT NULL DEFAULT 'green',
            "optionalRawRepresentable" TEXT,
            "iso8601Date" TEXT NOT NULL DEFAULT '2018-01-29 00:08:00',
            "optionalISO8601Date" TEXT,
            "unixTimeDate" INT NOT NULL DEFAULT 1234567890,
            "optionalUnixTimeDate" INT,
            "julianDayDate" REAL NOT NULL DEFAULT 2456789.0,
            "optionalJulianDayDate" REAL,
            "jsonArray" TEXT NOT NULL DEFAULT '[]',
            "optionalJSONArray" TEXT,
            "jsonArrayOfDates" TEXT NOT NULL DEFAULT '[]'
          )
          """
        )
      )
      try db.execute(
        Kitchen.insert {
          Kitchen(
            id: 1
          )
        }
      )
      try db.execute(
        KitchenSink.insert()
      )
      try db.execute(
        KitchenSink.insert {
          [
            KitchenSink(
              id: 2,
              kitchenID: 1,
              bool: true,
              string: "Blob",
              int: 42,
              double: 17.29,
              rawRepresentable: .red,
              iso8601Date: Date(timeIntervalSinceReferenceDate: 24 * 60 * 60),
              unixTimeDate: Date(timeIntervalSince1970: 24 * 60 * 60),
              julianDayDate: Date(timeIntervalSinceReferenceDate: 7 * 24 * 60 * 60),
              jsonArray: ["Hello", "world"],
              jsonArrayOfDates: [Date(timeIntervalSinceReferenceDate: 1_234_567_890)]
            ),
            KitchenSink(
              id: 3,
              kitchenID: 1,
              bool: false,
              optionalBool: true,
              string: "Blob Jr",
              optionalString: "Blob Sr",
              int: 24,
              optionalInt: 48,
              double: 29.17,
              optionalDouble: 80.08,
              rawRepresentable: .green,
              optionalRawRepresentable: .blue,
              iso8601Date: Date(timeIntervalSinceReferenceDate: 24 * 60 * 60),
              optionalISO8601Date: Date(timeIntervalSinceReferenceDate: 2 * 24 * 60 * 60),
              unixTimeDate: Date(timeIntervalSince1970: 24 * 60 * 60),
              optionalUnixTimeDate: Date(timeIntervalSince1970: 2 * 24 * 60 * 60),
              julianDayDate: Date(timeIntervalSinceReferenceDate: 7 * 24 * 60 * 60),
              optionalJulianDayDate: Date(timeIntervalSinceReferenceDate: 2 * 7 * 24 * 60 * 60),
              jsonArray: ["Hello", "world"],
              optionalJSONArray: ["Goodnight", "moon"],
              jsonArrayOfDates: [Date(timeIntervalSinceReferenceDate: 1_234_567_890)]
            ),
          ]
        }
      )
    }

    @Test func basics() {
      assertQuery(
        KitchenSink.all
      ) {
        """
        SELECT "kitchenSinks"."id", "kitchenSinks"."kitchenID", "kitchenSinks"."bool", "kitchenSinks"."optionalBool", "kitchenSinks"."string", "kitchenSinks"."optionalString", "kitchenSinks"."int", "kitchenSinks"."optionalInt", "kitchenSinks"."double", "kitchenSinks"."optionalDouble", "kitchenSinks"."rawRepresentable", "kitchenSinks"."optionalRawRepresentable", "kitchenSinks"."iso8601Date", "kitchenSinks"."optionalISO8601Date", "kitchenSinks"."unixTimeDate", "kitchenSinks"."optionalUnixTimeDate", "kitchenSinks"."julianDayDate", "kitchenSinks"."optionalJulianDayDate", "kitchenSinks"."jsonArray", "kitchenSinks"."optionalJSONArray", "kitchenSinks"."jsonArrayOfDates"
        FROM "kitchenSinks"
        """
      } results: {
        """
        ┌──────────────────────────────────────────────────────────┐
        │ KitchenSink(                                             │
        │   id: 1,                                                 │
        │   kitchenID: nil,                                        │
        │   bool: false,                                           │
        │   optionalBool: nil,                                     │
        │   string: "",                                            │
        │   optionalString: nil,                                   │
        │   int: 0,                                                │
        │   optionalInt: nil,                                      │
        │   double: 0.0,                                           │
        │   optionalDouble: nil,                                   │
        │   rawRepresentable: .green,                              │
        │   optionalRawRepresentable: nil,                         │
        │   iso8601Date: Date(2018-01-29T00:08:00.000Z),           │
        │   optionalISO8601Date: nil,                              │
        │   unixTimeDate: Date(2009-02-13T23:31:30.000Z),          │
        │   optionalUnixTimeDate: nil,                             │
        │   julianDayDate: Date(2014-05-11T12:00:00.000Z),         │
        │   optionalJulianDayDate: nil,                            │
        │   jsonArray: [],                                         │
        │   optionalJSONArray: nil,                                │
        │   jsonArrayOfDates: []                                   │
        │ )                                                        │
        ├──────────────────────────────────────────────────────────┤
        │ KitchenSink(                                             │
        │   id: 2,                                                 │
        │   kitchenID: 1,                                          │
        │   bool: true,                                            │
        │   optionalBool: nil,                                     │
        │   string: "Blob",                                        │
        │   optionalString: nil,                                   │
        │   int: 42,                                               │
        │   optionalInt: nil,                                      │
        │   double: 17.29,                                         │
        │   optionalDouble: nil,                                   │
        │   rawRepresentable: .red,                                │
        │   optionalRawRepresentable: nil,                         │
        │   iso8601Date: Date(2001-01-02T00:00:00.000Z),           │
        │   optionalISO8601Date: nil,                              │
        │   unixTimeDate: Date(1970-01-02T00:00:00.000Z),          │
        │   optionalUnixTimeDate: nil,                             │
        │   julianDayDate: Date(2001-01-08T00:00:00.000Z),         │
        │   optionalJulianDayDate: nil,                            │
        │   jsonArray: [                                           │
        │     [0]: "Hello",                                        │
        │     [1]: "world"                                         │
        │   ],                                                     │
        │   optionalJSONArray: nil,                                │
        │   jsonArrayOfDates: [                                    │
        │     [0]: Date(2040-02-14T23:31:30.000Z)                  │
        │   ]                                                      │
        │ )                                                        │
        ├──────────────────────────────────────────────────────────┤
        │ KitchenSink(                                             │
        │   id: 3,                                                 │
        │   kitchenID: 1,                                          │
        │   bool: false,                                           │
        │   optionalBool: true,                                    │
        │   string: "Blob Jr",                                     │
        │   optionalString: "Blob Sr",                             │
        │   int: 24,                                               │
        │   optionalInt: 48,                                       │
        │   double: 29.17,                                         │
        │   optionalDouble: 80.08,                                 │
        │   rawRepresentable: .green,                              │
        │   optionalRawRepresentable: .blue,                       │
        │   iso8601Date: Date(2001-01-02T00:00:00.000Z),           │
        │   optionalISO8601Date: Date(2001-01-03T00:00:00.000Z),   │
        │   unixTimeDate: Date(1970-01-02T00:00:00.000Z),          │
        │   optionalUnixTimeDate: Date(1970-01-03T00:00:00.000Z),  │
        │   julianDayDate: Date(2001-01-08T00:00:00.000Z),         │
        │   optionalJulianDayDate: Date(2001-01-15T00:00:00.000Z), │
        │   jsonArray: [                                           │
        │     [0]: "Hello",                                        │
        │     [1]: "world"                                         │
        │   ],                                                     │
        │   optionalJSONArray: [                                   │
        │     [0]: "Goodnight",                                    │
        │     [1]: "moon"                                          │
        │   ],                                                     │
        │   jsonArrayOfDates: [                                    │
        │     [0]: Date(2040-02-14T23:31:30.000Z)                  │
        │   ]                                                      │
        │ )                                                        │
        └──────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonGroupArray() {
      assertQuery(
        Kitchen
          .fullJoin(KitchenSink.all) { $0.id.is($1.kitchenID) }
          .select { ($0, $1.jsonGroupArray()) }
      ) {
        """
        SELECT "kitchens"."id", json_group_array(CASE WHEN ("kitchenSinks"."rowid") IS NOT (NULL) THEN json_object('id', json_quote("kitchenSinks"."id"), 'kitchenID', json_quote("kitchenSinks"."kitchenID"), 'bool', json(CASE "kitchenSinks"."bool" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'optionalBool', json(CASE "kitchenSinks"."optionalBool" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'string', json_quote("kitchenSinks"."string"), 'optionalString', json_quote("kitchenSinks"."optionalString"), 'int', json_quote("kitchenSinks"."int"), 'optionalInt', json_quote("kitchenSinks"."optionalInt"), 'double', json_quote("kitchenSinks"."double"), 'optionalDouble', json_quote("kitchenSinks"."optionalDouble"), 'rawRepresentable', json_quote("kitchenSinks"."rawRepresentable"), 'optionalRawRepresentable', json_quote("kitchenSinks"."optionalRawRepresentable"), 'iso8601Date', json_quote("kitchenSinks"."iso8601Date"), 'optionalISO8601Date', json_quote("kitchenSinks"."optionalISO8601Date"), 'unixTimeDate', datetime("kitchenSinks"."unixTimeDate", 'unixepoch'), 'optionalUnixTimeDate', datetime("kitchenSinks"."optionalUnixTimeDate", 'unixepoch'), 'julianDayDate', datetime("kitchenSinks"."julianDayDate", 'julianday'), 'optionalJulianDayDate', datetime("kitchenSinks"."optionalJulianDayDate", 'julianday'), 'jsonArray', json("kitchenSinks"."jsonArray"), 'optionalJSONArray', json("kitchenSinks"."optionalJSONArray"), 'jsonArrayOfDates', json("kitchenSinks"."jsonArrayOfDates")) END) FILTER (WHERE ("kitchenSinks"."id") IS NOT (NULL))
        FROM "kitchens"
        FULL JOIN "kitchenSinks" ON ("kitchens"."id") IS ("kitchenSinks"."kitchenID")
        """
      } results: {
        """
        ┌────────────────┬────────────────────────────────────────────────────────────┐
        │ Kitchen(id: 1) │ [                                                          │
        │                │   [0]: KitchenSink(                                        │
        │                │     id: 2,                                                 │
        │                │     kitchenID: 1,                                          │
        │                │     bool: true,                                            │
        │                │     optionalBool: nil,                                     │
        │                │     string: "Blob",                                        │
        │                │     optionalString: nil,                                   │
        │                │     int: 42,                                               │
        │                │     optionalInt: nil,                                      │
        │                │     double: 17.29,                                         │
        │                │     optionalDouble: nil,                                   │
        │                │     rawRepresentable: .red,                                │
        │                │     optionalRawRepresentable: nil,                         │
        │                │     iso8601Date: Date(2001-01-02T00:00:00.000Z),           │
        │                │     optionalISO8601Date: nil,                              │
        │                │     unixTimeDate: Date(1970-01-02T00:00:00.000Z),          │
        │                │     optionalUnixTimeDate: nil,                             │
        │                │     julianDayDate: Date(2001-01-08T00:00:00.000Z),         │
        │                │     optionalJulianDayDate: nil,                            │
        │                │     jsonArray: [                                           │
        │                │       [0]: "Hello",                                        │
        │                │       [1]: "world"                                         │
        │                │     ],                                                     │
        │                │     optionalJSONArray: nil,                                │
        │                │     jsonArrayOfDates: [                                    │
        │                │       [0]: Date(2040-02-14T23:31:30.000Z)                  │
        │                │     ]                                                      │
        │                │   ),                                                       │
        │                │   [1]: KitchenSink(                                        │
        │                │     id: 3,                                                 │
        │                │     kitchenID: 1,                                          │
        │                │     bool: false,                                           │
        │                │     optionalBool: true,                                    │
        │                │     string: "Blob Jr",                                     │
        │                │     optionalString: "Blob Sr",                             │
        │                │     int: 24,                                               │
        │                │     optionalInt: 48,                                       │
        │                │     double: 29.17,                                         │
        │                │     optionalDouble: 80.08,                                 │
        │                │     rawRepresentable: .green,                              │
        │                │     optionalRawRepresentable: .blue,                       │
        │                │     iso8601Date: Date(2001-01-02T00:00:00.000Z),           │
        │                │     optionalISO8601Date: Date(2001-01-03T00:00:00.000Z),   │
        │                │     unixTimeDate: Date(1970-01-02T00:00:00.000Z),          │
        │                │     optionalUnixTimeDate: Date(1970-01-03T00:00:00.000Z),  │
        │                │     julianDayDate: Date(2001-01-08T00:00:00.000Z),         │
        │                │     optionalJulianDayDate: Date(2001-01-15T00:00:00.000Z), │
        │                │     jsonArray: [                                           │
        │                │       [0]: "Hello",                                        │
        │                │       [1]: "world"                                         │
        │                │     ],                                                     │
        │                │     optionalJSONArray: [                                   │
        │                │       [0]: "Goodnight",                                    │
        │                │       [1]: "moon"                                          │
        │                │     ],                                                     │
        │                │     jsonArrayOfDates: [                                    │
        │                │       [0]: Date(2040-02-14T23:31:30.000Z)                  │
        │                │     ]                                                      │
        │                │   ),                                                       │
        │                │   [2]: KitchenSink(                                        │
        │                │     id: 1,                                                 │
        │                │     kitchenID: nil,                                        │
        │                │     bool: false,                                           │
        │                │     optionalBool: nil,                                     │
        │                │     string: "",                                            │
        │                │     optionalString: nil,                                   │
        │                │     int: 0,                                                │
        │                │     optionalInt: nil,                                      │
        │                │     double: 0.0,                                           │
        │                │     optionalDouble: nil,                                   │
        │                │     rawRepresentable: .green,                              │
        │                │     optionalRawRepresentable: nil,                         │
        │                │     iso8601Date: Date(2018-01-29T00:08:00.000Z),           │
        │                │     optionalISO8601Date: nil,                              │
        │                │     unixTimeDate: Date(2009-02-13T23:31:30.000Z),          │
        │                │     optionalUnixTimeDate: nil,                             │
        │                │     julianDayDate: Date(2014-05-11T12:00:00.000Z),         │
        │                │     optionalJulianDayDate: nil,                            │
        │                │     jsonArray: [],                                         │
        │                │     optionalJSONArray: nil,                                │
        │                │     jsonArrayOfDates: []                                   │
        │                │   )                                                        │
        │                │ ]                                                          │
        └────────────────┴────────────────────────────────────────────────────────────┘
        """
      }
    }
  }
}

@Table
private struct Kitchen {
  let id: Int
}

private enum Color: String, Codable, QueryBindable {
  case red, green, blue
}

@Table
private struct KitchenSink: Codable {
  let id: Int
  var kitchenID: Int?
  var bool: Bool
  var optionalBool: Bool?
  var string: String
  var optionalString: String?
  var int: Int
  var optionalInt: Int?
  var double: Double
  var optionalDouble: Double?
  var rawRepresentable: Color
  var optionalRawRepresentable: Color?
  var iso8601Date: Date
  var optionalISO8601Date: Date?
  @Column(as: Date.UnixTimeRepresentation.self)
  var unixTimeDate: Date
  @Column(as: Date.UnixTimeRepresentation?.self)
  var optionalUnixTimeDate: Date?
  @Column(as: Date.JulianDayRepresentation.self)
  var julianDayDate: Date
  @Column(as: Date.JulianDayRepresentation?.self)
  var optionalJulianDayDate: Date?
  @Column(as: [String].JSONRepresentation.self)
  var jsonArray: [String]
  @Column(as: [String].JSONRepresentation?.self)
  var optionalJSONArray: [String]?
  @Column(as: [Date].JSONRepresentation.self)
  var jsonArrayOfDates: [Date]
}
