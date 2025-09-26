import CasePaths
import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct NestedTests {
    @Dependency(\.defaultDatabase) var db

    @Test func basics() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "items" (
            "title" TEXT NOT NULL DEFAULT '',
            "quantity" INTEGER NOT NULL DEFAULT 0,
            "isOutOfStock" INTEGER NOT NULL DEFAULT 0,
            "isOnBackOrder" INTEGER NOT NULL DEFAULT 0
          )
          """
        )
      )
      assertQuery(
        Item
          .insert {
            Item(title: "Phone", quantity: 1, status: Status())
          }
          .returning(\.self)
      ) {
        """
        INSERT INTO "items"
        ("title", "quantity", "isOutOfStock", "isOnBackOrder")
        VALUES
        ('Phone', 1, 0, 0)
        RETURNING "title", "quantity", "isOutOfStock", "isOnBackOrder"
        """
      } results: {
        """
        ┌──────────────────────────┐
        │ Item(                    │
        │   title: "Phone",        │
        │   quantity: 1,           │
        │   status: Status(        │
        │     isOutOfStock: false, │
        │     isOnBackOrder: false │
        │   )                      │
        │ )                        │
        └──────────────────────────┘
        """
      }
      assertQuery(
        Item.insert {
          $0.status.isOutOfStock
        } values: {
          true
        }
      ) {
        """
        INSERT INTO "items"
        ("isOutOfStock")
        VALUES
        (1)
        """
      }
      assertQuery(
        Item.insert {
          $0.status
        } values: {
          Status(isOutOfStock: true, isOnBackOrder: true)
        }
      ) {
        """
        INSERT INTO "items"
        ("isOutOfStock", "isOnBackOrder")
        VALUES
        (1, 1)
        """
      }
      assertQuery(
        Item.all
      ) {
        """
        SELECT "items"."title", "items"."quantity", "items"."isOutOfStock", "items"."isOnBackOrder"
        FROM "items"
        """
      } results: {
        """
        ┌──────────────────────────┐
        │ Item(                    │
        │   title: "Phone",        │
        │   quantity: 1,           │
        │   status: Status(        │
        │     isOutOfStock: false, │
        │     isOnBackOrder: false │
        │   )                      │
        │ )                        │
        ├──────────────────────────┤
        │ Item(                    │
        │   title: "",             │
        │   quantity: 0,           │
        │   status: Status(        │
        │     isOutOfStock: true,  │
        │     isOnBackOrder: false │
        │   )                      │
        │ )                        │
        ├──────────────────────────┤
        │ Item(                    │
        │   title: "",             │
        │   quantity: 0,           │
        │   status: Status(        │
        │     isOutOfStock: true,  │
        │     isOnBackOrder: true  │
        │   )                      │
        │ )                        │
        └──────────────────────────┘
        """
      }
      assertQuery(
        Item.where { $0.status.eq(Status()) }.select(\.status)
      ) {
        """
        SELECT "items"."isOutOfStock", "items"."isOnBackOrder"
        FROM "items"
        WHERE ("items"."isOutOfStock", "items"."isOnBackOrder") = (0, 0)
        """
      } results: {
        """
        ┌────────────────────────┐
        │ Status(                │
        │   isOutOfStock: false, │
        │   isOnBackOrder: false │
        │ )                      │
        └────────────────────────┘
        """
      }
      assertQuery(
        Item.update {
          $0.status.isOutOfStock = true
        }
      ) {
        """
        UPDATE "items"
        SET "isOutOfStock" = 1
        """
      }
      assertQuery(
        Item.update {
          $0.status = Status(isOutOfStock: true, isOnBackOrder: true)
        }
      ) {
        """
        UPDATE "items"
        SET "isOutOfStock" = 1, "isOnBackOrder" = 1
        """
      }
      // FIXME: These should decode 'nil' but because all its fields have defaults it coalesces.
      assertQuery(
        DefaultItem?(nil)
      ) {
        """
        SELECT NULL AS "title", NULL AS "quantity", NULL AS "isOutOfStock", NULL AS "isOnBackOrder"
        """
      } results: {
        """
        ┌──────────────────────────┐
        │ DefaultItem(             │
        │   title: "",             │
        │   quantity: 0,           │
        │   status: Status(        │
        │     isOutOfStock: false, │
        │     isOnBackOrder: false │
        │   )                      │
        │ )                        │
        └──────────────────────────┘
        """
      }
      // NB: This tests that 'Optional.none' is favored over 'Table.none'.
      assertQuery(
        DefaultItem?.none
      ) {
        """
        SELECT NULL AS "title", NULL AS "quantity", NULL AS "isOutOfStock", NULL AS "isOnBackOrder"
        """
      } results: {
        """
        ┌──────────────────────────┐
        │ DefaultItem(             │
        │   title: "",             │
        │   quantity: 0,           │
        │   status: Status(        │
        │     isOutOfStock: false, │
        │     isOnBackOrder: false │
        │   )                      │
        │ )                        │
        └──────────────────────────┘
        """
      }
    }

    @Test func optionalDoubleNested() async throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "itemWithTimestamps" (
            "title" TEXT,
            "quantity" INTEGER,
            "isOutOfStock" INTEGER,
            "isOnBackOrder" INTEGER,
            "timestamp" TEXT NOT NULL
          )
          """
        )
      )
      assertQuery(
        ItemWithTimestamp.insert {
          ItemWithTimestamp(item: nil, timestamp: Date(timeIntervalSinceReferenceDate: 0))
        }
      ) {
        """
        INSERT INTO "itemWithTimestamps"
        ("title", "quantity", "isOutOfStock", "isOnBackOrder", "timestamp")
        VALUES
        (NULL, NULL, NULL, NULL, '2001-01-01 00:00:00.000')
        """
      }
      assertQuery(
        ItemWithTimestamp(item: nil, timestamp: Date(timeIntervalSinceReferenceDate: 0))
      ) {
        """
        SELECT NULL AS "title", NULL AS "quantity", NULL AS "isOutOfStock", NULL AS "isOnBackOrder", '2001-01-01 00:00:00.000' AS "timestamp"
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ ItemWithTimestamp(                          │
        │   item: nil,                                │
        │   timestamp: Date(2001-01-01T00:00:00.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
      assertQuery(
        ItemWithTimestamp.insert {
          ItemWithTimestamp(
            item: Item(
              title: "Pencil",
              quantity: 0,
              status: Status(isOutOfStock: true, isOnBackOrder: true)
            ),
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
          )
        }
      ) {
        """
        INSERT INTO "itemWithTimestamps"
        ("title", "quantity", "isOutOfStock", "isOnBackOrder", "timestamp")
        VALUES
        ('Pencil', 0, 1, 1, '2001-01-01 00:00:00.000')
        """
      }
      assertQuery(
        ItemWithTimestamp.select { _ in
          ItemWithTimestamp.Columns(
            timestamp: Date(timeIntervalSinceReferenceDate: 0)
          )
        }
      ) {
        """
        SELECT NULL AS "title", NULL AS "quantity", NULL AS "isOutOfStock", NULL AS "isOnBackOrder", '2001-01-01 00:00:00.000' AS "timestamp"
        FROM "itemWithTimestamps"
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ ItemWithTimestamp(                          │
        │   item: nil,                                │
        │   timestamp: Date(2001-01-01T00:00:00.000Z) │
        │ )                                           │
        ├─────────────────────────────────────────────┤
        │ ItemWithTimestamp(                          │
        │   item: nil,                                │
        │   timestamp: Date(2001-01-01T00:00:00.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @Test func nestedGenerated() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "rows" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT '00000000-0000-0000-0000-000000000000',
            "createdAt" TEXT NOT NULL,
            "updatedAt" TEXT NOT NULL,
            "deletedAt" TEXT,
            "isDeleted" INTEGER AS ("deletedAt" IS NOT NULL)
          )
          """
        )
      )
      let now = Date(timeIntervalSinceReferenceDate: 0)
      assertQuery(
        Row
          .insert {
            Row.Draft(timestamps: Timestamps(createdAt: now, updatedAt: now, isDeleted: false))
          }
          .returning(\.self)
      ) {
        """
        INSERT INTO "rows"
        ("id", "createdAt", "updatedAt", "deletedAt")
        VALUES
        (NULL, '2001-01-01 00:00:00.000', '2001-01-01 00:00:00.000', NULL)
        RETURNING "id", "createdAt", "updatedAt", "deletedAt", "isDeleted"
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────┐
        │ Row(                                              │
        │   id: UUID(00000000-0000-0000-0000-000000000000), │
        │   timestamps: Timestamps(                         │
        │     createdAt: Date(2001-01-01T00:00:00.000Z),    │
        │     updatedAt: Date(2001-01-01T00:00:00.000Z),    │
        │     deletedAt: nil,                               │
        │     isDeleted: false                              │
        │   )                                               │
        │ )                                                 │
        └───────────────────────────────────────────────────┘
        """
      }
    }

    @Test func primaryKey() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "metadatas" (
            "recordID" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT
              '00000000-0000-0000-0000-000000000000',
            "recordType" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'reminders',
            "userModificationDate" TEXT NOT NULL,
            PRIMARY KEY ("recordID", "recordType")
          )
          """
        )
      )
      let now = Date(timeIntervalSinceReferenceDate: 0)
      assertQuery(
        Metadata
          .insert {
            Metadata.Draft(userModificationDate: now)
          }
          .returning(\.self)
      ) {
        """
        INSERT INTO "metadatas"
        ("recordID", "recordType", "userModificationDate")
        VALUES
        (NULL, NULL, '2001-01-01 00:00:00.000')
        RETURNING "recordID", "recordType", "userModificationDate"
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Metadata(                                                 │
        │   id: MetadataID(                                         │
        │     recordID: UUID(00000000-0000-0000-0000-000000000000), │
        │     recordType: "reminders"                               │
        │   ),                                                      │
        │   userModificationDate: Date(2001-01-01T00:00:00.000Z)    │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Metadata.find(MetadataID(recordID: UUID(0), recordType: "reminders"))
      ) {
        """
        SELECT "metadatas"."recordID", "metadatas"."recordType", "metadatas"."userModificationDate"
        FROM "metadatas"
        WHERE ("metadatas"."recordID", "metadatas"."recordType") IN (('00000000-0000-0000-0000-000000000000', 'reminders'))
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Metadata(                                                 │
        │   id: MetadataID(                                         │
        │     recordID: UUID(00000000-0000-0000-0000-000000000000), │
        │     recordType: "reminders"                               │
        │   ),                                                      │
        │   userModificationDate: Date(2001-01-01T00:00:00.000Z)    │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Metadata.upsert {
          Metadata(
            id: MetadataID(recordID: UUID(0), recordType: "reminders"),
            userModificationDate: now.addingTimeInterval(1)
          )
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "metadatas"
        ("recordID", "recordType", "userModificationDate")
        VALUES
        ('00000000-0000-0000-0000-000000000000', 'reminders', '2001-01-01 00:00:01.000')
        ON CONFLICT ("recordID", "recordType")
        DO UPDATE SET "userModificationDate" = "excluded"."userModificationDate"
        RETURNING "recordID", "recordType", "userModificationDate"
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Metadata(                                                 │
        │   id: MetadataID(                                         │
        │     recordID: UUID(00000000-0000-0000-0000-000000000000), │
        │     recordType: "reminders"                               │
        │   ),                                                      │
        │   userModificationDate: Date(2001-01-01T00:00:01.000Z)    │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func `enum`() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "posts" (
            "url" TEXT,
            "note" TEXT
          )
          """
        )
      )
      assertQuery(
        Post.insert {
          Post.note("Hello world")
          Post.photo(Photo(url: URL(fileURLWithPath: "/tmp/poster.png")))
        }
      ) {
        """
        INSERT INTO "posts"
        ("url", "note")
        VALUES
        (NULL, 'Hello world'), ('file:///tmp/poster.png', NULL)
        """
      }
      assertQuery(
        Post.all
      ) {
        """
        SELECT "posts"."url", "posts"."note"
        FROM "posts"
        """
      } results: {
        """
        ┌───────────────────────────────────────────┐
        │ Post.note("Hello world")                  │
        ├───────────────────────────────────────────┤
        │ Post.photo(                               │
        │   Photo(url: URL(file:///tmp/poster.png)) │
        │ )                                         │
        └───────────────────────────────────────────┘
        """
      }
      assertQuery(
        Values(Post.Selection.note("Goodnight moon"))
      ) {
        """
        SELECT NULL, 'Goodnight moon'
        """
      } results: {
        """
        ┌─────────────────────────────┐
        │ Post.note("Goodnight moon") │
        └─────────────────────────────┘
        """
      }
    }
  }
}

@Table
private struct Item {
  var title: String
  var quantity = 0
  @Columns
  var status: Status = Status()
}

@Table("items")
private struct DefaultItem {
  var title = ""
  var quantity = 0
  @Columns
  var status: Status = Status()
}

@Table
private struct Status {
  var isOutOfStock = false
  var isOnBackOrder = false
}

@Table
private struct ItemWithTimestamp {
  @Columns
  var item: Item?
  var timestamp: Date
}

@Table
private struct Timestamps {
  var createdAt: Date
  var updatedAt: Date
  var deletedAt: Date?
  @Column(generated: .virtual)
  let isDeleted: Bool
}

@Table
private struct Row {
  let id: UUID
  @Columns
  var timestamps: Timestamps
}

@Table
private struct Metadata: Identifiable {
  @Columns
  let id: MetadataID
  var userModificationDate: Date
}

@Table
private struct MetadataID: Hashable {
  let recordID: UUID
  let recordType: String
}

@Table
private struct Photo {
  let url: URL
}

@Table
private struct Note {
  let body: String
}

// TODO: Diagnose 'enum' tables: require at most 1 associated value; ignore labels?

@CasePathable
private enum Post {
  // @Columns
  case photo(Photo)
  case note(String = "")

  // Generated:
  public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
    public typealias QueryValue = Post
    public let photo = StructuredQueriesCore.ColumnGroup<QueryValue, Photo?>(
      keyPath: \QueryValue.photo
    )
    public let note = StructuredQueriesCore.TableColumn<QueryValue, String?>(
      "note",
      keyPath: \QueryValue.note,
      default: ""
    )
    public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
      [
        StructuredQueriesCore.ColumnGroup.allColumns(keyPath: \QueryValue.photo),
        [QueryValue.columns.note],
      ].flatMap(\.self)
    }
    public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
      [
        StructuredQueriesCore.ColumnGroup.writableColumns(keyPath: \QueryValue.photo),
        [QueryValue.columns.note],
      ].flatMap(\.self)
    }
    public var queryFragment: QueryFragment {
      "\(self.photo), \(self.note)"
    }
  }

  public struct Selection: StructuredQueriesCore.TableExpression {
    public typealias QueryValue = Post
    public let allColumns: [any StructuredQueriesCore.QueryExpression]
    // TODO: Generated
    public static func photo(_ photo: some StructuredQueriesCore.QueryExpression<Photo>) -> Self {
      Self(
        allColumns: [photo._allColumns, String?(queryOutput: nil)._allColumns]
          .flatMap(\.self)
      )
    }
    public static func note(_ note: some StructuredQueriesCore.QueryExpression<String>) -> Self {
      Self(
        allColumns: [Photo?(queryOutput: nil)._allColumns, note._allColumns]
          .flatMap(\.self)
      )
    }
  }
}

nonisolated extension Post: StructuredQueriesCore.Table, StructuredQueriesCore
    .PartialSelectStatement
{
  public typealias QueryValue = Self
  public typealias From = Swift.Never
  public nonisolated static var columns: TableColumns {
    TableColumns()
  }
  public nonisolated static var columnWidth: Int {
    [Photo?.columnWidth, Note?.columnWidth].reduce(0, +)
  }
  public nonisolated static var tableName: String {
    "posts"
  }

  // TODO:
  public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
    if let photo = try decoder.decode(Photo.self) {
      self = .photo(photo)
    } else if let note = try decoder.decode(String.self) {
      self = .note(note)
    } else {
      throw QueryDecodingError.missingRequiredColumn
    }
  }
}
