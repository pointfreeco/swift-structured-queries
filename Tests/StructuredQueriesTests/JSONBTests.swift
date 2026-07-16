import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
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
      try db.execute(
        #sql(
          """
          CREATE TABLE "profiles" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "author" BLOB NOT NULL,
            "editor" BLOB
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "sessions" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "token" BLOB NOT NULL,
            "refresh" BLOB
          )
          """
        )
      )
      try db.execute(
        Session.insert {
          Session.Draft(token: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!)
        }
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "bios" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT,
            "resume" BLOB NOT NULL
          )
          """
        )
      )
      try db.execute(
        Bio.insert {
          [
            Bio.Draft(resume: Resume(author: Author(name: "Blob Sr"))),
            Bio.Draft(resume: Resume()),
          ]
        }
      )
      try db.execute(
        Profile.insert {
          Profile.Draft(
            author: Author(
              name: "Blob",
              isVerified: true,
              joinedAt: Date(timeIntervalSince1970: 60 * 60 * 24),
              externalID: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!,
              links: Link(
                homepage: "pointfree.co",
                updatedAt: Date(timeIntervalSince1970: 60 * 60 * 36)
              ),
              pastLinks: [
                Link(
                  homepage: "example.com",
                  updatedAt: Date(timeIntervalSince1970: 60 * 60 * 12)
                )
              ]
            ),
            editor: Author(name: "Blob Jr")
          )
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
        SELECT json_array_length("posts"."notes")
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

    @Test func jsonArrayLengthPath() {
      assertQuery(
        Profile.select {
          (
            $0.author.jsonArrayLength(\.pastLinks),
            $0.editor.jsonArrayLength(\.pastLinks)
          )
        }
      ) {
        """
        SELECT json_array_length("profiles"."author", '$."pastLinks"'), json_array_length("profiles"."editor", '$."pastLinks"')
        FROM "profiles"
        """
      } results: {
        """
        ┌───┬───┐
        │ 1 │ 0 │
        └───┴───┘
        """
      }
      assertQuery(
        Bio.select { $0.resume.jsonArrayLength(\.author.pastLinks) }
      ) {
        """
        SELECT json_array_length("bios"."resume", '$."author"."pastLinks"')
        FROM "bios"
        """
      } results: {
        """
        ┌─────┐
        │ 0   │
        │ nil │
        └─────┘
        """
      }
    }

    @Test func jsonbGroupArray() {
      assertQuery(
        Post
          .update { $0.notes = Track.select { $0.trackName.jsonbGroupArray() } }
          .returning(\.notes)
      ) {
        """
        UPDATE "posts"
        SET "notes" = (
          SELECT jsonb_group_array("tracks"."track_name")
          FROM "tracks"
        )
        RETURNING json("notes")
        """
      } results: {
        """
        ┌────────────────────────┐
        │ [                      │
        │   [0]: "Blob\\'s Blues" │
        │ ]                      │
        └────────────────────────┘
        """
      }
      assertQuery(
        Post.select { _ in #sql("typeof(\"notes\")", as: String.self) }
      ) {
        """
        SELECT typeof("notes")
        FROM "posts"
        """
      } results: {
        """
        ┌────────┐
        │ "blob" │
        └────────┘
        """
      }
    }

    @Test func jsonbObject() {
      assertInlineSnapshot(of: Track.columns.jsonbObject(), as: .sql) {
        """
        jsonb_object('id', "tracks"."id", 'track_name', "tracks"."track_name", 'track_tags', "tracks"."track_tags")
        """
      }
      assertInlineSnapshot(of: Track.columns.jsonbGroupArray(), as: .sql) {
        """
        jsonb_group_array(jsonb_object('id', "tracks"."id", 'track_name', "tracks"."track_name", 'track_tags', "tracks"."track_tags"))
        """
      }
    }

    @Test func jsonGroupArray() {
      assertQuery(
        Post.select { $0.jsonGroupArray() }
      ) {
        """
        SELECT json_group_array(json_object('id', "posts"."id", 'notes', "posts"."notes", 'optionalTags', "posts"."optionalTags"))
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
        SELECT json_group_array(json_object('id', "tracks"."id", 'track_name', "tracks"."track_name", 'track_tags', "tracks"."track_tags"))
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

    @Test func jsonExtract() {
      assertQuery(
        Profile.select {
          (
            $0.author.jsonExtract(\.name),
            $0.author.jsonExtract(\.isVerified),
            $0.author.jsonExtract(\.joinedAt),
            $0.author.jsonExtract(\.externalID)
          )
        }
      ) {
        """
        SELECT json_extract("profiles"."author", '$."name"'), json_extract("profiles"."author", '$."is_verified"'), json_extract("profiles"."author", '$."joinedAt"'), (json_extract("profiles"."author", '$."externalID"') COLLATE NOCASE)
        FROM "profiles"
        """
      } results: {
        """
        ┌────────┬──────┬────────────────────────────────┬────────────────────────────────────────────┐
        │ "Blob" │ true │ Date(1970-01-02T00:00:00.000Z) │ UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF) │
        └────────┴──────┴────────────────────────────────┴────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonExtractNested() {
      assertQuery(
        Profile.select {
          (
            $0.author.jsonExtract(\.links.homepage),
            $0.author.jsonExtract(\.links.updatedAt),
            $0.author.jsonExtract(\.pastLinks[0].homepage),
            $0.editor.jsonExtract(\.name)
          )
        }
      ) {
        """
        SELECT json_extract("profiles"."author", '$."links"."homepage"'), json_extract("profiles"."author", '$."links"."updatedAt"'), json_extract("profiles"."author", '$."pastLinks"[0]."homepage"'), json_extract("profiles"."editor", '$."name"')
        FROM "profiles"
        """
      } results: {
        """
        ┌────────────────┬────────────────────────────────┬───────────────┬───────────┐
        │ "pointfree.co" │ Date(1970-01-02T12:00:00.000Z) │ "example.com" │ "Blob Jr" │
        └────────────────┴────────────────────────────────┴───────────────┴───────────┘
        """
      }
    }

    @Test func jsonExtractIdentity() {
      assertQuery(
        Profile.select { $0.author.jsonExtract(\.self) }
      ) {
        """
        SELECT json_extract("profiles"."author", '$')
        FROM "profiles"
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Author(                                                   │
        │   name: "Blob",                                           │
        │   isVerified: true,                                       │
        │   nickname: nil,                                          │
        │   joinedAt: Date(1970-01-02T00:00:00.000Z),               │
        │   externalID: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │   links: Link(                                            │
        │     homepage: "pointfree.co",                             │
        │     updatedAt: Date(1970-01-02T12:00:00.000Z)             │
        │   ),                                                      │
        │   pastLinks: [                                            │
        │     [0]: Link(                                            │
        │       homepage: "example.com",                            │
        │       updatedAt: Date(1970-01-01T12:00:00.000Z)           │
        │     )                                                     │
        │   ]                                                       │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonExtractIndex() {
      assertQuery(
        Post.select {
          ($0.notes.jsonExtract(\.[0]), $0.notes.jsonExtract(\.[-1]))
        }
      ) {
        """
        SELECT json_extract("posts"."notes", '$[0]'), json_extract("posts"."notes", '$[#-1]')
        FROM "posts"
        """
      } results: {
        """
        ┌──────────────┬─────────────┐
        │ "First post" │ "An update" │
        └──────────────┴─────────────┘
        """
      }
    }

    @Test func jsonbExtract() {
      assertQuery(
        Profile.select {
          (
            $0.author.jsonbExtract(\.name),
            $0.author.jsonbExtract(\.isVerified),
            $0.author.jsonbExtract(\.joinedAt),
            $0.author.jsonbExtract(\.externalID),
            $0.editor.jsonbExtract(\.name)
          )
        }
      ) {
        """
        SELECT jsonb_extract("profiles"."author", '$."name"'), jsonb_extract("profiles"."author", '$."is_verified"'), jsonb_extract("profiles"."author", '$."joinedAt"'), (jsonb_extract("profiles"."author", '$."externalID"') COLLATE NOCASE), jsonb_extract("profiles"."editor", '$."name"')
        FROM "profiles"
        """
      } results: {
        """
        ┌────────┬──────┬────────────────────────────────┬────────────────────────────────────────────┬───────────┐
        │ "Blob" │ true │ Date(1970-01-02T00:00:00.000Z) │ UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF) │ "Blob Jr" │
        └────────┴──────┴────────────────────────────────┴────────────────────────────────────────────┴───────────┘
        """
      }
    }

    @Test func jsonbExtractDocument() {
      assertQuery(
        Profile.select {
          ($0.author.jsonbExtract(\.links), $0.author.jsonbExtract(\.pastLinks[0]))
        }
      ) {
        """
        SELECT json(jsonb_extract("profiles"."author", '$."links"')), json(jsonb_extract("profiles"."author", '$."pastLinks"[0]'))
        FROM "profiles"
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┬─────────────────────────────────────────────┐
        │ Link(                                       │ Link(                                       │
        │   homepage: "pointfree.co",                 │   homepage: "example.com",                  │
        │   updatedAt: Date(1970-01-02T12:00:00.000Z) │   updatedAt: Date(1970-01-01T12:00:00.000Z) │
        │ )                                           │ )                                           │
        └─────────────────────────────────────────────┴─────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonbExtractThroughOptional() {
      assertQuery(
        Bio.select {
          (
            $0.resume.jsonbExtract(\.author.name),
            $0.resume.jsonbExtract(\.author.links.homepage)
          )
        }
      ) {
        """
        SELECT jsonb_extract("bios"."resume", '$."author"."name"'), jsonb_extract("bios"."resume", '$."author"."links"."homepage"')
        FROM "bios"
        """
      } results: {
        """
        ┌───────────┬─────┐
        │ "Blob Sr" │ ""  │
        │ nil       │ nil │
        └───────────┴─────┘
        """
      }
    }

    @Test func jsonbGetSet() {
      assertQuery(
        Profile
          .update {
            $0.author = $0.author.jsonbSet(\.links, $0.author.jsonbExtract(\.pastLinks[0]))
          }
          .returning(\.author)
      ) {
        """
        UPDATE "profiles"
        SET "author" = jsonb_set("profiles"."author", '$."links"', jsonb_extract("profiles"."author", '$."pastLinks"[0]'))
        RETURNING json("author")
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Author(                                                   │
        │   name: "Blob",                                           │
        │   isVerified: true,                                       │
        │   nickname: nil,                                          │
        │   joinedAt: Date(1970-01-02T00:00:00.000Z),               │
        │   externalID: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │   links: Link(                                            │
        │     homepage: "example.com",                              │
        │     updatedAt: Date(1970-01-01T12:00:00.000Z)             │
        │   ),                                                      │
        │   pastLinks: [                                            │
        │     [0]: Link(                                            │
        │       homepage: "example.com",                            │
        │       updatedAt: Date(1970-01-01T12:00:00.000Z)           │
        │     )                                                     │
        │   ]                                                       │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonbSet() {
      assertQuery(
        Profile
          .update {
            $0.author = $0.author
              .jsonbSet(\.name, "Blob, Esq.")
              .jsonbSet(\.isVerified, false)
              .jsonbSet(\.links.homepage, "pointfree.co/blog")
              .jsonbSet(\.pastLinks[0], #bind(Link(homepage: "example.org")))
          }
          .returning(\.author)
      ) {
        """
        UPDATE "profiles"
        SET "author" = jsonb_set("profiles"."author", '$."name"', 'Blob, Esq.', '$."is_verified"', json(CASE 0 WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), '$."links"."homepage"', 'pointfree.co/blog', '$."pastLinks"[0]', jsonb('{
          "homepage" : "example.org",
          "updatedAt" : "1970-01-01 00:00:00.000"
        }'))
        RETURNING json("author")
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Author(                                                   │
        │   name: "Blob, Esq.",                                     │
        │   isVerified: false,                                      │
        │   nickname: nil,                                          │
        │   joinedAt: Date(1970-01-02T00:00:00.000Z),               │
        │   externalID: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │   links: Link(                                            │
        │     homepage: "pointfree.co/blog",                        │
        │     updatedAt: Date(1970-01-02T12:00:00.000Z)             │
        │   ),                                                      │
        │   pastLinks: [                                            │
        │     [0]: Link(                                            │
        │       homepage: "example.org",                            │
        │       updatedAt: Date(1970-01-01T00:00:00.000Z)           │
        │     )                                                     │
        │   ]                                                       │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonbInsertAndReplace() {
      assertQuery(
        Profile
          .update {
            $0.author = $0.author
              .jsonbInsert(\.nickname, "Blobby")
              .jsonbReplace(\.nickname, "Blobbo")
          }
          .returning(\.author)
      ) {
        """
        UPDATE "profiles"
        SET "author" = jsonb_replace(jsonb_insert("profiles"."author", '$."nickname"', 'Blobby'), '$."nickname"', 'Blobbo')
        RETURNING json("author")
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Author(                                                   │
        │   name: "Blob",                                           │
        │   isVerified: true,                                       │
        │   nickname: "Blobbo",                                     │
        │   joinedAt: Date(1970-01-02T00:00:00.000Z),               │
        │   externalID: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │   links: Link(                                            │
        │     homepage: "pointfree.co",                             │
        │     updatedAt: Date(1970-01-02T12:00:00.000Z)             │
        │   ),                                                      │
        │   pastLinks: [                                            │
        │     [0]: Link(                                            │
        │       homepage: "example.com",                            │
        │       updatedAt: Date(1970-01-01T12:00:00.000Z)           │
        │     )                                                     │
        │   ]                                                       │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Post
          .update {
            $0.notes = $0.notes
              .jsonbReplace(\.[0], "Rewritten")
              .jsonbReplace(\.[1], "Revised")
          }
          .returning(\.notes)
      ) {
        """
        UPDATE "posts"
        SET "notes" = jsonb_replace("posts"."notes", '$[0]', 'Rewritten', '$[1]', 'Revised')
        RETURNING json("notes")
        """
      } results: {
        """
        ┌─────────────────────┐
        │ [                   │
        │   [0]: "Rewritten", │
        │   [1]: "Revised"    │
        │ ]                   │
        └─────────────────────┘
        """
      }
    }

    @Test func jsonbAppend() {
      assertQuery(
        Post
          .update {
            $0.notes = $0.notes
              .jsonbAppend("Appended")
              .jsonbAppend("Amended")
          }
          .returning(\.notes)
      ) {
        """
        UPDATE "posts"
        SET "notes" = jsonb_insert("posts"."notes", '$[#]', 'Appended', '$[#]', 'Amended')
        RETURNING json("notes")
        """
      } results: {
        """
        ┌──────────────────────┐
        │ [                    │
        │   [0]: "First post", │
        │   [1]: "An update",  │
        │   [2]: "Appended",   │
        │   [3]: "Amended"     │
        │ ]                    │
        └──────────────────────┘
        """
      }
      assertQuery(
        Profile
          .update {
            $0.author = $0.author
              .jsonbInsert(\.nickname, "Blobby")
              .jsonbAppend(
                \.pastLinks,
                #bind(Link(homepage: "blob.example", updatedAt: Date(timeIntervalSince1970: 0)))
              )
          }
          .returning(\.author)
      ) {
        """
        UPDATE "profiles"
        SET "author" = jsonb_insert("profiles"."author", '$."nickname"', 'Blobby', '$."pastLinks"[#]', jsonb('{
          "homepage" : "blob.example",
          "updatedAt" : "1970-01-01 00:00:00.000"
        }'))
        RETURNING json("author")
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Author(                                                   │
        │   name: "Blob",                                           │
        │   isVerified: true,                                       │
        │   nickname: "Blobby",                                     │
        │   joinedAt: Date(1970-01-02T00:00:00.000Z),               │
        │   externalID: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │   links: Link(                                            │
        │     homepage: "pointfree.co",                             │
        │     updatedAt: Date(1970-01-02T12:00:00.000Z)             │
        │   ),                                                      │
        │   pastLinks: [                                            │
        │     [0]: Link(                                            │
        │       homepage: "example.com",                            │
        │       updatedAt: Date(1970-01-01T12:00:00.000Z)           │
        │     ),                                                    │
        │     [1]: Link(                                            │
        │       homepage: "blob.example",                           │
        │       updatedAt: Date(1970-01-01T00:00:00.000Z)           │
        │     )                                                     │
        │   ]                                                       │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonbRemove() {
      assertQuery(
        Post
          .update {
            $0.notes = $0.notes
              .jsonbRemove(\.[0])
              .jsonbRemove(\.[0])
          }
          .returning(\.notes)
      ) {
        """
        UPDATE "posts"
        SET "notes" = jsonb_remove("posts"."notes", '$[0]', '$[0]')
        RETURNING json("notes")
        """
      } results: {
        """
        ┌────┐
        │ [] │
        └────┘
        """
      }
      assertQuery(
        Profile
          .update {
            $0.author = $0.author
              .jsonbInsert(\.nickname, "Blobby")
              .jsonbRemove(\.nickname)
          }
          .returning(\.author)
      ) {
        """
        UPDATE "profiles"
        SET "author" = jsonb_remove(jsonb_insert("profiles"."author", '$."nickname"', 'Blobby'), '$."nickname"')
        RETURNING json("author")
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Author(                                                   │
        │   name: "Blob",                                           │
        │   isVerified: true,                                       │
        │   nickname: nil,                                          │
        │   joinedAt: Date(1970-01-02T00:00:00.000Z),               │
        │   externalID: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │   links: Link(                                            │
        │     homepage: "pointfree.co",                             │
        │     updatedAt: Date(1970-01-02T12:00:00.000Z)             │
        │   ),                                                      │
        │   pastLinks: [                                            │
        │     [0]: Link(                                            │
        │       homepage: "example.com",                            │
        │       updatedAt: Date(1970-01-01T12:00:00.000Z)           │
        │     )                                                     │
        │   ]                                                       │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonbRemove_select() {
      assertQuery(
        Post
          .select { $0.notes.jsonbRemove(\.[0]) }
          .limit(1)
      ) {
        """
        SELECT json(jsonb_remove("posts"."notes", '$[0]'))
        FROM "posts"
        LIMIT 1
        """
      } results: {
        """
        ┌────────────────────┐
        │ [                  │
        │   [0]: "An update" │
        │ ]                  │
        └────────────────────┘
        """
      }
    }

    @Test func jsonExtractThroughOptional() {
      assertQuery(
        Bio.select {
          (
            $0.resume.jsonExtract(\.author.name),
            $0.resume.jsonExtract(\.author.links.homepage)
          )
        }
      ) {
        """
        SELECT json_extract("bios"."resume", '$."author"."name"'), json_extract("bios"."resume", '$."author"."links"."homepage"')
        FROM "bios"
        """
      } results: {
        """
        ┌───────────┬─────┐
        │ "Blob Sr" │ ""  │
        │ nil       │ nil │
        └───────────┴─────┘
        """
      }
    }

    @Test func jsonbMutateThroughOptional() {
      assertQuery(
        Bio
          .update {
            $0.resume = $0.resume
              .jsonbReplace(\.author.name, "Blob Sr, Esq.")
              .jsonbRemove(\.author.nickname)
          }
          .returning(\.resume)
      ) {
        """
        UPDATE "bios"
        SET "resume" = jsonb_remove(jsonb_replace("bios"."resume", '$."author"."name"', 'Blob Sr, Esq.'), '$."author"."nickname"')
        RETURNING json("resume")
        """
      } results: {
        """
        ┌─────────────────────────────────────────────────────────────┐
        │ Resume(                                                     │
        │   author: Author(                                           │
        │     name: "Blob Sr, Esq.",                                  │
        │     isVerified: false,                                      │
        │     nickname: nil,                                          │
        │     joinedAt: Date(1970-01-01T00:00:00.000Z),               │
        │     externalID: UUID(00000000-0000-0000-0000-000000000000), │
        │     links: Link(                                            │
        │       homepage: "",                                         │
        │       updatedAt: Date(1970-01-01T00:00:00.000Z)             │
        │     ),                                                      │
        │     pastLinks: []                                           │
        │   )                                                         │
        │ )                                                           │
        ├─────────────────────────────────────────────────────────────┤
        │ Resume(author: nil)                                         │
        └─────────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonGroupArrayBytesUUID() {
      assertQuery(
        Session.select { $0.jsonGroupArray() }
      ) {
        """
        SELECT json_group_array(json_object('id', "sessions"."id", 'token', CASE WHEN "sessions"."token" IS NULL THEN NULL ELSE lower(printf('%s-%s-%s-%s-%s', substr(hex("sessions"."token"), 1, 8), substr(hex("sessions"."token"), 9, 4), substr(hex("sessions"."token"), 13, 4), substr(hex("sessions"."token"), 17, 4), substr(hex("sessions"."token"), 21, 12))) END, 'refresh', CASE WHEN "sessions"."refresh" IS NULL THEN NULL ELSE lower(printf('%s-%s-%s-%s-%s', substr(hex("sessions"."refresh"), 1, 8), substr(hex("sessions"."refresh"), 9, 4), substr(hex("sessions"."refresh"), 13, 4), substr(hex("sessions"."refresh"), 17, 4), substr(hex("sessions"."refresh"), 21, 12))) END))
        FROM "sessions"
        """
      } results: {
        """
        ┌────────────────────────────────────────────────────────┐
        │ [                                                      │
        │   [0]: Session(                                        │
        │     id: 1,                                             │
        │     token: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │     refresh: nil                                       │
        │   )                                                    │
        │ ]                                                      │
        └────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonExtractUUID() {
      assertQuery(
        Profile
          .where {
            $0.author.jsonExtract(\.externalID)
              .eq(UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!)
          }
          .select(\.id)
      ) {
        """
        SELECT "profiles"."id"
        FROM "profiles"
        WHERE (((json_extract("profiles"."author", '$."externalID"') COLLATE NOCASE)) = ('deadbeef-dead-beef-dead-beefdeadbeef'))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
      }
    }

    @Test func updateReturningClosure() {
      assertQuery(
        Profile
          .update { $0.author = $0.author.jsonbSet(\.name, "Blob 2") }
          .returning { $0.author }
      ) {
        """
        UPDATE "profiles"
        SET "author" = jsonb_set("profiles"."author", '$."name"', 'Blob 2')
        RETURNING json("author")
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Author(                                                   │
        │   name: "Blob 2",                                         │
        │   isVerified: true,                                       │
        │   nickname: nil,                                          │
        │   joinedAt: Date(1970-01-02T00:00:00.000Z),               │
        │   externalID: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │   links: Link(                                            │
        │     homepage: "pointfree.co",                             │
        │     updatedAt: Date(1970-01-02T12:00:00.000Z)             │
        │   ),                                                      │
        │   pastLinks: [                                            │
        │     [0]: Link(                                            │
        │       homepage: "example.com",                            │
        │       updatedAt: Date(1970-01-01T12:00:00.000Z)           │
        │     )                                                     │
        │   ]                                                       │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonExtractInWhere() {
      assertQuery(
        Profile
          .where { $0.author.jsonExtract(\.name).eq("Blob") }
          .select(\.id)
      ) {
        """
        SELECT "profiles"."id"
        FROM "profiles"
        WHERE ((json_extract("profiles"."author", '$."name"')) = ('Blob'))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
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

    @Test func jsonGetSet() {
      assertQuery(
        Profile.update {
          $0.author = $0.author.jsonbSet(
            \.pastLinks,
            Profile.select { $0.author.jsonExtract(\.pastLinks) }.limit(1)
          )
        }
        .returning(\.self)
      ) {
        """
        UPDATE "profiles"
        SET "author" = jsonb_set("profiles"."author", '$."pastLinks"', (
          SELECT json_extract("profiles"."author", '$."pastLinks"')
          FROM "profiles"
          LIMIT 1
        ))
        RETURNING "id", json("author"), json("editor")
        """
      } results: {
        """
        ┌─────────────────────────────────────────────────────────────┐
        │ Profile(                                                    │
        │   id: 1,                                                    │
        │   author: Author(                                           │
        │     name: "Blob",                                           │
        │     isVerified: true,                                       │
        │     nickname: nil,                                          │
        │     joinedAt: Date(1970-01-02T00:00:00.000Z),               │
        │     externalID: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │     links: Link(                                            │
        │       homepage: "pointfree.co",                             │
        │       updatedAt: Date(1970-01-02T12:00:00.000Z)             │
        │     ),                                                      │
        │     pastLinks: [                                            │
        │       [0]: Link(                                            │
        │         homepage: "example.com",                            │
        │         updatedAt: Date(1970-01-01T12:00:00.000Z)           │
        │       )                                                     │
        │     ]                                                       │
        │   ),                                                        │
        │   editor: Author(                                           │
        │     name: "Blob Jr",                                        │
        │     isVerified: false,                                      │
        │     nickname: nil,                                          │
        │     joinedAt: Date(1970-01-01T00:00:00.000Z),               │
        │     externalID: UUID(00000000-0000-0000-0000-000000000000), │
        │     links: Link(                                            │
        │       homepage: "",                                         │
        │       updatedAt: Date(1970-01-01T00:00:00.000Z)             │
        │     ),                                                      │
        │     pastLinks: []                                           │
        │   )                                                         │
        │ )                                                           │
        └─────────────────────────────────────────────────────────────┘
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
private struct Profile: Codable, Equatable {
  let id: Int
  @Column(as: Author.JSONBRepresentation.self)
  var author: Author = Author()
  @Column(as: Author.JSONBRepresentation?.self)
  var editor: Author?
}

@Selection
private struct Author: Codable, Equatable {
  var name = ""
  @Column("is_verified")
  var isVerified = false
  var nickname: String?
  @Column(as: Date.UnixTimeRepresentation.self)
  var joinedAt = Date(timeIntervalSince1970: 0)
  @Column(as: UUID.BytesRepresentation.self)
  var externalID = UUID(0)
  @Column(as: Link.JSONBRepresentation.self)
  var links: Link = Link()
  @Column(as: [Link].JSONBRepresentation.self)
  var pastLinks: [Link] = []
}

@Selection
private struct Link: Codable, Equatable {
  var homepage = ""
  var updatedAt = Date(timeIntervalSince1970: 0)
}

@Table
private struct Track: Codable, Equatable {
  let id: Int
  @Column("track_name")
  var trackName = ""
  @Column("track_tags", as: [String].JSONBRepresentation.self)
  var trackTags: [String] = []
}

@Selection
private struct Resume: Codable, Equatable {
  @Column(as: Author.JSONBRepresentation?.self)
  var author: Author?
}

@Table
private struct Bio: Codable, Equatable {
  let id: Int
  @Column(as: Resume.JSONBRepresentation.self)
  var resume: Resume = Resume()
}

@Table
private struct Session: Codable, Equatable {
  let id: Int
  @Column(as: UUID.BytesRepresentation.self)
  var token: UUID = UUID(0)
  @Column(as: UUID.BytesRepresentation?.self)
  var refresh: UUID?
}
