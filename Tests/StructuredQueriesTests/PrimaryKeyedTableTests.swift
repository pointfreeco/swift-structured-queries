import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import Testing

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
        SET "title" = ("reminders"."title" || '!!!')
        WHERE ("reminders"."id" = 1)
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
        SET "title" = ("reminders"."title" || '???')
        WHERE ("reminders"."id" = 1)
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
        WHERE ("reminders"."id" = 1)
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
        WHERE ("reminders"."id" = 2)
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
        WHERE ("reminders"."id" = 1)
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
        WHERE ("reminders"."id" = 2)
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
        JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")
        WHERE ("reminders"."id" = 2)
        """
      } results: {
        """
        ┌───────────┬────────────┐
        │ "Haircut" │ "Personal" │
        └───────────┴────────────┘
        """
      }
    }

    @Test func uuid() throws {
      try database.execute(
        #sql(
          """
          CREATE TABLE "rows" (id TEXT PRIMARY KEY NOT NULL)
          """
        )
      )
      try database.execute(Row.insert { Row(id: UUID(1)) })
      assertQuery(
        Row.find(UUID(1))
      ) {
        """
        SELECT "rows"."id"
        FROM "rows"
        WHERE ("rows"."id" = '00000000-0000-0000-0000-000000000001')
        """
      } results: {
        """
        ┌─────────────────────────────────────────────────────┐
        │ Row(id: UUID(00000000-0000-0000-0000-000000000001)) │
        └─────────────────────────────────────────────────────┘
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
}
