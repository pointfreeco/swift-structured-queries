import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing

extension SnapshotTests {
  @Suite struct JoinTests {
    @Test func basics() {
      assertQuery(
        Reminder
          .order { $0.dueDate.desc() }
          .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
          .select { ($0.title, $1.title) }
      ) {
        """
        SELECT "reminders"."title", "remindersLists"."title"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
        ORDER BY "reminders"."dueDate" DESC
        """
      } results: {
        """
        ┌────────────────────────────┬────────────┐
        │ "Take out trash"           │ "Family"   │
        │ "Pick up kids from school" │ "Family"   │
        │ "Call accountant"          │ "Business" │
        │ "Groceries"                │ "Personal" │
        │ "Doctor appointment"       │ "Personal" │
        │ "Haircut"                  │ "Personal" │
        │ "Get laundry"              │ "Family"   │
        │ "Send weekly emails"       │ "Business" │
        │ "Take a walk"              │ "Personal" │
        │ "Buy concert tickets"      │ "Personal" │
        └────────────────────────────┴────────────┘
        """
      }
    }

    @Test func outerJoinOptional() {
      assertQuery(
        RemindersList
          .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
          .select {
            PriorityRow.Columns(value: $1.priority)
          }
      ) {
        """
        SELECT "reminders"."priority" AS "value"
        FROM "remindersLists"
        LEFT JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
        """
      } results: {
        """
        ┌─────────────────────────┐
        │ PriorityRow(value: nil) │
        ├─────────────────────────┤
        │ PriorityRow(            │
        │   value: .medium        │
        │ )                       │
        ├─────────────────────────┤
        │ PriorityRow(            │
        │   value: .high          │
        │ )                       │
        ├─────────────────────────┤
        │ PriorityRow(            │
        │   value: .low           │
        │ )                       │
        ├─────────────────────────┤
        │ PriorityRow(            │
        │   value: .high          │
        │ )                       │
        ├─────────────────────────┤
        │ PriorityRow(value: nil) │
        ├─────────────────────────┤
        │ PriorityRow(value: nil) │
        ├─────────────────────────┤
        │ PriorityRow(            │
        │   value: .high          │
        │ )                       │
        ├─────────────────────────┤
        │ PriorityRow(value: nil) │
        ├─────────────────────────┤
        │ PriorityRow(value: nil) │
        └─────────────────────────┘
        """
      }
    }
  }
}

@Table
private struct PriorityRow {
  let value: Priority?
}
