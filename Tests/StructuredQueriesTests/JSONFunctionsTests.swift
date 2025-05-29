import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct JSONFunctionsTests {
    @Dependency(\.defaultDatabase) var db

    @Test func jsonGroupArray() {
      assertQuery(
        Reminder.select {
          $0.title.jsonGroupArray()
        }
      ) {
        """
        SELECT json_group_array("reminders"."title")
        FROM "reminders"
        """
      } results: {
        """
        ┌────────────────────────────────────┐
        │ [                                  │
        │   [0]: "Groceries",                │
        │   [1]: "Haircut",                  │
        │   [2]: "Doctor appointment",       │
        │   [3]: "Take a walk",              │
        │   [4]: "Buy concert tickets",      │
        │   [5]: "Pick up kids from school", │
        │   [6]: "Get laundry",              │
        │   [7]: "Take out trash",           │
        │   [8]: "Call accountant",          │
        │   [9]: "Send weekly emails"        │
        │ ]                                  │
        └────────────────────────────────────┘
        """
      }
    }

    @Test func jsonGroupArrayDisctinct() {
      assertQuery(
        Reminder.select {
          $0.priority.jsonGroupArray(isDistinct: true)
        }
      ) {
        """
        SELECT json_group_array(DISTINCT "reminders"."priority")
        FROM "reminders"
        """
      } results: {
        """
        ┌────────────────┐
        │ [              │
        │   [0]: nil,    │
        │   [1]: .high,  │
        │   [2]: .low,   │
        │   [3]: .medium │
        │ ]              │
        └────────────────┘
        """
      }
    }

    @Test func jsonArrayLength() {
      assertQuery(
        Reminder.select {
          $0.title.jsonGroupArray().jsonArrayLength()
        }
      ) {
        """
        SELECT json_array_length(json_group_array("reminders"."title"))
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

    @Test func queryJSON() throws {
      try db.execute(Reminder.delete())
      try db.execute(
        Reminder.insert([
          Reminder.Draft(
            notes: #"""
              [{"body": "* Milk\n* Eggs"},{"body": "* Eggs"},]
              """#,
            remindersListID: 1,
            title: "Get groceries"
          ),
          Reminder.Draft(
            notes: "[]",
            remindersListID: 1,
            title: "Call accountant"
          ),
        ])
      )

      assertQuery(
        Reminder
          .select {
            (
              $0.title,
              #sql("\($0.notes) ->> '$[#-1].body'", as: String?.self)
            )
          }
      ) {
        """
        SELECT "reminders"."title", "reminders"."notes" ->> '$[#-1].body'
        FROM "reminders"
        """
      } results: {
        """
        ┌───────────────────┬──────────┐
        │ "Get groceries"   │ "* Eggs" │
        │ "Call accountant" │ nil      │
        └───────────────────┴──────────┘
        """
      }
    }

    @Test func jsonAssociation_Reminder() {
      assertQuery(
        Reminder
          .group(by: \.id)
          .leftJoin(ReminderTag.all) { $0.id.eq($1.reminderID) }
          .leftJoin(Tag.all) { $1.tagID.eq($2.id) }
          .leftJoin(User.all) { $0.assignedUserID.eq($3.id) }
          .select { reminder, _, tag, user in
            ReminderRow.Columns(
              assignedUser: user,
              reminder: reminder,
              tags: #sql("\(tag.jsonGroupArray())")
            )
          }
          .limit(2)
      ) {
        """
        SELECT "users"."id", "users"."name" AS "assignedUser", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title" AS "reminder", json_group_array(CASE WHEN ("tags"."id" IS NOT NULL) THEN json_object('id', json_quote("tags"."id"), 'title', json_quote("tags"."title")) END) AS "tags"
        FROM "reminders"
        LEFT JOIN "remindersTags" ON ("reminders"."id" = "remindersTags"."reminderID")
        LEFT JOIN "tags" ON ("remindersTags"."tagID" = "tags"."id")
        LEFT JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")
        GROUP BY "reminders"."id"
        LIMIT 2
        """
      } results: {
        """
        ┌──────────────────────────────────────────────┐
        │ ReminderRow(                                 │
        │   assignedUser: User(                        │
        │     id: 1,                                   │
        │     name: "Blob"                             │
        │   ),                                         │
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
        │   tags: [                                    │
        │     [0]: Tag(                                │
        │       id: 3,                                 │
        │       title: "someday"                       │
        │     ),                                       │
        │     [1]: Tag(                                │
        │       id: 4,                                 │
        │       title: "optional"                      │
        │     )                                        │
        │   ]                                          │
        │ )                                            │
        ├──────────────────────────────────────────────┤
        │ ReminderRow(                                 │
        │   assignedUser: nil,                         │
        │   reminder: Reminder(                        │
        │     id: 2,                                   │
        │     assignedUserID: nil,                     │
        │     dueDate: Date(2000-12-30T00:00:00.000Z), │
        │     isCompleted: false,                      │
        │     isFlagged: true,                         │
        │     notes: "",                               │
        │     priority: nil,                           │
        │     remindersListID: 1,                      │
        │     title: "Haircut"                         │
        │   ),                                         │
        │   tags: [                                    │
        │     [0]: Tag(                                │
        │       id: 3,                                 │
        │       title: "someday"                       │
        │     ),                                       │
        │     [1]: Tag(                                │
        │       id: 4,                                 │
        │       title: "optional"                      │
        │     )                                        │
        │   ]                                          │
        │ )                                            │
        └──────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonAssociation_RemindersList() throws {
      assertQuery(
        RemindersList
          .group(by: \.id)
          .leftJoin(Reminder.incomplete) { $0.id.eq($1.remindersListID) }
          .select { remindersList, reminder in
            RemindersListRow.Columns(
              remindersList: remindersList,
              reminders: #sql("\(reminder.jsonGroupArray())")
            )
          }
          .limit(1)
      ) {
        """
        SELECT "remindersLists"."id", "remindersLists"."color", "remindersLists"."title" AS "remindersList", json_group_array(CASE WHEN ("reminders"."id" IS NOT NULL) THEN json_object('id', json_quote("reminders"."id"), 'assignedUserID', json_quote("reminders"."assignedUserID"), 'dueDate', json_quote("reminders"."dueDate"), 'isCompleted', json(CASE "reminders"."isCompleted" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'isFlagged', json(CASE "reminders"."isFlagged" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'notes', json_quote("reminders"."notes"), 'priority', json_quote("reminders"."priority"), 'remindersListID', json_quote("reminders"."remindersListID"), 'title', json_quote("reminders"."title")) END) AS "reminders"
        FROM "remindersLists"
        LEFT JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
        WHERE NOT ("reminders"."isCompleted")
        GROUP BY "remindersLists"."id"
        LIMIT 1
        """
      } results: {
        """
        ┌────────────────────────────────────────────────┐
        │ RemindersListRow(                              │
        │   remindersList: RemindersList(                │
        │     id: 1,                                     │
        │     color: 4889071,                            │
        │     title: "Personal"                          │
        │   ),                                           │
        │   reminders: [                                 │
        │     [0]: Reminder(                             │
        │       id: 1,                                   │
        │       assignedUserID: 1,                       │
        │       dueDate: Date(2001-01-01T00:00:00.000Z), │
        │       isCompleted: false,                      │
        │       isFlagged: false,                        │
        │       notes: "Milk, Eggs, Apples",             │
        │       priority: nil,                           │
        │       remindersListID: 1,                      │
        │       title: "Groceries"                       │
        │     ),                                         │
        │     [1]: Reminder(                             │
        │       id: 2,                                   │
        │       assignedUserID: nil,                     │
        │       dueDate: Date(2000-12-30T00:00:00.000Z), │
        │       isCompleted: false,                      │
        │       isFlagged: true,                         │
        │       notes: "",                               │
        │       priority: nil,                           │
        │       remindersListID: 1,                      │
        │       title: "Haircut"                         │
        │     ),                                         │
        │     [2]: Reminder(                             │
        │       id: 3,                                   │
        │       assignedUserID: nil,                     │
        │       dueDate: Date(2001-01-01T00:00:00.000Z), │
        │       isCompleted: false,                      │
        │       isFlagged: false,                        │
        │       notes: "Ask about diet",                 │
        │       priority: .high,                         │
        │       remindersListID: 1,                      │
        │       title: "Doctor appointment"              │
        │     ),                                         │
        │     [3]: Reminder(                             │
        │       id: 5,                                   │
        │       assignedUserID: nil,                     │
        │       dueDate: nil,                            │
        │       isCompleted: false,                      │
        │       isFlagged: false,                        │
        │       notes: "",                               │
        │       priority: nil,                           │
        │       remindersListID: 1,                      │
        │       title: "Buy concert tickets"             │
        │     )                                          │
        │   ]                                            │
        │ )                                              │
        └────────────────────────────────────────────────┘
        """
      }
    }
  }
}

@Selection
private struct ReminderRow {
  let assignedUser: User?
  let reminder: Reminder
  @Column(as: [Tag].JSONRepresentation.self)
  let tags: [Tag]
}

@Selection
private struct RemindersListRow {
  let remindersList: RemindersList
  @Column(as: [Reminder].JSONRepresentation.self)
  let reminders: [Reminder]
}
