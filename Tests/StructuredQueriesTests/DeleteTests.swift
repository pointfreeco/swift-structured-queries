import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct DeleteTests {
    @Test func deleteAll() {
      assertQuery(Reminder.delete().returning(\.id)) {
        """
        DELETE FROM "reminders"
        RETURNING "reminders"."id"
        """
      } results: {
        """
        ┌────┐
        │ 1  │
        │ 2  │
        │ 3  │
        │ 4  │
        │ 5  │
        │ 6  │
        │ 7  │
        │ 8  │
        │ 9  │
        │ 10 │
        └────┘
        """
      }
      assertQuery(Reminder.count()) {
        """
        SELECT count(*)
        FROM "reminders"
        """
      } results: {
        """
        ┌───┐
        │ 0 │
        └───┘
        """
      }
    }

    @Test func deleteID1() {
      assertQuery(Reminder.delete().where { $0.id == 1 }.returning(\.self)) {
        """
        DELETE FROM "reminders"
        WHERE ("reminders"."id") = (1)
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt"
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Reminder(                                   │
        │   id: 1,                                    │
        │   assignedUserID: 1,                        │
        │   dueDate: Date(2001-01-01T00:00:00.000Z),  │
        │   isCompleted: false,                       │
        │   isFlagged: false,                         │
        │   notes: "Milk, Eggs, Apples",              │
        │   priority: nil,                            │
        │   remindersListID: 1,                       │
        │   title: "Groceries",                       │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
      assertQuery(Reminder.count()) {
        """
        SELECT count(*)
        FROM "reminders"
        """
      } results: {
        """
        ┌───┐
        │ 9 │
        └───┘
        """
      }
    }

    @Test func primaryKey() {
      assertQuery(Reminder.delete(Reminder(id: 1, remindersListID: 1))) {
        """
        DELETE FROM "reminders"
        WHERE ("reminders"."id") = (1)
        """
      }
      assertQuery(Reminder.count()) {
        """
        SELECT count(*)
        FROM "reminders"
        """
      } results: {
        """
        ┌───┐
        │ 9 │
        └───┘
        """
      }
    }

    @Test func deleteWhereKeyPath() {
      assertQuery(
        Reminder
          .delete()
          .where(\.isCompleted)
          .returning(\.title)
      ) {
        """
        DELETE FROM "reminders"
        WHERE "reminders"."isCompleted"
        RETURNING "reminders"."title"
        """
      } results: {
        """
        ┌──────────────────────┐
        │ "Take a walk"        │
        │ "Get laundry"        │
        │ "Send weekly emails" │
        └──────────────────────┘
        """
      }
    }

    @Test func aliasName() {
      enum R: AliasName {}
      assertQuery(
        RemindersList.as(R.self)
          .where { $0.id == 1 }
          .delete()
          .returning(\.self)
      ) {
        """
        DELETE FROM "remindersLists" AS "rs"
        WHERE ("rs"."id") = (1)
        RETURNING "id", "color", "title", "position"
        """
      } results: {
        """
        ┌──────────────────────┐
        │ RemindersList(       │
        │   id: 1,             │
        │   color: 4889071,    │
        │   title: "Personal", │
        │   position: 0        │
        │ )                    │
        └──────────────────────┘
        """
      }
    }

    @Test func noPrimaryKey() {
      assertInlineSnapshot(of: Item.delete(), as: .sql) {
        """
        DELETE FROM "items"
        """
      }
    }

    @Test func empty() {
      assertQuery(
        Reminder.none.delete()
      ) {
        """

        """
      }
    }
  }
}

@Table private struct Item {
  var title = ""
  var quantity = 0
}
