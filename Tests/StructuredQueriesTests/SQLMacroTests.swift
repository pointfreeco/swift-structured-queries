import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing

extension SnapshotTests {
  @Suite struct SQLMacroTests {
    @Test func rawSelect() {
      assertQuery(
        #sql(
          """
          SELECT \(Reminder.columns)
          FROM \(Reminder.self)
          ORDER BY \(Reminder.id)
          LIMIT 1
          """,
          as: Reminder.self
        )
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "reminders"
        ORDER BY "reminders"."id"
        LIMIT 1
        """
      } results: {
        """
        ┌────────────────────────────────────────────┐
        │ Reminder(                                  │
        │   id: 1,                                   │
        │   assignedUserID: 1,                       │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │
        │   isCompleted: false,                      │
        │   isFlagged: false,                        │
        │   notes: "Milk, Eggs, Apples",             │
        │   priority: nil,                           │
        │   remindersListID: 1,                      │
        │   title: "Groceries"                       │
        │ )                                          │
        └────────────────────────────────────────────┘
        """
      }
    }

    @Test func join() {
      assertQuery(
        #sql(
          """
          SELECT
            \(Reminder.columns),
            \(RemindersList.columns)
          FROM \(Reminder.self)
          JOIN \(RemindersList.self)
            ON \(Reminder.remindersListID) = \(RemindersList.id)
          LIMIT 1
          """,
          as: (Reminder, RemindersList).self
        )
      ) {
        """
        SELECT
          "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title",
          "remindersLists"."id", "remindersLists"."color", "remindersLists"."name"
        FROM "reminders"
        JOIN "remindersLists"
          ON "reminders"."remindersListID" = "remindersLists"."id"
        LIMIT 1
        """
      } results: {
        """
        ┌────────────────────────────────────────────┬────────────────────┐
        │ Reminder(                                  │ RemindersList(     │
        │   id: 1,                                   │   id: 1,           │
        │   assignedUserID: 1,                       │   color: 4889071,  │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │   name: "Personal" │
        │   isCompleted: false,                      │ )                  │
        │   isFlagged: false,                        │                    │
        │   notes: "Milk, Eggs, Apples",             │                    │
        │   priority: nil,                           │                    │
        │   remindersListID: 1,                      │                    │
        │   title: "Groceries"                       │                    │
        │ )                                          │                    │
        └────────────────────────────────────────────┴────────────────────┘
        """
      }
    }

    @Test func selection() {
      assertQuery(
        #sql(
          """
          SELECT \(Reminder.columns), \(RemindersList.columns) 
          FROM \(Reminder.self) \
          JOIN \(RemindersList.self) \
          ON \(Reminder.remindersListID) = \(RemindersList.id) \
          LIMIT 1
          """,
          as: ReminderWithList.self
        )
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "remindersLists"."id", "remindersLists"."color", "remindersLists"."name" 
        FROM "reminders" JOIN "remindersLists" ON "reminders"."remindersListID" = "remindersLists"."id" LIMIT 1
        """
      } results: {
        """
        ┌──────────────────────────────────────────────┐
        │ ReminderWithList(                            │
        │   reminder: Reminder(                        │
        │     id: 1,                                   │
        │     assignedUserID: 1,                       │
        │     dueDate: Date(2001-01-01T00:00:00.000Z), │
        │     isCompleted: false,                      │
        │     isFlagged: false,                        │
        │     notes: "Milk, Eggs, Apples",             │
        │     priority: nil,                           │
        │     remindersListID: 1,                      │
        │     title: "Groceries"                       │
        │   ),                                         │
        │   list: RemindersList(                       │
        │     id: 1,                                   │
        │     color: 4889071,                          │
        │     name: "Personal"                         │
        │   )                                          │
        │ )                                            │
        └──────────────────────────────────────────────┘
        """
      }
    }

    @Test func customDecoding() {
      struct ReminderResult: QueryRepresentable {
        let title: String
        let isCompleted: Bool
        init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
          guard let title = try decoder.decode(String.self)
          else { throw QueryDecodingError.missingRequiredColumn }
          guard let isCompleted = try decoder.decode(Bool.self)
          else { throw QueryDecodingError.missingRequiredColumn }
          self.isCompleted = isCompleted
          self.title = title
        }
      }
      assertQuery(
        #sql(#"SELECT "title", "isCompleted" FROM "reminders" LIMIT 4"#, as: ReminderResult.self)
      ) {
        """
        SELECT "title", "isCompleted" FROM "reminders" LIMIT 4
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ SnapshotTests.SQLMacroTests.ReminderResult( │
        │   title: "Groceries",                       │
        │   isCompleted: false                        │
        │ )                                           │
        ├─────────────────────────────────────────────┤
        │ SnapshotTests.SQLMacroTests.ReminderResult( │
        │   title: "Haircut",                         │
        │   isCompleted: false                        │
        │ )                                           │
        ├─────────────────────────────────────────────┤
        │ SnapshotTests.SQLMacroTests.ReminderResult( │
        │   title: "Doctor appointment",              │
        │   isCompleted: false                        │
        │ )                                           │
        ├─────────────────────────────────────────────┤
        │ SnapshotTests.SQLMacroTests.ReminderResult( │
        │   title: "Take a walk",                     │
        │   isCompleted: true                         │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }
  }
}

@Selection
private struct ReminderWithList {
  let reminder: Reminder
  let list: RemindersList
}
