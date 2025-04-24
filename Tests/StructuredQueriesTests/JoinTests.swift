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
        JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")
        ORDER BY "reminders"."dueDate" DESC
        """
      }results: {
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
  }
}
