import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesSQLite
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @MainActor
  @Suite struct JSONBTests {
    @Dependency(\.defaultDatabase) var db

    init() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "posts" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "notes" BLOB NOT NULL,
            "optionalTags" BLOB
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "comments" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "postID" INTEGER NOT NULL,
            "moderation" BLOB
          )
          """
        )
      )
      try db.execute(
        Post.insert {
          Post.Draft(notes: ["First post", "An update"], optionalTags: ["swift"])
        }
      )
      try db.execute(
        Comment.insert {
          Comment.Draft(postID: 1, moderation: ["approved"])
        }
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "tracks" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "track_name" TEXT NOT NULL,
            "track_tags" BLOB NOT NULL
          )
          """
        )
      )
      try db.execute(
        Track.insert {
          Track.Draft(trackName: "Blob's Blues", trackTags: ["blues", "rnb"])
        }
      )
    }

    @Test func insertReturning() {
      assertQuery(
        Post.insert {
          Post.Draft(notes: ["Hello"])
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "posts"
        ("id", "notes", "optionalTags")
        VALUES
        (NULL, jsonb('[
          "Hello"
        ]'), NULL)
        RETURNING "id", json("notes"), json("optionalTags")
        """
      } results: {
        """
        ┌─────────────────────┐
        │ Post(               │
        │   id: 2,            │
        │   notes: [          │
        │     [0]: "Hello"    │
        │   ],                │
        │   optionalTags: nil │
        │ )                   │
        └─────────────────────┘
        """
      }
    }

    @Test func selectAll() {
      assertQuery(
        Post.all
      ) {
        """
        SELECT "posts"."id", json("posts"."notes"), json("posts"."optionalTags")
        FROM "posts"
        """
      } results: {
        """
        ┌────────────────────────┐
        │ Post(                  │
        │   id: 1,               │
        │   notes: [             │
        │     [0]: "First post", │
        │     [1]: "An update"   │
        │   ],                   │
        │   optionalTags: [      │
        │     [0]: "swift"       │
        │   ]                    │
        │ )                      │
        └────────────────────────┘
        """
      }
    }

    @Test func selectColumn() {
      assertQuery(
        Post.select(\.notes)
      ) {
        """
        SELECT json("posts"."notes")
        FROM "posts"
        """
      } results: {
        """
        ┌──────────────────────┐
        │ [                    │
        │   [0]: "First post", │
        │   [1]: "An update"   │
        │ ]                    │
        └──────────────────────┘
        """
      }
    }

    @Test func whereClause() {
      assertQuery(
        Post
          .where { $0.notes.eq(#bind(["First post", "An update"])) }
          .select(\.id)
      ) {
        """
        SELECT "posts"."id"
        FROM "posts"
        WHERE (("posts"."notes") = (jsonb('[
          "First post",
          "An update"
        ]')))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
      }
    }

    @Test func updateReturning() {
      assertQuery(
        Post
          .update { $0.notes = #bind(["Edited"]) }
          .returning(\.notes)
      ) {
        """
        UPDATE "posts"
        SET "notes" = jsonb('[
          "Edited"
        ]')
        RETURNING json("notes")
        """
      } results: {
        """
        ┌─────────────────┐
        │ [               │
        │   [0]: "Edited" │
        │ ]               │
        └─────────────────┘
        """
      }
    }

    @Test func deleteReturning() {
      assertQuery(
        Post
          .delete()
          .returning { ($0.notes, $0.optionalTags) }
      ) {
        """
        DELETE FROM "posts"
        RETURNING json("notes"), json("optionalTags")
        """
      } results: {
        """
        ┌──────────────────────┬────────────────┐
        │ [                    │ [              │
        │   [0]: "First post", │   [0]: "swift" │
        │   [1]: "An update"   │ ]              │
        │ ]                    │                │
        └──────────────────────┴────────────────┘
        """
      }
    }

    @Test func jsonArrayLengthInSelect() {
      assertQuery(
        Post.select { $0.notes.jsonArrayLength() }
      ) {
        """
        SELECT json_array_length(json("posts"."notes"))
        FROM "posts"
        """
      } results: {
        """
        ┌───┐
        │ 2 │
        └───┘
        """
      }
    }

    @Test func jsonArrayLengthInWhere() {
      assertQuery(
        Post
          .where { $0.notes.jsonArrayLength().gt(1) }
          .select(\.id)
      ) {
        """
        SELECT "posts"."id"
        FROM "posts"
        WHERE ((json_array_length("posts"."notes")) > (1))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
      }
    }

    @Test func jsonPatch() {
      assertQuery(
        Post
          .update { $0.notes = $0.notes.jsonbPatch(#bind(["Replaced"])) }
          .returning(\.notes)
      ) {
        """
        UPDATE "posts"
        SET "notes" = jsonb_patch("posts"."notes", jsonb('[
          "Replaced"
        ]'))
        RETURNING json("notes")
        """
      } results: {
        """
        ┌───────────────────┐
        │ [                 │
        │   [0]: "Replaced" │
        │ ]                 │
        └───────────────────┘
        """
      }
    }

    @Test func jsonGroupArray() {
      assertQuery(
        Post.select { $0.jsonGroupArray() }
      ) {
        """
        SELECT json_group_array(json_object('id', json_quote("posts"."id"), 'notes', json("posts"."notes"), 'optionalTags', json("posts"."optionalTags")))
        FROM "posts"
        """
      } results: {
        """
        ┌──────────────────────────┐
        │ [                        │
        │   [0]: Post(             │
        │     id: 1,               │
        │     notes: [             │
        │       [0]: "First post", │
        │       [1]: "An update"   │
        │     ],                   │
        │     optionalTags: [      │
        │       [0]: "swift"       │
        │     ]                    │
        │   )                      │
        │ ]                        │
        └──────────────────────────┘
        """
      }
    }

    @Test func jsonGroupArrayOfColumns() {
      assertQuery(
        Post.select { ($0.notes.jsonGroupArray(), $0.optionalTags.jsonGroupArray()) }
      ) {
        """
        SELECT json_group_array(json("posts"."notes")), json_group_array(json("posts"."optionalTags"))
        FROM "posts"
        """
      } results: {
        """
        ┌────────────────────────┬──────────────────┐
        │ [                      │ [                │
        │   [0]: [               │   [0]: [         │
        │     [0]: "First post", │     [0]: "swift" │
        │     [1]: "An update"   │   ]              │
        │   ]                    │ ]                │
        │ ]                      │                  │
        └────────────────────────┴──────────────────┘
        """
      }
    }

    @Test func jsonGroupArrayWithRenamedColumns() {
      assertQuery(
        Track.select { $0.jsonGroupArray() }
      ) {
        """
        SELECT json_group_array(json_object('id', json_quote("tracks"."id"), 'track_name', json_quote("tracks"."track_name"), 'track_tags', json("tracks"."track_tags")))
        FROM "tracks"
        """
      } results: {
        #"""
        ┌─────────────────────────────────┐
        │ [                               │
        │   [0]: Track(                   │
        │     id: 1,                      │
        │     trackName: "Blob\'s Blues", │
        │     trackTags: [                │
        │       [0]: "blues",             │
        │       [1]: "rnb"                │
        │     ]                           │
        │   )                             │
        │ ]                               │
        └─────────────────────────────────┘
        """#
      }
    }

    @Test func join() {
      assertQuery(
        Post
          .join(Comment.all) { $0.id.eq($1.postID) }
      ) {
        """
        SELECT "posts"."id", json("posts"."notes"), json("posts"."optionalTags"), "comments"."id", "comments"."postID", json("comments"."moderation")
        FROM "posts"
        JOIN "comments" ON ("posts"."id") = ("comments"."postID")
        """
      } results: {
        """
        ┌────────────────────────┬─────────────────────┐
        │ Post(                  │ Comment(            │
        │   id: 1,               │   id: 1,            │
        │   notes: [             │   postID: 1,        │
        │     [0]: "First post", │   moderation: [     │
        │     [1]: "An update"   │     [0]: "approved" │
        │   ],                   │   ]                 │
        │   optionalTags: [      │ )                   │
        │     [0]: "swift"       │                     │
        │   ]                    │                     │
        │ )                      │                     │
        └────────────────────────┴─────────────────────┘
        """
      }
    }
  }
}

@Table
private struct Post: Codable, Equatable {
  let id: Int
  @Column(as: [String].JSONBRepresentation.self)
  var notes: [String] = []
  @Column(as: [String].JSONBRepresentation?.self)
  var optionalTags: [String]?
}

@Table
private struct Comment: Codable, Equatable {
  let id: Int
  var postID: Int
  @Column(as: [String].JSONBRepresentation?.self)
  var moderation: [String]?
}

@Table
private struct Track: Codable, Equatable {
  let id: Int
  @Column("track_name")
  var trackName = ""
  @Column("track_tags", as: [String].JSONBRepresentation.self)
  var trackTags: [String] = []
}
