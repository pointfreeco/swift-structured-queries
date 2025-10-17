import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct UpdateTests {
    @Dependency(\.defaultDatabase) var db

    @Test func basics() {
      assertQuery(
        Reminder
          .update { $0.isCompleted.toggle() }
          .returning { ($0.title, $0.priority, $0.isCompleted) }
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        RETURNING "title", "priority", "isCompleted"
        """
      } results: {
        """
        ┌────────────────────────────┬─────────┬───────┐
        │ "Groceries"                │ nil     │ true  │
        │ "Haircut"                  │ nil     │ true  │
        │ "Doctor appointment"       │ .high   │ true  │
        │ "Take a walk"              │ nil     │ false │
        │ "Buy concert tickets"      │ nil     │ true  │
        │ "Pick up kids from school" │ .high   │ true  │
        │ "Get laundry"              │ .low    │ false │
        │ "Take out trash"           │ .high   │ true  │
        │ "Call accountant"          │ nil     │ true  │
        │ "Send weekly emails"       │ .medium │ false │
        └────────────────────────────┴─────────┴───────┘
        """
      }
      assertQuery(
        Reminder
          .where { $0.priority == nil }
          .update { $0.isCompleted = true }
          .returning { ($0.title, $0.priority, $0.isCompleted) }
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = 1
        WHERE ("reminders"."priority") IS (NULL)
        RETURNING "title", "priority", "isCompleted"
        """
      } results: {
        """
        ┌───────────────────────┬─────┬──────┐
        │ "Groceries"           │ nil │ true │
        │ "Haircut"             │ nil │ true │
        │ "Take a walk"         │ nil │ true │
        │ "Buy concert tickets" │ nil │ true │
        │ "Call accountant"     │ nil │ true │
        └───────────────────────┴─────┴──────┘
        """
      }
    }

    @Test func returningRepresentable() {
      assertQuery(
        Reminder
          .update { $0.isCompleted.toggle() }
          .returning(\.dueDate)
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        RETURNING "dueDate"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2001-01-01T00:00:00.000Z) │
        │ Date(2000-12-30T00:00:00.000Z) │
        │ Date(2001-01-01T00:00:00.000Z) │
        │ Date(2000-06-25T00:00:00.000Z) │
        │ nil                            │
        │ Date(2001-01-03T00:00:00.000Z) │
        │ Date(2000-12-30T00:00:00.000Z) │
        │ Date(2001-01-05T00:00:00.000Z) │
        │ Date(2001-01-03T00:00:00.000Z) │
        │ Date(2000-12-30T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
    }

    @Test func primaryKey() throws {
      var reminder = try #require(try db.execute(Reminder.all).first)
      reminder.isCompleted.toggle()
      assertQuery(
        Reminder
          .update(reminder)
          .returning(\.self)
      ) {
        """
        UPDATE "reminders"
        SET "assignedUserID" = 1, "dueDate" = '2001-01-01 00:00:00.000', "isCompleted" = 1, "isFlagged" = 0, "notes" = 'Milk, Eggs, Apples', "priority" = NULL, "remindersListID" = 1, "title" = 'Groceries', "updatedAt" = '2040-02-14 23:31:30.000'
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
        │   isCompleted: true,                        │
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
    }

    @Test func toggleAssignment() {
      assertInlineSnapshot(
        of: Reminder.update {
          $0.isCompleted = !$0.isCompleted
        },
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        """
      }
    }

    @Test func toggleBoolean() {
      assertInlineSnapshot(
        of: Reminder.update { $0.isCompleted.toggle() },
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        """
      }
    }

    @Test func multipleMutations() {
      assertInlineSnapshot(
        of: Reminder.update {
          $0.title += "!"
          $0.title += "?"
        },
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "title" = ("reminders"."title") || ('!'), "title" = ("reminders"."title") || ('?')
        """
      }
    }

    @Test func rawBind() {
      assertQuery(
        Reminder
          .update { $0.dueDate = #sql("CURRENT_TIMESTAMP") }
          .where { $0.id.eq(1) }
          .returning(\.title)
      ) {
        """
        UPDATE "reminders"
        SET "dueDate" = CURRENT_TIMESTAMP
        WHERE ("reminders"."id") = (1)
        RETURNING "title"
        """
      } results: {
        """
        ┌─────────────┐
        │ "Groceries" │
        └─────────────┘
        """
      }
    }

    @Test func updateWhereKeyPath() {
      assertQuery(
        Reminder
          .update { $0.isFlagged.toggle() }
          .where(\.isFlagged)
          .returning(\.title)
      ) {
        """
        UPDATE "reminders"
        SET "isFlagged" = NOT ("reminders"."isFlagged")
        WHERE "reminders"."isFlagged"
        RETURNING "title"
        """
      } results: {
        """
        ┌────────────────────────────┐
        │ "Haircut"                  │
        │ "Pick up kids from school" │
        └────────────────────────────┘
        """
      }
    }

    @Test func aliasName() {
      enum R: AliasName {}
      assertQuery(
        Reminder.as(R.self)
          .where { $0.id.eq(1) }
          .update { $0.title += " 2" }
          .returning(\.self)
      ) {
        """
        UPDATE "reminders" AS "rs"
        SET "title" = ("rs"."title") || (' 2')
        WHERE ("rs"."id") = (1)
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
        │   title: "Groceries 2",                     │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @Test func noPrimaryKey() {
      assertInlineSnapshot(
        of: Item.update {
          $0.title = "Dog"
        },
        as: .sql
      ) {
        """
        UPDATE "items"
        SET "title" = 'Dog'
        """
      }

    }

    @Test func emptyUpdate() {
      assertInlineSnapshot(
        of: Item.update { _ in },
        as: .sql
      ) {
        """

        """
      }
    }

    @Test func overwriteRow() throws {
      var reminder = Reminder(
        id: 100,
        remindersListID: 1,
        title: "Buy iPhone"
      )

      try db.execute(
        Reminder.insert { reminder }
      )

      try db.execute(
        Reminder.find(100).update { $0.title += " Pro" }
      )

      reminder.isCompleted = true

      // NB: This overwrites the external 'Buy iPhone Pro' update
      assertQuery(
        Reminder.update(reminder)
      ) {
        """
        UPDATE "reminders"
        SET "assignedUserID" = NULL, "dueDate" = NULL, "isCompleted" = 1, "isFlagged" = 0, "notes" = '', "priority" = NULL, "remindersListID" = 1, "title" = 'Buy iPhone', "updatedAt" = '2040-02-14 23:31:30.000'
        WHERE ("reminders"."id") = (100)
        """
      }
    }

    @Test func complexMutation() {
      let updateQuery =
        Reminder
        .find(1)
        .update {
          $0.dueDate = Case()
            .when($0.dueDate == nil, then: #sql("'2018-01-29 00:08:00.000'"))
        }

      assertQuery(
        updateQuery
          .returning(\.dueDate)
      ) {
        """
        UPDATE "reminders"
        SET "dueDate" = CASE WHEN ("reminders"."dueDate") IS (NULL) THEN '2018-01-29 00:08:00.000' END
        WHERE ("reminders"."id") IN ((1))
        RETURNING "dueDate"
        """
      } results: {
        """
        ┌─────┐
        │ nil │
        └─────┘
        """
      }

      assertQuery(
        updateQuery
          .returning(\.dueDate)
      ) {
        """
        UPDATE "reminders"
        SET "dueDate" = CASE WHEN ("reminders"."dueDate") IS (NULL) THEN '2018-01-29 00:08:00.000' END
        WHERE ("reminders"."id") IN ((1))
        RETURNING "dueDate"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2018-01-29T00:08:00.000Z) │
        └────────────────────────────────┘
        """
      }
    }

    @Test func empty() {
      assertQuery(
        Reminder.none.update { $0.isCompleted.toggle() }
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
