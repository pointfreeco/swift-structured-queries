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
        Item.insert {
          Item(title: "Phone", quantity: 1, status: Status())
        }
      ) {
        """
        INSERT INTO "items"
        ("title", "quantity", "isOutOfStock", "isOnBackOrder")
        VALUES
        ('Phone', 1, 0, 0)
        """
      } results: {
        """

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
        Item.where { $0.status.eq(Status()) }
      ) {
        """
        SELECT "items"."title", "items"."quantity", "items"."isOutOfStock", "items"."isOnBackOrder"
        FROM "items"
        WHERE ("items"."isOutOfStock", "items"."isOnBackOrder") = (0, 0)
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
    }
  }
}

@Table
private struct Item {
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
