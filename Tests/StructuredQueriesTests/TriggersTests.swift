import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct TriggersTests {
    @Dependency(\.defaultDatabase) var db

    @Test func basics() {
      let trigger = RemindersList.createTemporaryTrigger(
        "after_insert_on_remindersLists",
        after: .insert { new in
          RemindersList
            .update {
              $0.position = RemindersList.select { ($0.position.max() ?? -1) + 1 }
            }
            .where { $0.id.eq(new.id) }
        }
      )
      assertQuery(trigger) {
        """
        CREATE TEMPORARY TRIGGER
          "after_insert_on_remindersLists"
        AFTER INSERT ON "remindersLists"
        FOR EACH ROW BEGIN
          UPDATE "remindersLists"
          SET "position" = (
            SELECT (coalesce(max("remindersLists"."position"), -1)) + (1)
            FROM "remindersLists"
          )
          WHERE ("remindersLists"."id") = ("new"."id");
        END
        """
      }
      assertQuery(trigger.drop()) {
        """
        DROP TRIGGER "after_insert_on_remindersLists"
        """
      }
    }

    @Test func dateDiagnostic() {
      withKnownIssue {
        assertQuery(
          Reminder.createTemporaryTrigger(
            "after_update_on_reminders",
            after: .update { _, new in
              Reminder
                .update { $0.dueDate = Date(timeIntervalSinceReferenceDate: 0) }
                .where { $0.id.eq(new.id) }
            }
          )
        ) {
          """
          CREATE TEMPORARY TRIGGER
            "after_update_on_reminders"
          AFTER UPDATE ON "reminders"
          FOR EACH ROW BEGIN
            UPDATE "reminders"
            SET "dueDate" = '2001-01-01 00:00:00.000'
            WHERE ("reminders"."id") = ("new"."id");
          END
          """
        }
      } matching: {
        $0.description.contains(
          """
          Swift Date values should not be bound to a 'CREATE TEMPORARY TRIGGER' statement. Specify \
          dates using the '#sql' macro, instead. For example, the current date:

              #sql("datetime()")

          Or a constant date:

              #sql("'2018-01-29 00:08:00'")
          """
        )
      }
    }

    @Test func afterUpdateTouch() {
      assertQuery(
        RemindersList.createTemporaryTrigger(
          "after_update_on_remindersLists",
          after: .update {
            $0.position += 1
          }
        )
      ) {
        """
        CREATE TEMPORARY TRIGGER
          "after_update_on_remindersLists"
        AFTER UPDATE ON "remindersLists"
        FOR EACH ROW BEGIN
          UPDATE "remindersLists"
          SET "position" = ("remindersLists"."position") + (1)
          WHERE ("remindersLists"."rowid") = ("new"."rowid");
        END
        """
      }
    }

    @Test func afterUpdateTouchDate() {
      assertQuery(
        Reminder.createTemporaryTrigger(
          "after_update_on_reminders",
          after: .update(touch: \.updatedAt)
        )
      ) {
        """
        CREATE TEMPORARY TRIGGER
          "after_update_on_reminders"
        AFTER UPDATE ON "reminders"
        FOR EACH ROW BEGIN
          UPDATE "reminders"
          SET "updatedAt" = datetime('subsec')
          WHERE ("reminders"."rowid") = ("new"."rowid");
        END
        """
      }
    }

    @Test func afterUpdateTouchDate_NestedTimestamps() throws {
      try db.execute(
        """
        CREATE TABLE "episodes" (
          "id" INTEGER PRIMARY KEY,
          "createdAt" TEXT NOT NULL,
          "updatedAt" TEXT
        ) STRICT
        """)
      assertQuery(
        Episode.createTemporaryTrigger(
          "after_update_on_episodes",
          after: .update(touch: \.timestamps.updatedAt)
        )
      ) {
        """
        CREATE TEMPORARY TRIGGER
          "after_update_on_episodes"
        AFTER UPDATE ON "episodes"
        FOR EACH ROW BEGIN
          UPDATE "episodes"
          SET "updatedAt" = datetime('subsec')
          WHERE ("episodes"."rowid") = ("new"."rowid");
        END
        """
      }
    }

    @Test func afterUpdateTouchCustomDate() {
      assertQuery(
        Reminder.createTemporaryTrigger(
          "after_update_on_reminders",
          after: .update(touch: \.updatedAt, date: #sql("customDate()"))
        )
      ) {
        """
        CREATE TEMPORARY TRIGGER
          "after_update_on_reminders"
        AFTER UPDATE ON "reminders"
        FOR EACH ROW BEGIN
          UPDATE "reminders"
          SET "updatedAt" = customDate()
          WHERE ("reminders"."rowid") = ("new"."rowid");
        END
        """
      }
    }

    @Test func multiStatement() {
      let trigger = RemindersList.createTemporaryTrigger(
        "after_insert_on_remindersLists",
        after: .insert { new in
          RemindersList
            .update {
              $0.position = RemindersList.select { ($0.position.max() ?? -1) + 1 }
            }
            .where { $0.id.eq(new.id) }
          RemindersList
            .where { $0.position.eq(0) }
            .delete()
          RemindersList
            .select(\.position)
        }
      )
      assertQuery(trigger) {
        """
        CREATE TEMPORARY TRIGGER
          "after_insert_on_remindersLists"
        AFTER INSERT ON "remindersLists"
        FOR EACH ROW BEGIN
          UPDATE "remindersLists"
          SET "position" = (
            SELECT (coalesce(max("remindersLists"."position"), -1)) + (1)
            FROM "remindersLists"
          )
          WHERE ("remindersLists"."id") = ("new"."id");
          DELETE FROM "remindersLists"
          WHERE ("remindersLists"."position") = (0);
          SELECT "remindersLists"."position"
          FROM "remindersLists";
        END
        """
      }
    }
  }
}

@Table private struct Episode {
  let id: Int
  let timestamps: Timestamps
}
@Selection private struct Timestamps {
  let createdAt: Date
  let updatedAt: Date?
}
