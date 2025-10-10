#if StructuredQueriesCasePaths
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
          WHERE ("attachments"."link", "attachments"."note", "attachments"."videoURL", "attachments"."videoKind", "attachments"."imageCaption", "attachments"."imageURL") IS (NULL, 'Today was a good day', NULL, NULL, NULL, NULL)
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
          WHERE ("attachments"."note") IS ('Today was a good day')
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
          WHERE ("attachments"."imageCaption", "attachments"."imageURL") IS NOT (NULL, NULL)
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
          WHERE ("attachments"."imageCaption", "attachments"."imageURL") IS NOT (NULL, NULL)
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
          WHERE ("attachments"."id") IN ((1))
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
              Attachment.Image(caption: "Blob", url: URL(string: "https://pointfree.co")!))
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
    }
  }

  @Table private struct Attachment {
    let id: Int
    let kind: Kind

    @CasePathable @Selection
    fileprivate enum Kind {
      case link(URL)
      case note(String)
      case video(Attachment.Video)
      case image(Attachment.Image)
    }

    @Selection fileprivate struct Video {
      @Column("videoURL")
      let url: URL
      @Column("videoKind")
      var kind: Kind
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
