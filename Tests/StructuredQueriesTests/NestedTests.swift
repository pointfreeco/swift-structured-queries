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
      // FIXME: This should decode 'nil' but because all its fields have defaults it coalesces.
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

    @Test func optionalDoubleNested() throws {
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
            PRIMARY KEY ("recordID", "recordType")
          )
          """
        )
      )
      assertQuery(
        Metadata
          .insert {
            Metadata.Draft()
          }
          .returning(\.self)
      ) {
        """
        INSERT INTO "metadatas"
        ("recordID", "recordType")
        VALUES
        (NULL, NULL)
        RETURNING "recordID", "recordType"
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ Metadata(                                                 │
        │   id: MetadataID(                                         │
        │     recordID: UUID(00000000-0000-0000-0000-000000000000), │
        │     recordType: "reminders"                               │
        │   )                                                       │
        │ )                                                         │
        └───────────────────────────────────────────────────────────┘
        """
      }
      // TODO: Make work.
      // assertQuery(
      //   Metadata.find(MetadataID(recordID: UUID(0), recordType: "reminders"))
      // )
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
  @Column(generated: .stored)
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
  @Columns/*(primaryKey: true)*/
  let id: MetadataID
}

@Table
private struct MetadataID: Hashable {
  let recordID: UUID
  let recordType: String
}
