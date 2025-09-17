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
        as: Reminder
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
        query.drop()
      ) {
        """
        DROP VIEW "completedReminders"
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

extension Table where Self: _Selection {
  static func foo() {}
}
