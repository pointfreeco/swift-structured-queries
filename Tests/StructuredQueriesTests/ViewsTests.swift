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

    @Test func reminderWithList() {
      assertQuery(
        ReminderWithList.createTemporaryView(
          as:
            Reminder
            .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
            .select {
              ReminderWithList.Columns(
                reminderID: $0.id,
                reminderTitle: $0.title,
                remindersListTitle: $1.title
              )
            }
        )
      ) {
        """
        CREATE TEMPORARY VIEW
        "reminderWithLists"
        ("reminderID", "reminderTitle", "remindersListTitle")
        AS
        SELECT "reminders"."id" AS "reminderID", "reminders"."title" AS "reminderTitle", "remindersLists"."title" AS "remindersListTitle"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
        """
      }

      assertQuery(
        ReminderWithList.createTemporaryTrigger(
          insteadOf: .insert { new in
            Reminder.insert {
              ($0.title, $0.remindersListID)
            } values: {
              (
                new.reminderTitle,
                RemindersList
                  .select(\.id)
                  .where { $0.title.eq(new.remindersListTitle) }
              )
            }
          }
        )
      ) {
        """
        CREATE TEMPORARY TRIGGER
          "after_insert_on_reminderWithLists@StructuredQueriesTests/ViewsTests.swift:174:48"
        INSTEAD OF INSERT ON "reminderWithLists"
        FOR EACH ROW BEGIN
          INSERT INTO "reminders"
          ("title", "remindersListID")
          VALUES
          ("new"."reminderTitle", (
            SELECT "remindersLists"."id"
            FROM "remindersLists"
            WHERE ("remindersLists"."title") = ("new"."remindersListTitle")
          ));
        END
        """
      }

      assertQuery(
        ReminderWithList.insert {
          ReminderWithList.Draft(reminderTitle: "Morning sync", remindersListTitle: "Business")
        }
      ) {
        """
        INSERT INTO "reminderWithLists"
        ("reminderID", "reminderTitle", "remindersListTitle")
        VALUES
        (NULL, 'Morning sync', 'Business')
        """
      }

      assertQuery(
        ReminderWithList.insert {
          ReminderWithList.Draft(reminderTitle: "Morning sync", remindersListTitle: "Unknown List")
        }
      ) {
        """
        INSERT INTO "reminderWithLists"
        ("reminderID", "reminderTitle", "remindersListTitle")
        VALUES
        (NULL, 'Morning sync', 'Unknown List')
        """
      } results: {
        """
        NOT NULL constraint failed: reminders.remindersListID
        """
      }

      assertQuery(ReminderWithList.find(1)) {
        """
        SELECT "reminderWithLists"."reminderID", "reminderWithLists"."reminderTitle", "reminderWithLists"."remindersListTitle"
        FROM "reminderWithLists"
        WHERE ("reminderWithLists"."reminderID") IN ((1))
        """
      } results: {
        """
        ┌──────────────────────────────────┐
        │ ReminderWithList(                │
        │   reminderID: 1,                 │
        │   reminderTitle: "Groceries",    │
        │   remindersListTitle: "Personal" │
        │ )                                │
        └──────────────────────────────────┘
        """
      }

      assertQuery(
        ReminderWithList
          .order(by: { ($0.remindersListTitle, $0.reminderTitle) })
          .limit(3)
      ) {
        """
        SELECT "reminderWithLists"."reminderID", "reminderWithLists"."reminderTitle", "reminderWithLists"."remindersListTitle"
        FROM "reminderWithLists"
        ORDER BY "reminderWithLists"."remindersListTitle", "reminderWithLists"."reminderTitle"
        LIMIT 3
        """
      } results: {
        """
        ┌────────────────────────────────────────┐
        │ ReminderWithList(                      │
        │   reminderID: 9,                       │
        │   reminderTitle: "Call accountant",    │
        │   remindersListTitle: "Business"       │
        │ )                                      │
        ├────────────────────────────────────────┤
        │ ReminderWithList(                      │
        │   reminderID: 11,                      │
        │   reminderTitle: "Morning sync",       │
        │   remindersListTitle: "Business"       │
        │ )                                      │
        ├────────────────────────────────────────┤
        │ ReminderWithList(                      │
        │   reminderID: 10,                      │
        │   reminderTitle: "Send weekly emails", │
        │   remindersListTitle: "Business"       │
        │ )                                      │
        └────────────────────────────────────────┘
        """
      }
    }

    @Test func viewWithBindings() {
      assertQuery(
        PastDueReminder.createTemporaryView(
          as:
            Reminder.where(\.isPastDue)
            .select {
              PastDueReminder.Columns(
                reminderID: $0.id,
                title: $0.title
              )
            }
        )
      ) {
        """
        CREATE TEMPORARY VIEW
        "pastDueReminders"
        ("reminderID", "title")
        AS
        SELECT "reminders"."id" AS "reminderID", "reminders"."title" AS "title"
        FROM "reminders"
        WHERE (NOT ("reminders"."isCompleted")) AND (coalesce("reminders"."dueDate", date('now')) < date('now'))
        """
      }
      assertQuery(
        PastDueReminder.all
      ) {
        """
        SELECT "pastDueReminders"."reminderID", "pastDueReminders"."title"
        FROM "pastDueReminders"
        """
      } results: {
        """
        ┌─────────────────────────────────────┐
        │ PastDueReminder(                    │
        │   reminderID: 1,                    │
        │   title: "Groceries"                │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ PastDueReminder(                    │
        │   reminderID: 2,                    │
        │   title: "Haircut"                  │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ PastDueReminder(                    │
        │   reminderID: 3,                    │
        │   title: "Doctor appointment"       │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ PastDueReminder(                    │
        │   reminderID: 6,                    │
        │   title: "Pick up kids from school" │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ PastDueReminder(                    │
        │   reminderID: 8,                    │
        │   title: "Take out trash"           │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ PastDueReminder(                    │
        │   reminderID: 9,                    │
        │   title: "Call accountant"          │
        │ )                                   │
        └─────────────────────────────────────┘
        """
      }
    }
  }
}

@Table
private struct CompletedReminder {
  let reminderID: Reminder.ID
  let title: String
}

@Table
private struct PastDueReminder {
  let reminderID: Reminder.ID
  let title: String
}

@Table
private struct ReminderWithList {
  @Column(primaryKey: true)
  let reminderID: Reminder.ID
  let reminderTitle: String
  let remindersListTitle: String
}
