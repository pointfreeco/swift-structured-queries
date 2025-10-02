import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing

extension SnapshotTests {
  @Suite struct UnionTests {
    @Test func basics() {
      assertQuery(
        Reminder.select { ("reminder", $0.title) }
          .union(RemindersList.select { ("list", $0.title) })
          .union(Tag.select { ("tag", $0.title) })
      ) {
        """
        SELECT 'reminder', "reminders"."title"
        FROM "reminders"
          UNION
        SELECT 'list', "remindersLists"."title"
        FROM "remindersLists"
          UNION
        SELECT 'tag', "tags"."title"
        FROM "tags"
        """
      } results: {
        """
        ┌────────────┬────────────────────────────┐
        │ "list"     │ "Business"                 │
        │ "list"     │ "Family"                   │
        │ "list"     │ "Personal"                 │
        │ "reminder" │ "Buy concert tickets"      │
        │ "reminder" │ "Call accountant"          │
        │ "reminder" │ "Doctor appointment"       │
        │ "reminder" │ "Get laundry"              │
        │ "reminder" │ "Groceries"                │
        │ "reminder" │ "Haircut"                  │
        │ "reminder" │ "Pick up kids from school" │
        │ "reminder" │ "Send weekly emails"       │
        │ "reminder" │ "Take a walk"              │
        │ "reminder" │ "Take out trash"           │
        │ "tag"      │ "car"                      │
        │ "tag"      │ "kids"                     │
        │ "tag"      │ "optional"                 │
        │ "tag"      │ "someday"                  │
        └────────────┴────────────────────────────┘
        """
      }
    }

    @Test func empty() {
      assertQuery(
        Reminder.none.select { ("reminder", $0.title) }
          .union(RemindersList.select { ("list", $0.title) })
          .union(Tag.none.select { ("tag", $0.title) })
      ) {
        """
        SELECT 'list', "remindersLists"."title"
        FROM "remindersLists"
        """
      } results: {
        """
        ┌────────┬────────────┐
        │ "list" │ "Business" │
        │ "list" │ "Family"   │
        │ "list" │ "Personal" │
        └────────┴────────────┘
        """
      }
    }
    @Test func commonTableExpression() {
      assertQuery(
        With {
          Reminder.select { Name.Columns(type: "reminder", value: $0.title) }
            .union(RemindersList.select { Name.Columns(type: "list", value: $0.title) })
            .union(Tag.select { Name.Columns(type: "tag", value: $0.title) })
        } query: {
          Name.order { ($0.type.desc(), $0.value.asc()) }
        }
      ) {
        """
        WITH "names" AS (
          SELECT 'reminder' AS "type", "reminders"."title" AS "value"
          FROM "reminders"
            UNION
          SELECT 'list' AS "type", "remindersLists"."title" AS "value"
          FROM "remindersLists"
            UNION
          SELECT 'tag' AS "type", "tags"."title" AS "value"
          FROM "tags"
        )
        SELECT "names"."type", "names"."value"
        FROM "names"
        ORDER BY "names"."type" DESC, "names"."value" ASC
        """
      } results: {
        """
        ┌─────────────────────────────────────┐
        │ Name(                               │
        │   type: "tag",                      │
        │   value: "car"                      │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "tag",                      │
        │   value: "kids"                     │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "tag",                      │
        │   value: "optional"                 │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "tag",                      │
        │   value: "someday"                  │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Buy concert tickets"      │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Call accountant"          │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Doctor appointment"       │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Get laundry"              │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Groceries"                │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Haircut"                  │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Pick up kids from school" │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Send weekly emails"       │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Take a walk"              │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "reminder",                 │
        │   value: "Take out trash"           │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "list",                     │
        │   value: "Business"                 │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "list",                     │
        │   value: "Family"                   │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ Name(                               │
        │   type: "list",                     │
        │   value: "Personal"                 │
        │ )                                   │
        └─────────────────────────────────────┘
        """
      }
    }
  }
}

@Table
private struct Name {
  let type: String
  let value: String
}
