import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct ViewsTests {
    @Test func basics() {
      let query = CompletedReminder.createTemporaryView(
        as:
          Reminder
          .where(\.isCompleted)
          .select { CompletedReminder.Columns(reminderID: $0.id, title: $0.title) }
      )
      assertQuery(
        query
      ) {
        """
        CREATE TEMPORARY VIEW
        "completedReminders"
        ("reminderID", "title")
        AS
        SELECT "reminders"."id" AS "reminderID", "reminders"."title" AS "title"
        FROM "reminders"
        WHERE "reminders"."isCompleted"
        """
      } results: {
        """

        """
      }
      assertQuery(
        CompletedReminder.limit(2)
      ) {
        """
        SELECT "completedReminders"."reminderID", "completedReminders"."title"
        FROM "completedReminders"
        LIMIT 2
        """
      } results: {
        """
        ┌────────────────────────┐
        │ CompletedReminder(     │
        │   reminderID: 4,       │
        │   title: "Take a walk" │
        │ )                      │
        ├────────────────────────┤
        │ CompletedReminder(     │
        │   reminderID: 7,       │
        │   title: "Get laundry" │
        │ )                      │
        └────────────────────────┘
        """
      }
      assertQuery(
        CompletedReminder.createTemporaryTrigger(
          insteadOf: .insert { new in
            Reminder.insert {
              ($0.title, $0.isCompleted, $0.remindersListID)
            } values: {
              (new.title, true, 1)
            }
          }
        )
      ) {
        """
        CREATE TEMPORARY TRIGGER
          "after_insert_on_completedReminders@StructuredQueriesTests/ViewsTests.swift:58:49"
        INSTEAD OF INSERT ON "completedReminders"
        FOR EACH ROW BEGIN
          INSERT INTO "reminders"
          ("title", "isCompleted", "remindersListID")
          VALUES
          ("new"."title", 1, 1);
        END
        """
      }
      assertQuery(
        CompletedReminder.insert(\.title) { "Already done" }
      ) {
        """
        INSERT INTO "completedReminders"
        ("title")
        VALUES
        ('Already done')
        """
      }
      // NB: Can't use 'RETURNING' above due to a SQLite bug where 'reminderID' is 'NULL'.
      assertQuery(
        CompletedReminder.order { $0.reminderID.desc() }.limit(1)
      ) {
        """
        SELECT "completedReminders"."reminderID", "completedReminders"."title"
        FROM "completedReminders"
        ORDER BY "completedReminders"."reminderID" DESC
        LIMIT 1
        """
      } results: {
        """
        ┌─────────────────────────┐
        │ CompletedReminder(      │
        │   reminderID: 11,       │
        │   title: "Already done" │
        │ )                       │
        └─────────────────────────┘
        """
      }
      assertQuery(
        query.drop()
      ) {
        """
        DROP VIEW "completedReminders"
        """
      }
    }

    @Test func ctes() {
      assertQuery(
        CompletedReminder.createTemporaryView(
          as: With {
            Reminder
              .where(\.isCompleted)
              .select { CompletedReminder.Columns(reminderID: $0.id, title: $0.title) }
          } query: {
            CompletedReminder.all
          }
        )
      ) {
        """
        CREATE TEMPORARY VIEW
        "completedReminders"
        ("reminderID", "title")
        AS
        WITH "completedReminders" AS (
          SELECT "reminders"."id" AS "reminderID", "reminders"."title" AS "title"
          FROM "reminders"
          WHERE "reminders"."isCompleted"
        )
        SELECT "completedReminders"."reminderID", "completedReminders"."title"
        FROM "completedReminders"
        """
      }
    }
  }
}

@Table @Selection
private struct CompletedReminder {
  let reminderID: Reminder.ID
  let title: String
}
