import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLiteCore
import Testing
import _StructuredQueriesSQLite

#if compiler(>=6.2)

  extension SnapshotTests {
    @MainActor
    @Suite struct JSONBTests {
      @Dependency(\.defaultDatabase) var db

      init() throws {
        try db.execute(
          """
          CREATE TABLE IF NOT EXISTS "documents" (
            "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "title" TEXT NOT NULL DEFAULT '',
            "tags" BLOB NOT NULL DEFAULT (jsonb('[]')),
            "metadata" BLOB
          )
          """
        )
        if #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) {
          try db.execute(
            Document.insert {
              Document(
                id: 1,
                title: "Getting started",
                tags: ["welcome", "todo"],
                metadata: Metadata(author: "Blob", version: 1)
              )
            }
          )
        } else {
          struct JSONBRequiresOS26: Error {}
          throw JSONBRequiresOS26()
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func roundTrip() {
        assertQuery(Document.all) {
          """
          SELECT "documents"."id", "documents"."title", "documents"."tags", "documents"."metadata"
          FROM "documents"
          """
        } results: {
          """
          ┌─────────────────────────────┐
          │ Document(                   │
          │   id: 1,                    │
          │   title: "Getting started", │
          │   tags: [                   │
          │     [0]: "welcome",         │
          │     [1]: "todo"             │
          │   ],                        │
          │   metadata: Metadata(       │
          │     author: "Blob",         │
          │     version: 1              │
          │   )                         │
          │ )                           │
          └─────────────────────────────┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func insertReturning() {
        assertQuery(
          Document.insert {
            Document(id: 2, title: "Vacation", tags: ["travel"], metadata: nil)
          }
          .returning(\.self)
        ) {
          """
          INSERT INTO "documents"
          ("id", "title", "tags", "metadata")
          VALUES
          (2, 'Vacation', jsonb('[
            "travel"
          ]'), NULL)
          RETURNING "id", "title", "tags", "metadata"
          """
        } results: {
          """
          ┌──────────────────────┐
          │ Document(            │
          │   id: 2,             │
          │   title: "Vacation", │
          │   tags: [            │
          │     [0]: "travel"    │
          │   ],                 │
          │   metadata: nil      │
          │ )                    │
          └──────────────────────┘
          """
        }
      }
      
      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func whereEquality() {
        assertQuery(
          Document
            .where { $0.tags.eq(#bind(["welcome", "todo"])) }
            .select { $0.title }
        ) {
          """
          SELECT "documents"."title"
          FROM "documents"
          WHERE (("documents"."tags") = (jsonb('[
            "welcome",
            "todo"
          ]')))
          """
        } results: {
          """
          ┌───────────────────┐
          │ "Getting started" │
          └───────────────────┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func update() {
        assertQuery(
          Document
            .update { $0.metadata = #bind(Metadata(author: "Blob Jr", version: 2)) }
            .returning(\.self)
        ) {
          """
          UPDATE "documents"
          SET "metadata" = jsonb('{
            "author" : "Blob Jr",
            "version" : 2
          }')
          RETURNING "id", "title", "tags", "metadata"
          """
        } results: {
          """
          ┌─────────────────────────────┐
          │ Document(                   │
          │   id: 1,                    │
          │   title: "Getting started", │
          │   tags: [                   │
          │     [0]: "welcome",         │
          │     [1]: "todo"             │
          │   ],                        │
          │   metadata: Metadata(       │
          │     author: "Blob Jr",      │
          │     version: 2              │
          │   )                         │
          │ )                           │
          └─────────────────────────────┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func json5Decoding() {
        assertQuery(
          #sql("SELECT jsonb('[0x1A, .5, 2., 1e2]')", as: [Double].JSONBRepresentation.self)
        ) {
          """
          SELECT jsonb('[0x1A, .5, 2., 1e2]')
          """
        } results: {
          """
          ┌──────────────┐
          │ [            │
          │   [0]: 26.0, │
          │   [1]: 0.5,  │
          │   [2]: 2.0,  │
          │   [3]: 100.0 │
          │ ]            │
          └──────────────┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func textRawDecoding() {
        assertQuery(
          #sql(
            """
            SELECT jsonb_set(
              jsonb('{"author":"Blob","version":9}'), '$.author', 'it''s "Blob"'
            )
            """,
            as: Metadata.JSONBRepresentation.self
          )
        ) {
          """
          SELECT jsonb_set(
            jsonb('{"author":"Blob","version":9}'), '$.author', 'it''s "Blob"'
          )
          """
        } results: {
          """
          ┌────────────────────────────┐
          │ Metadata(                  │
          │   author: #"it's "Blob""#, │
          │   version: 9               │
          │ )                          │
          └────────────────────────────┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func legacyTextFallback() {
        assertQuery(
          #sql(#"SELECT '["legacy"]'"#, as: [String].JSONBRepresentation.self)
        ) {
          """
          SELECT '["legacy"]'
          """
        } results: {
          """
          ┌─────────────────┐
          │ [               │
          │   [0]: "legacy" │
          │ ]               │
          └─────────────────┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func jsonArrayLength() {
        assertQuery(
          Document.select { $0.tags.jsonArrayLength() }
        ) {
          """
          SELECT json_array_length("documents"."tags")
          FROM "documents"
          """
        } results: {
          """
          ┌───┐
          │ 2 │
          └───┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func jsonbPatch() {
        assertQuery(
          Values(
            #bind(Metadata(author: "Blob", version: 1), as: Metadata.JSONBRepresentation.self)
              .jsonbPatch(#bind(Metadata(author: "Blob Jr", version: 2)))
          )
        ) {
          """
          SELECT jsonb_patch(jsonb('{
            "author" : "Blob",
            "version" : 1
          }'), jsonb('{
            "author" : "Blob Jr",
            "version" : 2
          }'))
          """
        } results: {
          """
          ┌──────────────────────┐
          │ Metadata(            │
          │   author: "Blob Jr", │
          │   version: 2         │
          │ )                    │
          └──────────────────────┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func externallyWrittenBlob() throws {
        try db.execute(
          """
          INSERT INTO "documents" ("id", "title", "tags", "metadata") VALUES
          (2, 'Imported', jsonb('["external"]'), jsonb('{"author":"Import Bot","version":9}'))
          """
        )
        assertQuery(Document.find(2)) {
          """
          SELECT "documents"."id", "documents"."title", "documents"."tags", "documents"."metadata"
          FROM "documents"
          WHERE (("documents"."id") IN ((2)))
          """
        } results: {
          """
          ┌───────────────────────────┐
          │ Document(                 │
          │   id: 2,                  │
          │   title: "Imported",      │
          │   tags: [                 │
          │     [0]: "external"       │
          │   ],                      │
          │   metadata: Metadata(     │
          │     author: "Import Bot", │
          │     version: 9            │
          │   )                       │
          │ )                         │
          └───────────────────────────┘
          """
        }
      }

      @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
      @Test func jsonGroupArray() {
        assertQuery(
          Document.select { $0.jsonGroupArray() }
        ) {
          """
          SELECT json_group_array(json_object('id', json_quote("documents"."id"), 'title', json_quote("documents"."title"), 'tags', json("documents"."tags"), 'metadata', json("documents"."metadata")))
          FROM "documents"
          """
        } results: {
          """
          ┌───────────────────────────────┐
          │ [                             │
          │   [0]: Document(              │
          │     id: 1,                    │
          │     title: "Getting started", │
          │     tags: [                   │
          │       [0]: "welcome",         │
          │       [1]: "todo"             │
          │     ],                        │
          │     metadata: Metadata(       │
          │       author: "Blob",         │
          │       version: 1              │
          │     )                         │
          │   )                           │
          │ ]                             │
          └───────────────────────────────┘
          """
        }
      }
    }
  }

  @Suite struct JSONBDecoderTests {
    init() throws {
      guard #available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *) else {
        struct JSONBRequiresOS26: Error {}
        throw JSONBRequiresOS26()
      }
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    @Test func primitives() throws {
      #expect(try transcodedJSON(from: [0x00]) == "null")
      #expect(try transcodedJSON(from: [0x01]) == "true")
      #expect(try transcodedJSON(from: [0x02]) == "false")
      #expect(try transcodedJSON(from: element(3, "123")) == "123")
      #expect(try transcodedJSON(from: element(5, "2.5")) == "2.5")
      #expect(try transcodedJSON(from: element(7, "hello")) == #""hello""#)
      #expect(try transcodedJSON(from: [0x0b]) == "[]")
      #expect(try transcodedJSON(from: [0x0c]) == "{}")
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    @Test func int5() throws {
      #expect(try transcodedJSON(from: element(4, "0x1A")) == "26")
      #expect(try transcodedJSON(from: element(4, "-0xff")) == "-255")
      #expect(try transcodedJSON(from: element(4, "+12")) == "12")
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    @Test func float5() throws {
      #expect(try transcodedJSON(from: element(6, ".5")) == "0.5")
      #expect(try transcodedJSON(from: element(6, "5.")) == "5.0")
      #expect(try transcodedJSON(from: element(6, "-.5e2")) == "-0.5e2")
      #expect(try transcodedJSON(from: element(6, "Infinity")) == "9e999")
      #expect(try transcodedJSON(from: element(6, "-Infinity")) == "-9e999")
      #expect(try transcodedJSON(from: element(6, "NaN")) == "null")
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    @Test func text5() throws {
      #expect(try transcodedJSON(from: element(9, #"\x41\'\v\0"#)) == ##""\u0041'\u000b\u0000""##)
      #expect(try transcodedJSON(from: element(9, #"\n\tA"#)) == #""\n\tA""#)
      #expect(try transcodedJSON(from: element(9, "a\\\nb")) == #""ab""#)
      #expect(try transcodedJSON(from: element(9, "a\\\r\nb")) == #""ab""#)
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    @Test func textRaw() throws {
      #expect(
        try transcodedJSON(from: element(10, "it's a \"test\"\n\u{01}"))
          == ##""it's a \"test\"\n\u0001""##
      )
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    @Test func multiByteSizeHeaders() throws {
      let text = String(repeating: "a", count: 300)
      #expect(try transcodedJSON(from: [0xd7, 0x01, 0x2c] + Array(text.utf8)) == "\"\(text)\"")
      #expect(
        try transcodedJSON(from: [0xe7, 0x00, 0x00, 0x01, 0x2c] + Array(text.utf8)) == "\"\(text)\""
      )
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    @Test func containers() throws {
      #expect(try transcodedJSON(from: element(11, "\u{13}1\u{13}2")) == "[1,2]")
      #expect(try transcodedJSON(from: element(12, "\u{17}a\u{13}1")) == #"{"a":1}"#)
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    @Test func malformedBlobs() {
      #expect(throws: JSONB.DecodingError.self) { try transcodedJSON(from: []) }
      #expect(throws: JSONB.DecodingError.self) { try transcodedJSON(from: [0x0d]) }
      #expect(throws: JSONB.DecodingError.self) { try transcodedJSON(from: [0x13]) }
      #expect(throws: JSONB.DecodingError.self) { try transcodedJSON(from: [0x00, 0x00]) }
      #expect(throws: JSONB.DecodingError.self) { try transcodedJSON(from: [0xc7]) }
      #expect(throws: JSONB.DecodingError.self) {
        // An object with a non-text key.
        try transcodedJSON(from: element(12, "\u{13}1\u{13}2"))
      }
      #expect(throws: JSONB.DecodingError.self) {
        // An object with a key and no value.
        try transcodedJSON(from: element(12, "\u{17}a"))
      }
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    private func transcodedJSON(from blob: [UInt8]) throws -> String {
      String(decoding: try JSONB.json(from: blob.span), as: UTF8.self)
    }

    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    private func element(_ type: UInt8, _ payload: String) -> [UInt8] {
      let payload = Array(payload.utf8)
      precondition(payload.count <= UInt8.max)
      return payload.count <= 11
        ? [UInt8(payload.count) << 4 | type] + payload
        : [0xc0 | type, UInt8(payload.count)] + payload
    }
  }

  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  @Table private struct Document: Codable, Equatable {
    let id: Int
    var title = ""
    @Column(as: [String].JSONBRepresentation.self)
    var tags: [String] = []
    @Column(as: Metadata?.JSONBRepresentation.self)
    var metadata: Metadata?
  }

  private struct Metadata: Codable, Equatable {
    var author = ""
    var version = 1
  }
#endif
