import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct NestedTableTests {
    @Dependency(\.defaultDatabase) var db

    @Test func basics() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "items" (
            "title" TEXT NOT NULL DEFAULT '',
            "quantity" INTEGER NOT NULL DEFAULT 0,
            "isCompleted" INTEGER NOT NULL DEFAULT 0,
            "isPastDue" INTEGER NOT NULL DEFAULT 0
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          INSERT INTO "items"
            ("title", "quantity", "isCompleted", "isPastDue")
          VALUES
            ('Hello', 42, 1, 0)
          """
        )
      )
      assertQuery(
        Item.insert {
          Item(
            title: "Hello",
            quantity: 24,
            someColumns: SomeColumns(isCompleted: true, isPastDue: false)
          )
        }
      ) {
        """
        INSERT INTO "items"
        ("title", "quantity", "isCompleted", "isPastDue")
        VALUES
        ('Hello', 24, 1, 0)
        """
      }
      assertQuery(
        Item.insert {
          ($0.title, $0.quantity, $0.someColumns.isCompleted, $0.someColumns.isPastDue)
        } values: {
          ("Blob", 42, false, false)
        }
      ) {
        """
        INSERT INTO "items"
        ("title", "quantity", "isCompleted", "isPastDue")
        VALUES
        ('Blob', 42, 0, 0)
        """
      }
      assertQuery(
        Item
          // TODO: Should use 'is' and 'is' should not require optionality?
          // TODO: Should '==' just always use 'IS'?
          .select { ($0, $0.someColumns.eq(SomeColumns())) }
          .where(\.someColumns.isCompleted)
          .group(by: \.someColumns.isCompleted)
          .having(\.someColumns.isCompleted)
          .order(by: \.someColumns.isCompleted)
      ) {
        """
        SELECT "items"."title", "items"."quantity", "items"."isCompleted", "items"."isPastDue", (("items"."isCompleted", "items"."isPastDue") = (0, 0))
        FROM "items"
        WHERE "items"."isCompleted"
        GROUP BY "items"."isCompleted"
        HAVING "items"."isCompleted"
        ORDER BY "items"."isCompleted"
        """
      }results: {
        """
        ┌─────────────────────────────┬───────┐
        │ Item(                       │ false │
        │   title: "Hello",           │       │
        │   quantity: 42,             │       │
        │   someColumns: SomeColumns( │       │
        │     isCompleted: true,      │       │
        │     isPastDue: false        │       │
        │   )                         │       │
        │ )                           │       │
        └─────────────────────────────┴───────┘
        """
      }
      assertQuery(
        Item
          .where {
            $0.eq(
              Item(
                title: "Hello",
                quantity: 42,
                someColumns: SomeColumns(isCompleted: true, isPastDue: false)
              )
            )
          }
      ) {
        """
        SELECT "items"."title", "items"."quantity", "items"."isCompleted", "items"."isPastDue"
        FROM "items"
        WHERE (("items"."title", "items"."quantity", "items"."isCompleted", "items"."isPastDue") = ('Hello', 42, 1, 0))
        """
      } results: {
        """
        ┌─────────────────────────────┐
        │ Item(                       │
        │   title: "Hello",           │
        │   quantity: 42,             │
        │   someColumns: SomeColumns( │
        │     isCompleted: true,      │
        │     isPastDue: false        │
        │   )                         │
        │ )                           │
        └─────────────────────────────┘
        """
      }
      assertQuery(
        SomeColumns.all
      ) {
        """
        SELECT "items"."isCompleted", "items"."isPastDue"
        FROM "items"
        """
      } results: {
        """
        ┌───────────────────────┐
        │ SomeColumns(          │
        │   isCompleted: true,  │
        │   isPastDue: false    │
        │ )                     │
        ├───────────────────────┤
        │ SomeColumns(          │
        │   isCompleted: true,  │
        │   isPastDue: false    │
        │ )                     │
        ├───────────────────────┤
        │ SomeColumns(          │
        │   isCompleted: false, │
        │   isPastDue: false    │
        │ )                     │
        └───────────────────────┘
        """
      }
      assertQuery(
        Item
          .update {
            $0.someColumns.isCompleted.toggle()
            $0.someColumns.isPastDue.toggle()
          }
          .returning(\.self)
      ) {
        """
        UPDATE "items"
        SET "isCompleted" = NOT ("items"."isCompleted"), "isPastDue" = NOT ("items"."isPastDue")
        RETURNING "title", "quantity", "isCompleted", "isPastDue"
        """
      } results: {
        """
        ┌─────────────────────────────┐
        │ Item(                       │
        │   title: "Hello",           │
        │   quantity: 42,             │
        │   someColumns: SomeColumns( │
        │     isCompleted: false,     │
        │     isPastDue: true         │
        │   )                         │
        │ )                           │
        ├─────────────────────────────┤
        │ Item(                       │
        │   title: "Hello",           │
        │   quantity: 24,             │
        │   someColumns: SomeColumns( │
        │     isCompleted: false,     │
        │     isPastDue: true         │
        │   )                         │
        │ )                           │
        ├─────────────────────────────┤
        │ Item(                       │
        │   title: "Blob",            │
        │   quantity: 42,             │
        │   someColumns: SomeColumns( │
        │     isCompleted: true,      │
        │     isPastDue: true         │
        │   )                         │
        │ )                           │
        └─────────────────────────────┘
        """
      }
      assertQuery(
        SomeColumns
          .update {
            $0.isCompleted.toggle()
            $0.isPastDue.toggle()
          }
          .returning(\.self)
      ) {
        """
        UPDATE "items"
        SET "isCompleted" = NOT ("items"."isCompleted"), "isPastDue" = NOT ("items"."isPastDue")
        RETURNING "isCompleted", "isPastDue"
        """
      } results: {
        """
        ┌───────────────────────┐
        │ SomeColumns(          │
        │   isCompleted: true,  │
        │   isPastDue: false    │
        │ )                     │
        ├───────────────────────┤
        │ SomeColumns(          │
        │   isCompleted: true,  │
        │   isPastDue: false    │
        │ )                     │
        ├───────────────────────┤
        │ SomeColumns(          │
        │   isCompleted: false, │
        │   isPastDue: false    │
        │ )                     │
        └───────────────────────┘
        """
      }
      assertQuery(
        Item
          .where(\.someColumns.isCompleted)
          .delete()
          .returning(\.self)
      ) {
        """
        DELETE FROM "items"
        WHERE "items"."isCompleted"
        RETURNING "title", "quantity", "isCompleted", "isPastDue"
        """
      } results: {
        """
        ┌─────────────────────────────┐
        │ Item(                       │
        │   title: "Hello",           │
        │   quantity: 42,             │
        │   someColumns: SomeColumns( │
        │     isCompleted: true,      │
        │     isPastDue: false        │
        │   )                         │
        │ )                           │
        ├─────────────────────────────┤
        │ Item(                       │
        │   title: "Hello",           │
        │   quantity: 24,             │
        │   someColumns: SomeColumns( │
        │     isCompleted: true,      │
        │     isPastDue: false        │
        │   )                         │
        │ )                           │
        └─────────────────────────────┘
        """
      }
    }
  }
}

// @Table
// private struct Item {
//   var title = ""
//   var quantity = 0
//   // @Columns
//   var someColumns: SomeColumns = SomeColumns()
// }
//
// @Table("items")  // @Table(Item.self)
// private struct SomeColumns {
//   var isCompleted = false
//   var isPastDue = false
// }

/*
@Table
private struct Item {
  var title = ""
  var quantity = 0
  var someColumns: SomeColumns = SomeColumns()

  @Columns
  struct SomeColumns {
    var isCompleted = false
    var isPastDue = false
  }
}
 */

private struct Item {
  public typealias QueryValue = Self

  var title = ""
  var quantity = 0
  var someColumns: SomeColumns = SomeColumns()

  public struct TableColumns: StructuredQueriesCore.TableDefinition {
    public typealias QueryValue = Item
    public let title = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>(
      "title",
      keyPath: \QueryValue.title,
      default: ""
    )
    public let quantity = StructuredQueriesCore.TableColumn<QueryValue, Swift.Int>(
      "quantity",
      keyPath: \QueryValue.quantity,
      default: 0
    )
    public let someColumns = SubtableColumns(keyPath: \QueryValue.someColumns)
    public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
      [QueryValue.columns.title]
        + [QueryValue.columns.quantity]
        + SubtableColumns.allColumns(keyPath: \QueryValue.someColumns)
    }
    public var queryFragment: QueryFragment {
      "\(self.title), \(self.quantity), \(self.someColumns)"
    }
  }
}

extension Item: StructuredQueriesCore.Table {
  public static let columns = TableColumns()
  public static let tableName = "items"
  var queryFragment: StructuredQueriesCore.QueryFragment {
    "\(self.title.queryFragment), \(self.quantity.queryFragment), \(self.someColumns.queryFragment)"
  }
  public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
    self.title = try decoder.decode(Swift.String.self) ?? ""
    self.quantity = try decoder.decode(Swift.Int.self) ?? 0
    self.someColumns = try decoder.decode(SomeColumns.self) ?? SomeColumns()
  }
}

private struct SomeColumns {
  public typealias QueryValue = Self

  var isCompleted = false
  var isPastDue = false

  public struct TableColumns: StructuredQueriesCore.TableDefinition {
    public typealias QueryValue = SomeColumns
    public let isCompleted = StructuredQueriesCore.TableColumn<QueryValue, Swift.Bool>(
      "isCompleted",
      keyPath: \QueryValue.isCompleted,
      default: false
    )
    public let isPastDue = StructuredQueriesCore.TableColumn<QueryValue, Swift.Bool>(
      "isPastDue",
      keyPath: \QueryValue.isPastDue,
      default: false
    )
    public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
      [QueryValue.columns.isCompleted, QueryValue.columns.isPastDue]
    }
    public var queryFragment: QueryFragment {
      "\(self.isCompleted), \(self.isPastDue)"
    }
  }
}

extension SomeColumns: StructuredQueriesCore.Table {
  public static let columns = TableColumns()
  public static let tableName = "items"
  var queryFragment: StructuredQueriesCore.QueryFragment {
    "\(self.isCompleted.queryFragment), \(self.isPastDue.queryFragment)"
  }
  public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
    self.isCompleted = try decoder.decode(Swift.Bool.self) ?? false
    self.isPastDue = try decoder.decode(Swift.Bool.self) ?? false
  }
}
