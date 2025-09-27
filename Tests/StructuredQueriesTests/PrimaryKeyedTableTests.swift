import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  struct PrimaryKeyedTableTests {
    @Dependency(\.defaultDatabase) var database

    @Test func count() {
      assertQuery(Reminder.select { $0.count() }) {
        """
        SELECT count("reminders"."id")
        FROM "reminders"
        """
      } results: {
        """
        ┌────┐
        │ 10 │
        └────┘
        """
      }
    }

    @Test func updateByID() {
      assertQuery(
        Reminder.find(1).update { $0.title += "!!!" }
          .returning(\.title)
      ) {
        """
        UPDATE "reminders"
        SET "title" = ("reminders"."title") || ('!!!')
        WHERE ("reminders"."id") IN ((1))
        RETURNING "title"
        """
      } results: {
        """
        ┌────────────────┐
        │ "Groceries!!!" │
        └────────────────┘
        """
      }

      assertQuery(
        Reminder.update { $0.title += "???" }.find(1)
          .returning(\.title)
      ) {
        """
        UPDATE "reminders"
        SET "title" = ("reminders"."title") || ('???')
        WHERE ("reminders"."id") IN ((1))
        RETURNING "title"
        """
      } results: {
        """
        ┌───────────────────┐
        │ "Groceries!!!???" │
        └───────────────────┘
        """
      }
    }

    @Test func deleteByID() {
      assertQuery(
        Reminder.find(1).delete()
          .returning(\.id)
      ) {
        """
        DELETE FROM "reminders"
        WHERE ("reminders"."id") IN ((1))
        RETURNING "reminders"."id"
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        └───┘
        """
      }

      assertQuery(
        Reminder.delete().find(2)
          .returning(\.id)
      ) {
        """
        DELETE FROM "reminders"
        WHERE ("reminders"."id") IN ((2))
        RETURNING "reminders"."id"
        """
      } results: {
        """
        ┌───┐
        │ 2 │
        └───┘
        """
      }
    }

    @Test func findByID() {
      assertQuery(
        Reminder.find(1).select { ($0.id, $0.title) }
      ) {
        """
        SELECT "reminders"."id", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."id") IN ((1))
        """
      } results: {
        """
        ┌───┬─────────────┐
        │ 1 │ "Groceries" │
        └───┴─────────────┘
        """
      }

      assertQuery(
        Reminder.Draft.find(1).select { ($0.id, $0.title) }
      ) {
        """
        SELECT "reminders"."id", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."id") IN ((1))
        """
      } results: {
        """
        ┌───┬─────────────┐
        │ 1 │ "Groceries" │
        └───┴─────────────┘
        """
      }

      assertQuery(
        Reminder.select { ($0.id, $0.title) }.find(2)
      ) {
        """
        SELECT "reminders"."id", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."id") IN ((2))
        """
      } results: {
        """
        ┌───┬───────────┐
        │ 2 │ "Haircut" │
        └───┴───────────┘
        """
      }

      assertQuery(
        Reminder.select { ($0.id, $0.title) }.find([2, 4, 6])
      ) {
        """
        SELECT "reminders"."id", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."id") IN ((2), (4), (6))
        """
      } results: {
        """
        ┌───┬────────────────────────────┐
        │ 2 │ "Haircut"                  │
        │ 4 │ "Take a walk"              │
        │ 6 │ "Pick up kids from school" │
        └───┴────────────────────────────┘
        """
      }

      assertQuery(
        Reminder.select { ($0.id, $0.title) }.find(Reminder.select(\.id))
      ) {
        """
        SELECT "reminders"."id", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."id") IN (((
          SELECT "reminders"."id"
          FROM "reminders"
        )))
        """
      } results: {
        """
        ┌────┬────────────────────────────┐
        │ 1  │ "Groceries"                │
        │ 2  │ "Haircut"                  │
        │ 3  │ "Doctor appointment"       │
        │ 4  │ "Take a walk"              │
        │ 5  │ "Buy concert tickets"      │
        │ 6  │ "Pick up kids from school" │
        │ 7  │ "Get laundry"              │
        │ 8  │ "Take out trash"           │
        │ 9  │ "Call accountant"          │
        │ 10 │ "Send weekly emails"       │
        └────┴────────────────────────────┘
        """
      }

      assertQuery(
        Reminder.Draft.select { ($0.id, $0.title) }.find(2)
      ) {
        """
        SELECT "reminders"."id", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."id") IN ((2))
        """
      } results: {
        """
        ┌───┬───────────┐
        │ 2 │ "Haircut" │
        └───┴───────────┘
        """
      }
    }

    @Test func findByIDWithJoin() {
      assertQuery(
        Reminder
          .join(RemindersList.all) { $0.remindersListID == $1.id }
          .select { ($0.title, $1.title) }
          .find(2)
      ) {
        """
        SELECT "reminders"."title", "remindersLists"."title"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
        WHERE ("reminders"."id") IN ((2))
        """
      } results: {
        """
        ┌───────────┬────────────┐
        │ "Haircut" │ "Personal" │
        └───────────┴────────────┘
        """
      }
    }

    @Test func uuidAndGeneratedColumn() throws {
      try database.execute(
        #sql(
          """
          CREATE TABLE "rows" (
            "id" TEXT PRIMARY KEY NOT NULL,
            "isDeleted" INTEGER NOT NULL DEFAULT 0,
            "isNotDeleted" INTEGER NOT NULL AS (NOT "isDeleted")
          )
          """
        )
      )
      assertQuery(
        Row.insert { Row.Draft(id: UUID(1)) }
      ) {
        """
        INSERT INTO "rows"
        ("id", "isDeleted")
        VALUES
        ('00000000-0000-0000-0000-000000000001', 0)
        """
      }
      assertQuery(
        Row.find(UUID(1))
      ) {
        """
        SELECT "rows"."id", "rows"."isDeleted", "rows"."isNotDeleted"
        FROM "rows"
        WHERE ("rows"."id") IN (('00000000-0000-0000-0000-000000000001'))
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────┐
        │ Row(                                              │
        │   id: UUID(00000000-0000-0000-0000-000000000001), │
        │   isDeleted: false,                               │
        │   isNotDeleted: true                              │
        │ )                                                 │
        └───────────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Row.insert {
          $0.id
        } values: {
          UUID(2)
        }.returning(\.self)
      ) {
        """
        INSERT INTO "rows"
        ("id")
        VALUES
        ('00000000-0000-0000-0000-000000000002')
        RETURNING "id", "isDeleted", "isNotDeleted"
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────┐
        │ Row(                                              │
        │   id: UUID(00000000-0000-0000-0000-000000000002), │
        │   isDeleted: false,                               │
        │   isNotDeleted: true                              │
        │ )                                                 │
        └───────────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Row
          .update(Row(id: UUID(2), isDeleted: true, isNotDeleted: false))
          .returning(\.self)
      ) {
        """
        UPDATE "rows"
        SET "isDeleted" = 1
        WHERE ("rows"."id") = ('00000000-0000-0000-0000-000000000002')
        RETURNING "id", "isDeleted", "isNotDeleted"
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────┐
        │ Row(                                              │
        │   id: UUID(00000000-0000-0000-0000-000000000002), │
        │   isDeleted: true,                                │
        │   isNotDeleted: false                             │
        │ )                                                 │
        └───────────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Row
          .upsert { Row.Draft(id: UUID(2), isDeleted: false) }
          .returning(\.self)
      ) {
        """
        INSERT INTO "rows"
        ("id", "isDeleted")
        VALUES
        ('00000000-0000-0000-0000-000000000002', 0)
        ON CONFLICT ("id")
        DO UPDATE SET "isDeleted" = "excluded"."isDeleted"
        RETURNING "id", "isDeleted", "isNotDeleted"
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────┐
        │ Row(                                              │
        │   id: UUID(00000000-0000-0000-0000-000000000002), │
        │   isDeleted: false,                               │
        │   isNotDeleted: true                              │
        │ )                                                 │
        └───────────────────────────────────────────────────┘
        """
      }
      enum R: AliasName {}
      assertQuery(
        Row.as(R.self).select(\.isNotDeleted)
      ) {
        """
        SELECT "rs"."isNotDeleted"
        FROM "rows" AS "rs"
        """
      } results: {
        """
        ┌──────┐
        │ true │
        │ true │
        └──────┘
        """
      }
    }

    @Test func joinWith() {
      // RemindersList.join(Reminder.all, with: \.remindersListID)
      // Reminder.join(RemindersList.all, with: \.remindersListID)
    }
  }
}

@Table
private struct Row {
  let id: UUID
  var isDeleted = false
  @Column(generated: .virtual)
  let isNotDeleted: Bool
}
