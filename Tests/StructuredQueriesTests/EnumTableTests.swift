#if CasePaths
  import CasePaths
  import Dependencies
  import Foundation
  import InlineSnapshotTesting
  import StructuredQueries
  import StructuredQueriesTestSupport
  import Testing
  import _StructuredQueriesSQLite

  extension SnapshotTests {
    @Suite struct EnumTableTests {
      @Dependency(\.defaultDatabase) var db

      init() throws {
        try db.execute(
          """
          CREATE TABLE "attachments" (
            "id" INTEGER PRIMARY KEY,
            "link" TEXT,
            "note" TEXT,
            "videoURL" TEXT,
            "videoKind" TEXT,
            "imageCaption" TEXT,
            "imageURL" TEXT
          ) STRICT
          """
        )
        try db.execute(
          """
          INSERT INTO "attachments"
          ("link") VALUES ('https://www.pointfree.co')
          """
        )
        try db.execute(
          """
          INSERT INTO "attachments"
          ("note") VALUES ('Today was a good day')
          """
        )
        try db.execute(
          """
          INSERT INTO "attachments"
          ("videoURL", "videoKind") VALUES ('https://www.youtube.com/video/1234', 'youtube')
          """
        )
        try db.execute(
          """
          INSERT INTO "attachments"
          ("imageCaption", "imageURL") VALUES ('Blob', 'https://www.pointfree.co/blob.jpg')
          """
        )
      }

      @Test func selectAll() {
        assertQuery(
          Attachment.all
        ) {
          """
          SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          """
        } results: {
          """
          ┌─────────────────────────────────────────────────────┐
          │ Attachment(                                         │
          │   id: 1,                                            │
          │   kind: .link(URL(https://www.pointfree.co))        │
          │ )                                                   │
          ├─────────────────────────────────────────────────────┤
          │ Attachment(                                         │
          │   id: 2,                                            │
          │   kind: .note("Today was a good day")               │
          │ )                                                   │
          ├─────────────────────────────────────────────────────┤
          │ Attachment(                                         │
          │   id: 3,                                            │
          │   kind: .video(                                     │
          │     Attachment.Video(                               │
          │       url: URL(https://www.youtube.com/video/1234), │
          │       kind: .youtube                                │
          │     )                                               │
          │   )                                                 │
          │ )                                                   │
          ├─────────────────────────────────────────────────────┤
          │ Attachment(                                         │
          │   id: 4,                                            │
          │   kind: .image(                                     │
          │     Attachment.Image(                               │
          │       caption: "Blob",                              │
          │       url: URL(https://www.pointfree.co/blob.jpg)   │
          │     )                                               │
          │   )                                                 │
          │ )                                                   │
          └─────────────────────────────────────────────────────┘
          """
        }
      }

      @Test func customSelect() {
        assertQuery(
          Attachment.select { $0.kind }
        ) {
          """
          SELECT "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          """
        } results: {
          """
          ┌─────────────────────────────────────────────────────┐
          │ Attachment.Kind.link(URL(https://www.pointfree.co)) │
          ├─────────────────────────────────────────────────────┤
          │ Attachment.Kind.note("Today was a good day")        │
          ├─────────────────────────────────────────────────────┤
          │ Attachment.Kind.video(                              │
          │   Attachment.Video(                                 │
          │     url: URL(https://www.youtube.com/video/1234),   │
          │     kind: .youtube                                  │
          │   )                                                 │
          │ )                                                   │
          ├─────────────────────────────────────────────────────┤
          │ Attachment.Kind.image(                              │
          │   Attachment.Image(                                 │
          │     caption: "Blob",                                │
          │     url: URL(https://www.pointfree.co/blob.jpg)     │
          │   )                                                 │
          │ )                                                   │
          └─────────────────────────────────────────────────────┘
          """
        }
      }

      @Test func isOperator() {
        assertQuery(
          Attachment.where { $0.kind.is(\.note) }
        ) {
          """
          SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          WHERE (("attachments"."note") IS NOT (NULL))
          """
        } results: {
          """
          ┌───────────────────────────────────────┐
          │ Attachment(                           │
          │   id: 2,                              │
          │   kind: .note("Today was a good day") │
          │ )                                     │
          └───────────────────────────────────────┘
          """
        }
        assertQuery(
          Attachment.where { $0.kind.is(\.video) }
        ) {
          """
          SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          WHERE (("attachments"."videoURL", "attachments"."videoKind") IS NOT (NULL, NULL))
          """
        } results: {
          """
          ┌─────────────────────────────────────────────────────┐
          │ Attachment(                                         │
          │   id: 3,                                            │
          │   kind: .video(                                     │
          │     Attachment.Video(                               │
          │       url: URL(https://www.youtube.com/video/1234), │
          │       kind: .youtube                                │
          │     )                                               │
          │   )                                                 │
          │ )                                                   │
          └─────────────────────────────────────────────────────┘
          """
        }
        assertQuery(
          Attachment
            .select { $0.kind.video }
            .where { $0.kind.video.isNot(nil) }
        ) {
          """
          SELECT "attachments"."videoURL", "attachments"."videoKind"
          FROM "attachments"
          WHERE (("attachments"."videoURL", "attachments"."videoKind") IS NOT (NULL, NULL))
          """
        } results: {
          """
          ┌─────────────────────────────────────────────────┐
          │ Attachment.Video(                               │
          │   url: URL(https://www.youtube.com/video/1234), │
          │   kind: .youtube                                │
          │ )                                               │
          └─────────────────────────────────────────────────┘
          """
        }
      }

      @Test func dynamicMemberLookup_CasePath() {
        assertQuery(
          Attachment.select(\.kind.image)
        ) {
          """
          SELECT "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          """
        } results: {
          """
          ┌───────────────────────────────────────────────┐
          │ nil                                           │
          ├───────────────────────────────────────────────┤
          │ nil                                           │
          ├───────────────────────────────────────────────┤
          │ nil                                           │
          ├───────────────────────────────────────────────┤
          │ Attachment.Image(                             │
          │   caption: "Blob",                            │
          │   url: URL(https://www.pointfree.co/blob.jpg) │
          │ )                                             │
          └───────────────────────────────────────────────┘
          """
        }
      }

      @Test func dynamicMemberLookup_MultipleLevels() {
        assertQuery(
          Attachment.select(\.kind.image.caption)
        ) {
          """
          SELECT "attachments"."imageCaption"
          FROM "attachments"
          """
        } results: {
          """
          ┌────────┐
          │ nil    │
          │ nil    │
          │ nil    │
          │ "Blob" │
          └────────┘
          """
        }
      }

      @Test func whereClause() {
        assertQuery(
          Attachment.where { $0.kind.is(Attachment.Kind.note("Today was a good day")) }
        ) {
          """
          SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          WHERE (("attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL") IS (NULL, 'Today was a good day', NULL, NULL, NULL, NULL))
          """
        } results: {
          """
          ┌───────────────────────────────────────┐
          │ Attachment(                           │
          │   id: 2,                              │
          │   kind: .note("Today was a good day") │
          │ )                                     │
          └───────────────────────────────────────┘
          """
        }
        assertQuery(
          Attachment.where { $0.kind.note.is("Today was a good day") }
        ) {
          """
          SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          WHERE (("attachments"."note") IS ('Today was a good day'))
          """
        } results: {
          """
          ┌───────────────────────────────────────┐
          │ Attachment(                           │
          │   id: 2,                              │
          │   kind: .note("Today was a good day") │
          │ )                                     │
          └───────────────────────────────────────┘
          """
        }
      }

      @Test func whereClause_DynamicMemberLookup() {
        assertQuery(
          Attachment.where { $0.kind.image.isNot(nil) }
        ) {
          """
          SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          WHERE (("attachments"."imageCaption", "attachments"."imageURL") IS NOT (NULL, NULL))
          """
        } results: {
          """
          ┌───────────────────────────────────────────────────┐
          │ Attachment(                                       │
          │   id: 4,                                          │
          │   kind: .image(                                   │
          │     Attachment.Image(                             │
          │       caption: "Blob",                            │
          │       url: URL(https://www.pointfree.co/blob.jpg) │
          │     )                                             │
          │   )                                               │
          │ )                                                 │
          └───────────────────────────────────────────────────┘
          """
        }
      }

      @Test func whereClauseEscapeHatch() {
        assertQuery(
          Attachment
            .where {
              #sql("(\($0.kind.image)) IS NOT (NULL, NULL)")
            }
        ) {
          """
          SELECT "attachments"."id", "attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL"
          FROM "attachments"
          WHERE (("attachments"."imageCaption", "attachments"."imageURL") IS NOT (NULL, NULL))
          """
        } results: {
          """
          ┌───────────────────────────────────────────────────┐
          │ Attachment(                                       │
          │   id: 4,                                          │
          │   kind: .image(                                   │
          │     Attachment.Image(                             │
          │       caption: "Blob",                            │
          │       url: URL(https://www.pointfree.co/blob.jpg) │
          │     )                                             │
          │   )                                               │
          │ )                                                 │
          └───────────────────────────────────────────────────┘
          """
        }
      }

      // TODO: write test for #sql escape hatch

      @Test func insert() {
        assertQuery(
          Attachment.insert {
            Attachment.Draft(kind: .note("Hello world!"))
            Attachment.Draft(
              kind: .image(
                Attachment.Image(
                  caption: "Image",
                  url: URL(string: "image.jpg")!
                )
              )
            )
          }
          .returning(\.self)
        ) {
          """
          INSERT INTO "attachments"
          ("id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL")
          VALUES
          (NULL, NULL, 'Hello world!', NULL, NULL, NULL, NULL), (NULL, NULL, NULL, NULL, NULL, 'Image', 'image.jpg')
          RETURNING "id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL"
          """
        } results: {
          """
          ┌───────────────────────────────┐
          │ Attachment(                   │
          │   id: 5,                      │
          │   kind: .note("Hello world!") │
          │ )                             │
          ├───────────────────────────────┤
          │ Attachment(                   │
          │   id: 6,                      │
          │   kind: .image(               │
          │     Attachment.Image(         │
          │       caption: "Image",       │
          │       url: URL(image.jpg)     │
          │     )                         │
          │   )                           │
          │ )                             │
          └───────────────────────────────┘
          """
        }
      }

      @Test func update() {
        assertQuery(
          Attachment
            .find(1)
            .update {
              $0.kind = .note("Good bye world!")
            }
            .returning(\.self)
        ) {
          """
          UPDATE "attachments"
          SET "link" = NULL, "note" = 'Good bye world!', "videoURL" = NULL, "videoKind" = NULL, "imageCaption" = NULL, "imageURL" = NULL
          WHERE (("attachments"."id") IN ((1)))
          RETURNING "id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL"
          """
        } results: {
          """
          ┌──────────────────────────────────┐
          │ Attachment(                      │
          │   id: 1,                         │
          │   kind: .note("Good bye world!") │
          │ )                                │
          └──────────────────────────────────┘
          """
        }
      }

      @Test func updateCase() {
        assertQuery(
          Attachment
            .find(1)
            .update {
              $0.kind.note = #bind("Hello, world!")
            }
            .returning(\.self)
        ) {
          """
          UPDATE "attachments"
          SET "note" = 'Hello, world!', "link" = NULL, "videoURL" = NULL, "videoKind" = NULL, "imageCaption" = NULL, "imageURL" = NULL
          WHERE (("attachments"."id") IN ((1)))
          RETURNING "id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL"
          """
        } results: {
          """
          ┌────────────────────────────────┐
          │ Attachment(                    │
          │   id: 1,                       │
          │   kind: .note("Hello, world!") │
          │ )                              │
          └────────────────────────────────┘
          """
        }
      }

      @Test func updateCaseGroup() {
        assertQuery(
          Attachment
            .find(2)
            .update {
              $0.kind.image = Attachment.Image(
                caption: "Blob",
                url: URL(string: "https://www.pointfree.co/blob.jpg")!
              )
            }
            .returning(\.self)
        ) {
          """
          UPDATE "attachments"
          SET "imageCaption" = 'Blob', "imageURL" = 'https://www.pointfree.co/blob.jpg', "link" = NULL, "note" = NULL, "videoURL" = NULL, "videoKind" = NULL
          WHERE (("attachments"."id") IN ((2)))
          RETURNING "id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL"
          """
        } results: {
          """
          ┌───────────────────────────────────────────────────┐
          │ Attachment(                                       │
          │   id: 2,                                          │
          │   kind: .image(                                   │
          │     Attachment.Image(                             │
          │       caption: "Blob",                            │
          │       url: URL(https://www.pointfree.co/blob.jpg) │
          │     )                                             │
          │   )                                               │
          │ )                                                 │
          └───────────────────────────────────────────────────┘
          """
        }
      }

      @Test func selection() {
        assertQuery(
          Values(
            Attachment.Kind.Selection.note("Hello, world!")
          )
        ) {
          """
          SELECT NULL AS "link", 'Hello, world!' AS "note", NULL AS "videoURL", NULL AS "videoKind", NULL AS "imageCaption", NULL AS "imageURL"
          """
        } results: {
          """
          ┌───────────────────────────────────────┐
          │ Attachment.Kind.note("Hello, world!") │
          └───────────────────────────────────────┘
          """
        }
        assertQuery(
          Values(
            Attachment.Kind.Selection.image(
              Attachment.Image(caption: "Blob", url: URL(string: "https://pointfree.co")!)
            )
          )
        ) {
          """
          SELECT NULL AS "link", NULL AS "note", NULL AS "videoURL", NULL AS "videoKind", 'Blob', 'https://pointfree.co' AS "imageCaption"
          """
        } results: {
          """
          ┌────────────────────────────────────┐
          │ Attachment.Kind.image(             │
          │   Attachment.Image(                │
          │     caption: "Blob",               │
          │     url: URL(https://pointfree.co) │
          │   )                                │
          │ )                                  │
          └────────────────────────────────────┘
          """
        }
      }

      @Test func `enum case with defaults isn't always decoded successfully`() {
        assertQuery(
          Attachment.upsert {
            Attachment
              .Draft(
                kind: .image(
                  Attachment.Image(
                    caption: "Hello",
                    url: URL(string: "https://image.com")!
                  )
                )
              )
          }
          .returning(\.self)
        ) {
          """
          INSERT INTO "attachments"
          ("id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL")
          VALUES
          (NULL, NULL, NULL, NULL, NULL, 'Hello', 'https://image.com')
          ON CONFLICT ("id")
          DO UPDATE SET "link" = "excluded"."link", "note" = "excluded"."note", "videoURL" = "excluded"."videoURL", "videoKind" = "excluded"."videoKind", "imageCaption" = "excluded"."imageCaption", "imageURL" = "excluded"."imageURL"
          RETURNING "id", "link", "note", "videoURL", "videoKind", "imageCaption", "imageURL"
          """
        } results: {
          """
          ┌───────────────────────────────────┐
          │ Attachment(                       │
          │   id: 5,                          │
          │   kind: .image(                   │
          │     Attachment.Image(             │
          │       caption: "Hello",           │
          │       url: URL(https://image.com) │
          │     )                             │
          │   )                               │
          │ )                                 │
          └───────────────────────────────────┘
          """
        }
      }
    }
  }

  #if ColumnCoding
    extension SnapshotTests.EnumTableTests {
      @Test func jsonGroupArrayDecoding() throws {
        try db.execute(
          """
          CREATE TABLE "medias" (
            "note" TEXT,
            "video_preview" TEXT,
            "image_caption" TEXT,
            "image_url" TEXT
          )
          """
        )
        try db.execute(
          """
          INSERT INTO "medias"
          ("note", "video_preview", "image_caption", "image_url")
          VALUES
          ('Hello', NULL, NULL, NULL),
          (NULL, 'https://www.pointfree.co/preview.mov', NULL, NULL),
          (NULL, NULL, 'Blob', 'https://www.pointfree.co/blob.jpg')
          """
        )
        assertQuery(
          Media.select { MediaList.Columns(medias: $0.jsonGroupArray()) }
        ) {
          """
          SELECT json_group_array(CASE WHEN "medias"."note" IS NOT NULL THEN json_object('note', "medias"."note") WHEN "medias"."video_preview" IS NOT NULL THEN json_object('video_preview', "medias"."video_preview") WHEN ("medias"."image_caption" IS NOT NULL OR "medias"."image_url" IS NOT NULL) THEN json_object('image', json_object('image_caption', "medias"."image_caption", 'image_url', "medias"."image_url")) END) AS "medias"
          FROM "medias"
          """
        } results: {
          """
          ┌────────────────────────────────────────────────────────────────────┐
          │ MediaList(                                                         │
          │   medias: [                                                        │
          │     [0]: .note("Hello"),                                           │
          │     [1]: .videoPreview(URL(https://www.pointfree.co/preview.mov)), │
          │     [2]: .image(                                                   │
          │       MediaImage(                                                  │
          │         caption: "Blob",                                           │
          │         url: URL(https://www.pointfree.co/blob.jpg)                │
          │       )                                                            │
          │     )                                                              │
          │   ]                                                                │
          │ )                                                                  │
          └────────────────────────────────────────────────────────────────────┘
          """
        }
      }

      @Test func jsonExtractCases() throws {
        try db.execute(
          """
          CREATE TABLE "takes" (
            "id" INTEGER PRIMARY KEY,
            "media" BLOB NOT NULL
          )
          """
        )
        try db.execute(
          Take.insert {
            [
              Take(id: 1, media: .note("Hello")),
              Take(id: 2, media: .videoPreview(URL(string: "https://www.pointfree.co/preview.mov")!)),
              Take(
                id: 3,
                media: .image(
                  MediaImage(caption: "Blob", url: URL(string: "https://www.pointfree.co/blob.jpg")!)
                )
              ),
            ]
          }
        )
        assertQuery(
          Take.select {
            ($0.media.jsonExtract(\.note), $0.media.jsonbExtract(\.videoPreview))
          }
        ) {
          """
          SELECT json_extract("takes"."media", '$."note"'), jsonb_extract("takes"."media", '$."video_preview"')
          FROM "takes"
          """
        } results: {
          """
          ┌─────────┬───────────────────────────────────────────┐
          │ "Hello" │ nil                                       │
          │ nil     │ URL(https://www.pointfree.co/preview.mov) │
          │ nil     │ nil                                       │
          └─────────┴───────────────────────────────────────────┘
          """
        }
        assertQuery(
          Take.select {
            ($0.media.jsonExtract(\.image), $0.media.jsonExtract(\.image.caption))
          }
        ) {
          """
          SELECT json_extract("takes"."media", '$."image"'), json_extract("takes"."media", '$."image"."image_caption"')
          FROM "takes"
          """
        } results: {
          """
          ┌───────────────────────────────────────────────┬────────┐
          │ nil                                           │ nil    │
          ├───────────────────────────────────────────────┼────────┤
          │ nil                                           │ nil    │
          ├───────────────────────────────────────────────┼────────┤
          │ MediaImage(                                   │ "Blob" │
          │   caption: "Blob",                            │        │
          │   url: URL(https://www.pointfree.co/blob.jpg) │        │
          │ )                                             │        │
          └───────────────────────────────────────────────┴────────┘
          """
        }
      }

      @Test func jsonbSetCase() throws {
        try db.execute(
          """
          CREATE TABLE "takes" (
            "id" INTEGER PRIMARY KEY,
            "media" BLOB NOT NULL
          )
          """
        )
        try db.execute(
          Take.insert {
            [
              Take(id: 1, media: .note("Hello")),
              Take(id: 2, media: .videoPreview(URL(string: "https://www.pointfree.co/preview.mov")!)),
            ]
          }
        )
        assertQuery(
          Take
            .update { $0.media = $0.media.jsonbSet(\.note, "Switched") }
            .returning(\.media)
        ) {
          """
          UPDATE "takes"
          SET "media" = jsonb_set("takes"."media", '$', jsonb_object('note', 'Switched'))
          RETURNING json("media")
          """
        } results: {
          """
          ┌────────────────────────┐
          │ Media.note("Switched") │
          │ Media.note("Switched") │
          └────────────────────────┘
          """
        }
      }

      @Test func jsonbReplaceCase() throws {
        try db.execute(
          """
          CREATE TABLE "takes" (
            "id" INTEGER PRIMARY KEY,
            "media" BLOB NOT NULL
          )
          """
        )
        try db.execute(
          Take.insert {
            [
              Take(id: 1, media: .note("Hello")),
              Take(id: 2, media: .videoPreview(URL(string: "https://www.pointfree.co/preview.mov")!)),
            ]
          }
        )
        assertQuery(
          Take
            .update {
              $0.media = $0.media.jsonbReplace(
                \.videoPreview, URL(string: "https://www.pointfree.co/preview.mp4")!
              )
            }
            .returning(\.media)
        ) {
          """
          UPDATE "takes"
          SET "media" = jsonb_replace("takes"."media", '$."video_preview"', 'https://www.pointfree.co/preview.mp4')
          RETURNING json("media")
          """
        } results: {
          """
          ┌───────────────────────────────────────────────────────────────┐
          │ Media.note("Hello")                                           │
          │ Media.videoPreview(URL(https://www.pointfree.co/preview.mp4)) │
          └───────────────────────────────────────────────────────────────┘
          """
        }
      }
      @Test func replaceIfActive() throws {
        try db.execute(
          """
          CREATE TABLE "abcRows" (
            "id" INTEGER PRIMARY KEY,
            "doc" BLOB NOT NULL
          )
          """
        )
        try db.execute(
          ABCRow.insert {
            [
              ABCRow(id: 1, doc: ABCDoc(abc: .a(CaseA(d: 1)))),
              ABCRow(id: 2, doc: ABCDoc(abc: .b(CaseB(e: 2, f: 3)))),
            ]
          }
        )
        assertQuery(
          ABCRow.update { $0.doc = $0.doc.jsonbReplace(\.abc.b.e, 99) }
        ) {
          """
          UPDATE "abcRows"
          SET "doc" = jsonb_replace("abcRows"."doc", '$."abc"."b"."e"', 99)
          """
        }
        assertQuery(
          ABCRow.select { _ in #sql("json(\"doc\")", as: String.self) }
        ) {
          """
          SELECT json("doc")
          FROM "abcRows"
          """
        } results: {
          """
          ┌──────────────────────────────────┐
          │ #"{"abc":{"a":{"d":1}}}"#        │
          │ #"{"abc":{"b":{"e":99,"f":3}}}"# │
          └──────────────────────────────────┘
          """
        }
      }
    }

    @Table private enum Media: Codable {
      case note(String)
      @Column("video_preview")
      case videoPreview(URL)
      case image(MediaImage)
    }

    @Selection private struct MediaImage: Codable {
      @Column("image_caption")
      var caption = ""
      @Column("image_url")
      let url: URL
    }

    @Selection private struct MediaList {
      @Column(as: [Media].JSONRepresentation.self)
      let medias: [Media]
    }

    @Table private struct Take {
      let id: Int
      @Column(as: Media.JSONBRepresentation.self)
      var media: Media
    }

    @Table private enum ABC: Codable {
      case a(CaseA)
      case b(CaseB)
      case c(String)
    }

    @Selection private struct CaseA: Codable {
      var d = 0
    }

    @Selection private struct CaseB: Codable {
      var e = 0
      var f = 0
    }

    @Selection private struct ABCDoc: Codable {
      var abc: ABC
    }

    @Table private enum Feed: Codable {
      case title(String)
      @Column(as: [String].JSONRepresentation.self)
      case tags([String])
    }

    @Table private struct FeedRow {
      let id: Int
      @Column(as: Feed.JSONBRepresentation.self)
      var feed: Feed
    }

    @Table("abcRows") private struct ABCRow {
      let id: Int
      @Column(as: ABCDoc.JSONBRepresentation.self)
      var doc: ABCDoc
    }
  #endif

  @Table private struct Attachment {
    let id: Int
    let kind: Kind

    @Selection
    fileprivate enum Kind {
      case link(URL)
      case note(String)
      case video(Attachment.Video)
      case image(Attachment.Image)
    }

    @Selection fileprivate struct Video {
      @Column("videoURL")
      var url: URL = URL(string: "https://youtube.com")!
      @Column("videoKind")
      var kind: Kind = .youtube
      fileprivate enum Kind: String, QueryBindable { case youtube, vimeo }
    }
    @Selection fileprivate struct Image {
      @Column("imageCaption")
      let caption: String
      @Column("imageURL")
      let url: URL
    }
  }
#endif
