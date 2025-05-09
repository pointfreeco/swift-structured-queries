import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing

extension SnapshotTests {
  @Suite struct SelectionTests {
    @Test func remindersListAndReminderCount() {
      let baseQuery =
        RemindersList
        .group(by: \.id)
        .limit(2)
        .join(Reminder.all) { $0.id.eq($1.remindersListID) }

      assertQuery(
        baseQuery
          .select {
            RemindersListAndReminderCount.Columns(remindersList: $0, remindersCount: $1.id.count())
          }
      ) {
        """
        SELECT "remindersLists"."id", "remindersLists"."color", "remindersLists"."title" AS "remindersList", count("reminders"."id") AS "remindersCount"
        FROM "remindersLists"
        JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
        GROUP BY "remindersLists"."id"
        LIMIT 2
        """
      } results: {
        """
        ┌─────────────────────────────────┐
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 1,                      │
        │     color: 4889071,             │
        │     title: "Personal"           │
        │   ),                            │
        │   remindersCount: 5             │
        │ )                               │
        ├─────────────────────────────────┤
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 2,                      │
        │     color: 15567157,            │
        │     title: "Family"             │
        │   ),                            │
        │   remindersCount: 3             │
        │ )                               │
        └─────────────────────────────────┘
        """
      }
      assertQuery(
        baseQuery
          .select { ($1.id.count(), $0) }
          .map { RemindersListAndReminderCount.Columns(remindersList: $1, remindersCount: $0) }
      ) {
        """
        SELECT "remindersLists"."id", "remindersLists"."color", "remindersLists"."title" AS "remindersList", count("reminders"."id") AS "remindersCount"
        FROM "remindersLists"
        JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
        GROUP BY "remindersLists"."id"
        LIMIT 2
        """
      } results: {
        """
        ┌─────────────────────────────────┐
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 1,                      │
        │     color: 4889071,             │
        │     title: "Personal"           │
        │   ),                            │
        │   remindersCount: 5             │
        │ )                               │
        ├─────────────────────────────────┤
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 2,                      │
        │     color: 15567157,            │
        │     title: "Family"             │
        │   ),                            │
        │   remindersCount: 3             │
        │ )                               │
        └─────────────────────────────────┘
        """
      }
    }

    @Test func outerJoin() {
      assertQuery(
        Reminder
          .limit(2)
          .leftJoin(User.all) { $0.assignedUserID.eq($1.id) }
          .select {
            ReminderTitleAndAssignedUserName.Columns(
              reminderTitle: $0.title,
              assignedUserName: $1.name
            )
          }
      ) {
        """
        SELECT "reminders"."title" AS "reminderTitle", "users"."name" AS "assignedUserName"
        FROM "reminders"
        LEFT JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")
        LIMIT 2
        """
      } results: {
        """
        ┌───────────────────────────────────┐
        │ ReminderTitleAndAssignedUserName( │
        │   reminderTitle: "Groceries",     │
        │   assignedUserName: "Blob"        │
        │ )                                 │
        ├───────────────────────────────────┤
        │ ReminderTitleAndAssignedUserName( │
        │   reminderTitle: "Haircut",       │
        │   assignedUserName: nil           │
        │ )                                 │
        └───────────────────────────────────┘
        """
      }
    }

    @Test func date() {
      assertQuery(
        Reminder.select {
          ReminderDate.Columns(date: $0.dueDate)
        }
      ) {
        """
        SELECT "reminders"."dueDate" AS "date"
        FROM "reminders"
        """
      } results: {
        """
        ┌────────────────────────────────────────────────────┐
        │ ReminderDate(date: Date(2001-01-01T00:00:00.000Z)) │
        │ ReminderDate(date: Date(2000-12-30T00:00:00.000Z)) │
        │ ReminderDate(date: Date(2001-01-01T00:00:00.000Z)) │
        │ ReminderDate(date: Date(2000-06-25T00:00:00.000Z)) │
        │ ReminderDate(date: nil)                            │
        │ ReminderDate(date: Date(2001-01-03T00:00:00.000Z)) │
        │ ReminderDate(date: Date(2000-12-30T00:00:00.000Z)) │
        │ ReminderDate(date: Date(2001-01-05T00:00:00.000Z)) │
        │ ReminderDate(date: Date(2001-01-03T00:00:00.000Z)) │
        │ ReminderDate(date: Date(2000-12-30T00:00:00.000Z)) │
        └────────────────────────────────────────────────────┘
        """
      }
    }

    @Test func multiAggregate() {
      assertQuery(
        Reminder.select {
          Stats.Columns(
            completedCount: $0.count(filter: $0.isCompleted),
            flaggedCount: $0.count(filter: $0.isFlagged),
            totalCount: $0.count()
          )
        }
      ) {
        """
        SELECT count("reminders"."id") FILTER (WHERE "reminders"."isCompleted") AS "completedCount", count("reminders"."id") FILTER (WHERE "reminders"."isFlagged") AS "flaggedCount", count("reminders"."id") AS "totalCount"
        FROM "reminders"
        """
      } results: {
        """
        ┌──────────────────────┐
        │ Stats(               │
        │   completedCount: 3, │
        │   flaggedCount: 2,   │
        │   totalCount: 10     │
        │ )                    │
        └──────────────────────┘
        """
      }
    }
  }
}

@Selection
struct ReminderDate {
  var date: Date?
}

@Selection
struct ReminderTitleAndAssignedUserName {
  let reminderTitle: String
  let assignedUserName: String?
}

@Selection
struct RemindersListAndReminderCount {
  let remindersList: RemindersList
  let remindersCount: Int
}

@Selection
struct Stats {
  let completedCount: Int
  let flaggedCount: Int
  let totalCount: Int
}
