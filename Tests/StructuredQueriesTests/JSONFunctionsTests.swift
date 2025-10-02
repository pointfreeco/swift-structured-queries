import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

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
          $0.priority.jsonGroupArray(distinct: true)
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
        Reminder.insert {
          Reminder.Draft(
            notes: #"""
              [{"body": "* Milk\n* Eggs"},{"body": "* Eggs"},]
              """#,
            remindersListID: 1,
            title: "Get groceries"
          )
          Reminder.Draft(
            notes: "[]",
            remindersListID: 1,
            title: "Call accountant"
          )
        }
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
              tags: tag.jsonGroupArray()
            )
          }
          .limit(2)
      ) {
        """
        SELECT "users"."id" AS "id", "users"."name" AS "name", "reminders"."id" AS "id", "reminders"."assignedUserID" AS "assignedUserID", "reminders"."dueDate" AS "dueDate", "reminders"."isCompleted" AS "isCompleted", "reminders"."isFlagged" AS "isFlagged", "reminders"."notes" AS "notes", "reminders"."priority" AS "priority", "reminders"."remindersListID" AS "remindersListID", "reminders"."title" AS "title", "reminders"."updatedAt" AS "updatedAt", json_group_array(CASE WHEN ("tags"."rowid") IS NOT (NULL) THEN json_object('id', json_quote("tags"."id"), 'title', json_quote("tags"."title")) END) FILTER (WHERE ("tags"."id") IS NOT (NULL)) AS "tags"
        FROM "reminders"
        LEFT JOIN "remindersTags" ON ("reminders"."id") = ("remindersTags"."reminderID")
        LEFT JOIN "tags" ON ("remindersTags"."tagID") = ("tags"."id")
        LEFT JOIN "users" ON ("reminders"."assignedUserID") = ("users"."id")
        GROUP BY "reminders"."id"
        LIMIT 2
        """
      } results: {
        """
        ┌───────────────────────────────────────────────┐
        │ ReminderRow(                                  │
        │   assignedUser: User(                         │
        │     id: 1,                                    │
        │     name: "Blob"                              │
        │   ),                                          │
        │   reminder: Reminder(                         │
        │     id: 1,                                    │
        │     assignedUserID: 1,                        │
        │     dueDate: Date(2001-01-01T00:00:00.000Z),  │
        │     isCompleted: false,                       │
        │     isFlagged: false,                         │
        │     notes: "Milk, Eggs, Apples",              │
        │     priority: nil,                            │
        │     remindersListID: 1,                       │
        │     title: "Groceries",                       │
        │     updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │   ),                                          │
        │   tags: [                                     │
        │     [0]: Tag(                                 │
        │       id: 3,                                  │
        │       title: "someday"                        │
        │     ),                                        │
        │     [1]: Tag(                                 │
        │       id: 4,                                  │
        │       title: "optional"                       │
        │     )                                         │
        │   ]                                           │
        │ )                                             │
        ├───────────────────────────────────────────────┤
        │ ReminderRow(                                  │
        │   assignedUser: nil,                          │
        │   reminder: Reminder(                         │
        │     id: 2,                                    │
        │     assignedUserID: nil,                      │
        │     dueDate: Date(2000-12-30T00:00:00.000Z),  │
        │     isCompleted: false,                       │
        │     isFlagged: true,                          │
        │     notes: "",                                │
        │     priority: nil,                            │
        │     remindersListID: 1,                       │
        │     title: "Haircut",                         │
        │     updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │   ),                                          │
        │   tags: [                                     │
        │     [0]: Tag(                                 │
        │       id: 3,                                  │
        │       title: "someday"                        │
        │     ),                                        │
        │     [1]: Tag(                                 │
        │       id: 4,                                  │
        │       title: "optional"                       │
        │     )                                         │
        │   ]                                           │
        │ )                                             │
        └───────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonAssociation_RemindersList() throws {
      assertQuery(
        RemindersList
          .group(by: \.id)
          .leftJoin(Milestone.all) { $0.id.eq($1.remindersListID) }
          .leftJoin(Reminder.incomplete) { $0.id.eq($2.remindersListID) }
          .select {
            RemindersListRow.Columns(
              remindersList: $0,
              milestones: $1.jsonGroupArray(distinct: true),
              reminders: $2.jsonGroupArray(distinct: true)
            )
          }
          .limit(1)
      ) {
        """
        SELECT "remindersLists"."id" AS "id", "remindersLists"."color" AS "color", "remindersLists"."title" AS "title", "remindersLists"."position" AS "position", json_group_array(DISTINCT CASE WHEN ("milestones"."rowid") IS NOT (NULL) THEN json_object('id', json_quote("milestones"."id"), 'remindersListID', json_quote("milestones"."remindersListID"), 'title', json_quote("milestones"."title")) END) FILTER (WHERE ("milestones"."id") IS NOT (NULL)) AS "milestones", json_group_array(DISTINCT CASE WHEN ("reminders"."rowid") IS NOT (NULL) THEN json_object('id', json_quote("reminders"."id"), 'assignedUserID', json_quote("reminders"."assignedUserID"), 'dueDate', json_quote("reminders"."dueDate"), 'isCompleted', json(CASE "reminders"."isCompleted" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'isFlagged', json(CASE "reminders"."isFlagged" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'notes', json_quote("reminders"."notes"), 'priority', json_quote("reminders"."priority"), 'remindersListID', json_quote("reminders"."remindersListID"), 'title', json_quote("reminders"."title"), 'updatedAt', json_quote("reminders"."updatedAt")) END) FILTER (WHERE ("reminders"."id") IS NOT (NULL)) AS "reminders"
        FROM "remindersLists"
        LEFT JOIN "milestones" ON ("remindersLists"."id") = ("milestones"."remindersListID")
        LEFT JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
        WHERE NOT ("reminders"."isCompleted")
        GROUP BY "remindersLists"."id"
        LIMIT 1
        """
      } results: {
        """
        ┌─────────────────────────────────────────────────┐
        │ RemindersListRow(                               │
        │   remindersList: RemindersList(                 │
        │     id: 1,                                      │
        │     color: 4889071,                             │
        │     title: "Personal",                          │
        │     position: 0                                 │
        │   ),                                            │
        │   milestones: [                                 │
        │     [0]: Milestone(                             │
        │       id: 1,                                    │
        │       remindersListID: 1,                       │
        │       title: "Phase 1"                          │
        │     ),                                          │
        │     [1]: Milestone(                             │
        │       id: 2,                                    │
        │       remindersListID: 1,                       │
        │       title: "Phase 2"                          │
        │     ),                                          │
        │     [2]: Milestone(                             │
        │       id: 3,                                    │
        │       remindersListID: 1,                       │
        │       title: "Phase 3"                          │
        │     )                                           │
        │   ],                                            │
        │   reminders: [                                  │
        │     [0]: Reminder(                              │
        │       id: 1,                                    │
        │       assignedUserID: 1,                        │
        │       dueDate: Date(2001-01-01T00:00:00.000Z),  │
        │       isCompleted: false,                       │
        │       isFlagged: false,                         │
        │       notes: "Milk, Eggs, Apples",              │
        │       priority: nil,                            │
        │       remindersListID: 1,                       │
        │       title: "Groceries",                       │
        │       updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │     ),                                          │
        │     [1]: Reminder(                              │
        │       id: 2,                                    │
        │       assignedUserID: nil,                      │
        │       dueDate: Date(2000-12-30T00:00:00.000Z),  │
        │       isCompleted: false,                       │
        │       isFlagged: true,                          │
        │       notes: "",                                │
        │       priority: nil,                            │
        │       remindersListID: 1,                       │
        │       title: "Haircut",                         │
        │       updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │     ),                                          │
        │     [2]: Reminder(                              │
        │       id: 3,                                    │
        │       assignedUserID: nil,                      │
        │       dueDate: Date(2001-01-01T00:00:00.000Z),  │
        │       isCompleted: false,                       │
        │       isFlagged: false,                         │
        │       notes: "Ask about diet",                  │
        │       priority: .high,                          │
        │       remindersListID: 1,                       │
        │       title: "Doctor appointment",              │
        │       updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │     ),                                          │
        │     [3]: Reminder(                              │
        │       id: 5,                                    │
        │       assignedUserID: nil,                      │
        │       dueDate: nil,                             │
        │       isCompleted: false,                       │
        │       isFlagged: false,                         │
        │       notes: "",                                │
        │       priority: nil,                            │
        │       remindersListID: 1,                       │
        │       title: "Buy concert tickets",             │
        │       updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │     )                                           │
        │   ]                                             │
        │ )                                               │
        └─────────────────────────────────────────────────┘
        """
      }
    }

    @Test func jsonPatch() {
      assertQuery(Values(#bind(["a": 1]).jsonPatch(#bind(["b": 2])))) {
        """
        SELECT json_patch('{
          "a" : 1
        }', '{
          "b" : 2
        }')
        """
      } results: {
        """
        ┌───────────┐
        │ [         │
        │   "a": 1, │
        │   "b": 2  │
        │ ]         │
        └───────────┘
        """
      }
    }

    @Test func jsonObject() {
      assertQuery(
        Reminder
          .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
          .select { ($0, $1.jsonObject()) }
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt", json_object('id', json_quote("remindersLists"."id"), 'color', json_quote("remindersLists"."color"), 'title', json_quote("remindersLists"."title"), 'position', json_quote("remindersLists"."position"))
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
        """
      } results: {
        #"""
        ┌─────────────────────────────────────────────┬──────────────────────┐
        │ Reminder(                                   │ RemindersList(       │
        │   id: 1,                                    │   id: 1,             │
        │   assignedUserID: 1,                        │   color: 4889071,    │
        │   dueDate: Date(2001-01-01T00:00:00.000Z),  │   title: "Personal", │
        │   isCompleted: false,                       │   position: 0        │
        │   isFlagged: false,                         │ )                    │
        │   notes: "Milk, Eggs, Apples",              │                      │
        │   priority: nil,                            │                      │
        │   remindersListID: 1,                       │                      │
        │   title: "Groceries",                       │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 2,                                    │   id: 1,             │
        │   assignedUserID: nil,                      │   color: 4889071,    │
        │   dueDate: Date(2000-12-30T00:00:00.000Z),  │   title: "Personal", │
        │   isCompleted: false,                       │   position: 0        │
        │   isFlagged: true,                          │ )                    │
        │   notes: "",                                │                      │
        │   priority: nil,                            │                      │
        │   remindersListID: 1,                       │                      │
        │   title: "Haircut",                         │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 3,                                    │   id: 1,             │
        │   assignedUserID: nil,                      │   color: 4889071,    │
        │   dueDate: Date(2001-01-01T00:00:00.000Z),  │   title: "Personal", │
        │   isCompleted: false,                       │   position: 0        │
        │   isFlagged: false,                         │ )                    │
        │   notes: "Ask about diet",                  │                      │
        │   priority: .high,                          │                      │
        │   remindersListID: 1,                       │                      │
        │   title: "Doctor appointment",              │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 4,                                    │   id: 1,             │
        │   assignedUserID: nil,                      │   color: 4889071,    │
        │   dueDate: Date(2000-06-25T00:00:00.000Z),  │   title: "Personal", │
        │   isCompleted: true,                        │   position: 0        │
        │   isFlagged: false,                         │ )                    │
        │   notes: "",                                │                      │
        │   priority: nil,                            │                      │
        │   remindersListID: 1,                       │                      │
        │   title: "Take a walk",                     │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 5,                                    │   id: 1,             │
        │   assignedUserID: nil,                      │   color: 4889071,    │
        │   dueDate: nil,                             │   title: "Personal", │
        │   isCompleted: false,                       │   position: 0        │
        │   isFlagged: false,                         │ )                    │
        │   notes: "",                                │                      │
        │   priority: nil,                            │                      │
        │   remindersListID: 1,                       │                      │
        │   title: "Buy concert tickets",             │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 6,                                    │   id: 2,             │
        │   assignedUserID: nil,                      │   color: 15567157,   │
        │   dueDate: Date(2001-01-03T00:00:00.000Z),  │   title: "Family",   │
        │   isCompleted: false,                       │   position: 0        │
        │   isFlagged: true,                          │ )                    │
        │   notes: "",                                │                      │
        │   priority: .high,                          │                      │
        │   remindersListID: 2,                       │                      │
        │   title: "Pick up kids from school",        │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 7,                                    │   id: 2,             │
        │   assignedUserID: nil,                      │   color: 15567157,   │
        │   dueDate: Date(2000-12-30T00:00:00.000Z),  │   title: "Family",   │
        │   isCompleted: true,                        │   position: 0        │
        │   isFlagged: false,                         │ )                    │
        │   notes: "",                                │                      │
        │   priority: .low,                           │                      │
        │   remindersListID: 2,                       │                      │
        │   title: "Get laundry",                     │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 8,                                    │   id: 2,             │
        │   assignedUserID: nil,                      │   color: 15567157,   │
        │   dueDate: Date(2001-01-05T00:00:00.000Z),  │   title: "Family",   │
        │   isCompleted: false,                       │   position: 0        │
        │   isFlagged: false,                         │ )                    │
        │   notes: "",                                │                      │
        │   priority: .high,                          │                      │
        │   remindersListID: 2,                       │                      │
        │   title: "Take out trash",                  │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 9,                                    │   id: 3,             │
        │   assignedUserID: nil,                      │   color: 11689427,   │
        │   dueDate: Date(2001-01-03T00:00:00.000Z),  │   title: "Business", │
        │   isCompleted: false,                       │   position: 0        │
        │   isFlagged: false,                         │ )                    │
        │   notes: """                                │                      │
        │     Status of tax return                    │                      │
        │     Expenses for next year                  │                      │
        │     Changing payroll company                │                      │
        │     """,                                    │                      │
        │   priority: nil,                            │                      │
        │   remindersListID: 3,                       │                      │
        │   title: "Call accountant",                 │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        ├─────────────────────────────────────────────┼──────────────────────┤
        │ Reminder(                                   │ RemindersList(       │
        │   id: 10,                                   │   id: 3,             │
        │   assignedUserID: nil,                      │   color: 11689427,   │
        │   dueDate: Date(2000-12-30T00:00:00.000Z),  │   title: "Business", │
        │   isCompleted: true,                        │   position: 0        │
        │   isFlagged: false,                         │ )                    │
        │   notes: "",                                │                      │
        │   priority: .medium,                        │                      │
        │   remindersListID: 3,                       │                      │
        │   title: "Send weekly emails",              │                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │                      │
        │ )                                           │                      │
        └─────────────────────────────────────────────┴──────────────────────┘
        """#
      }
    }
  }
}

@Table
private struct ReminderRow {
  let assignedUser: User?
  let reminder: Reminder
  @Column(as: [Tag].JSONRepresentation.self)
  let tags: [Tag]
}

@Table
private struct RemindersListRow {
  let remindersList: RemindersList
  @Column(as: [Milestone].JSONRepresentation.self)
  let milestones: [Milestone]
  @Column(as: [Reminder].JSONRepresentation.self)
  let reminders: [Reminder]
}
