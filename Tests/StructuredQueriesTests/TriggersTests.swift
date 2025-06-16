import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import Testing

extension SnapshotTests {
  @Suite struct TriggersTests {
    @Test func basics() {
      assertQuery(
        RemindersList.createTemporaryTrigger(
          after: .insert { new in
            RemindersList
              .update {
                $0.position = RemindersList.select { ($0.position.max() ?? -1) + 1 }
              }
              .where { $0.id.eq(new.id) }
          }
        )
      ) {
        """
        CREATE TEMPORARY TRIGGER
          "after_insert_on_remindersLists@StructuredQueriesTests/TriggersTests.swift:12:45"
        AFTER INSERT ON "remindersLists"
        FOR EACH ROW BEGIN
          UPDATE "remindersLists"
          SET "position" = (
            SELECT (coalesce(max("remindersLists"."position"), -1) + 1)
            FROM "remindersLists"
          )
          WHERE ("remindersLists"."id" = "new"."id");
        END
        """
      }
    }

    @Test func dateDiagnostic() {
      withKnownIssue {
        assertQuery(
          Reminder.createTemporaryTrigger(
            after: .update { _, new in
              Reminder
                .update { $0.dueDate = Date(timeIntervalSinceReferenceDate: 0) }
                .where { $0.id.eq(new.id) }
            }
          )
        ) {
          """
          CREATE TEMPORARY TRIGGER
            "after_update_on_reminders@StructuredQueriesTests/TriggersTests.swift:41:42"
          AFTER UPDATE ON "reminders"
          FOR EACH ROW BEGIN
            UPDATE "reminders"
            SET "dueDate" = '2001-01-01 00:00:00.000'
            WHERE ("reminders"."id" = "new"."id");
          END
          """
        }
      } matching: {
        $0.description.contains(
          """
          Cannot bind a date to a trigger statement. Specify dates using the '#sql' macro, \
          instead. For example, the current date:

              #sql("datetime()")

          Or a constant date:

              #sql("'2018-01-29 00:08:00'")
          """
        )
      }
    }
  }
}
