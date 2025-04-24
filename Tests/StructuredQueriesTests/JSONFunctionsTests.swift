import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesSupport
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

    @Test func jsonAssociation() {
      assertQuery(
        Reminder
          .group(by: \.id)
          .leftJoin(ReminderTag.all) { $0.id.eq($1.reminderID) }
          .leftJoin(Tag.all) { $1.tagID.eq($2.id) }
          .select { Row.Columns(reminder: $0, tags: #sql("\($2.jsonObjects)")) }
          .limit(3)
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title" AS "reminder", json_group_array(json_object('id', json_quote("tags"."id"), 'title', json_quote("tags"."title"))) filter(where ("tags"."id" IS NOT NULL)) AS "tags"
        FROM "reminders"
        LEFT JOIN "remindersTags" ON ("reminders"."id" = "remindersTags"."reminderID")
        LEFT JOIN "tags" ON ("remindersTags"."tagID" = "tags"."id")
        GROUP BY "reminders"."id"
        LIMIT 3
        """
      }results: {
        """
        ┌──────────────────────────────────────────────┐
        │ Row(                                         │
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
        │ Row(                                         │
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
        ├──────────────────────────────────────────────┤
        │ Row(                                         │
        │   reminder: Reminder(                        │
        │     id: 3,                                   │
        │     assignedUserID: nil,                     │
        │     dueDate: Date(2001-01-01T00:00:00.000Z), │
        │     isCompleted: false,                      │
        │     isFlagged: false,                        │
        │     notes: "Ask about diet",                 │
        │     priority: .high,                         │
        │     remindersListID: 1,                      │
        │     title: "Doctor appointment"              │
        │   ),                                         │
        │   tags: []                                   │
        │ )                                            │
        └──────────────────────────────────────────────┘
        """
      }
    }
  }
}

@Selection
fileprivate struct Row {
  let reminder: Reminder
  @Column(as: JSONRepresentation<[Tag]>.self)
  let tags: [Tag]
}

// TODO: Library code?
extension PrimaryKeyedTableDefinition where QueryValue: Codable & Sendable {
  public var jsonObject: some QueryExpression<JSONRepresentation<QueryValue>> {
    let fragment: QueryFragment = Self.allColumns
      .map { "\(quote: $0.name, delimiter: .text), json_quote(\($0))" }
      .joined(separator: ", ")
    return #sql("json_object(\(fragment))")
  }

  public var jsonObjects: some QueryExpression<JSONRepresentation<[QueryValue]>> {
    #sql(
      "json_group_array(\(jsonObject)) filter(where \(self.primaryKey != nil))"
    )
  }
}
