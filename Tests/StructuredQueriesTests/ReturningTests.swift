import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct ReturningTests {
    @Test func insertExpressions() {
      assertQuery(
        Reminder
          .insert { Reminder.Draft(remindersListID: 1, title: "Check email") }
          .returning { ($0.id, $0.title.upper(), $0.isCompleted || $0.isFlagged) }
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check email', '2040-02-14 23:31:30.000')
        RETURNING "id", upper("reminders"."title"), ("reminders"."isCompleted") OR ("reminders"."isFlagged")
        """
      } results: {
        """
        ┌────┬───────────────┬───────┐
        │ 11 │ "CHECK EMAIL" │ false │
        └────┴───────────────┴───────┘
        """
      }
    }

    @Test func updateExpressions() {
      assertQuery(
        Reminder
          .where { $0.id.eq(1) }
          .update { $0.title += "!" }
          .returning { ($0.title, $0.title.length(), $0.priority.ifnull(Priority.low)) }
      ) {
        """
        UPDATE "reminders"
        SET "title" = ("reminders"."title") || ('!')
        WHERE (("reminders"."id") = (1))
        RETURNING "title", length("reminders"."title"), ifnull("reminders"."priority", 1)
        """
      } results: {
        """
        ┌──────────────┬────┬──────────────┐
        │ "Groceries!" │ 10 │ Priority.low │
        └──────────────┴────┴──────────────┘
        """
      }
    }

    @Test func deleteExpression() {
      assertQuery(
        Reminder
          .where { $0.id.eq(1) }
          .delete()
          .returning { $0.title.lower() }
      ) {
        """
        DELETE FROM "reminders"
        WHERE (("reminders"."id") = (1))
        RETURNING lower("reminders"."title")
        """
      } results: {
        """
        ┌─────────────┐
        │ "groceries" │
        └─────────────┘
        """
      }
    }

    @Test func selection() {
      assertQuery(
        Reminder
          .where { $0.id.eq(1) }
          .delete()
          .returning {
            ReminderTitleAndLength.Columns(title: $0.title.upper(), length: $0.title.length())
          }
      ) {
        """
        DELETE FROM "reminders"
        WHERE (("reminders"."id") = (1))
        RETURNING upper("reminders"."title") AS "title", length("reminders"."title") AS "length"
        """
      } results: {
        """
        ┌─────────────────────────┐
        │ ReminderTitleAndLength( │
        │   title: "GROCERIES",   │
        │   length: 9             │
        │ )                       │
        └─────────────────────────┘
        """
      }
    }

    @Test func subquery() {
      assertQuery(
        Reminder
          .where { $0.id.eq(2) }
          .delete()
          .returning { reminder in
            (
              reminder.id,
              RemindersList
                .where { $0.id.eq(reminder.id) }
                .select(\.title)
            )
          }
      ) {
        """
        DELETE FROM "reminders"
        WHERE (("reminders"."id") = (2))
        RETURNING "id", (
          SELECT "remindersLists"."title"
          FROM "remindersLists"
          WHERE (("remindersLists"."id") = ("reminders"."id"))
        )
        """
      } results: {
        """
        ┌───┬──────────┐
        │ 2 │ "Family" │
        └───┴──────────┘
        """
      }
    }

    @Test func rawExpression() {
      assertQuery(
        Reminder
          .where { $0.id.eq(1) }
          .delete()
          .returning { (#sql("\($0.id) + 1", as: Int.self), #sql("\($0.title)", as: String.self)) }
      ) {
        """
        DELETE FROM "reminders"
        WHERE (("reminders"."id") = (1))
        RETURNING "reminders"."id" + 1, "reminders"."title"
        """
      } results: {
        """
        ┌───┬─────────────┐
        │ 2 │ "Groceries" │
        └───┴─────────────┘
        """
      }
    }

    @Test func aliasedTable() {
      enum R: AliasName {}
      assertQuery(
        Reminder.as(R.self)
          .where { $0.id.eq(1) }
          .update { $0.title += "!" }
          .returning { ($0.id, $0.title.upper()) }
      ) {
        """
        UPDATE "reminders" AS "rs"
        SET "title" = ("rs"."title") || ('!')
        WHERE (("rs"."id") = (1))
        RETURNING "id", upper("reminders"."title")
        """
      } results: {
        """
        ┌───┬──────────────┐
        │ 1 │ "GROCERIES!" │
        └───┴──────────────┘
        """
      }
      assertQuery(
        Reminder.as(R.self)
          .where { $0.id.eq(1) }
          .delete()
          .returning { reminder in
            RemindersList
              .where { $0.id.eq(reminder.remindersListID) }
              .select(\.title)
          }
      ) {
        """
        DELETE FROM "reminders" AS "rs"
        WHERE (("rs"."id") = (1))
        RETURNING (
          SELECT "remindersLists"."title"
          FROM "remindersLists"
          WHERE (("remindersLists"."id") = ("reminders"."remindersListID"))
        )
        """
      } results: {
        """
        ┌────────────┐
        │ "Personal" │
        └────────────┘
        """
      }
    }

    @Test func schemaQualifiedTable() {
      assertQuery(
        SchemaReminder
          .where { $0.id.eq(1) }
          .update { $0.remindersListID += 1 }
          .returning { ($0.id, $0.remindersListID + 1) }
      ) {
        """
        UPDATE "main"."reminders"
        SET "remindersListID" = ("main"."reminders"."remindersListID") + (1)
        WHERE (("main"."reminders"."id") = (1))
        RETURNING "id", ("reminders"."remindersListID") + (1)
        """
      } results: {
        """
        ┌───┬───┐
        │ 1 │ 3 │
        └───┴───┘
        """
      }
    }

    @Test func genericPrimaryKey() {
      func deleteReturningPrimaryKey<T: PrimaryKeyedTable>(
        _ table: T.Type
      ) -> Delete<T, T.PrimaryKey> {
        T.delete().returning(\.primaryKey)
      }
      assertQuery(deleteReturningPrimaryKey(RemindersList.self).where { $0.id.eq(3) }) {
        """
        DELETE FROM "remindersLists"
        WHERE (("remindersLists"."id") = (3))
        RETURNING "id"
        """
      } results: {
        """
        ┌───┐
        │ 3 │
        └───┘
        """
      }
    }

    @Test func empty() {
      assertQuery(
        Reminder
          .where { $0.id.eq(1) }
          .delete()
          .returning { _ in () }
      ) {
        """
        DELETE FROM "reminders"
        WHERE (("reminders"."id") = (1))
        """
      }
    }
  }
}

@Selection
private struct ReminderTitleAndLength {
  let title: String
  let length: Int
}

@Table("reminders", schema: "main")
private struct SchemaReminder {
  let id: Int
  var remindersListID: Int
}
