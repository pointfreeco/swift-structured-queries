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
        SELECT "remindersLists"."id" AS "remindersListAndReminderCounts_id", "remindersLists"."color" AS "remindersListAndReminderCounts_color", "remindersLists"."title" AS "remindersListAndReminderCounts_title", "remindersLists"."position" AS "remindersListAndReminderCounts_position", count("reminders"."id") AS "remindersListAndReminderCounts_remindersCount"
        FROM "remindersLists"
        JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
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
        │     title: "Personal",          │
        │     position: 0                 │
        │   ),                            │
        │   remindersCount: 5             │
        │ )                               │
        ├─────────────────────────────────┤
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 2,                      │
        │     color: 15567157,            │
        │     title: "Family",            │
        │     position: 0                 │
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
        SELECT "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "remindersLists"."position", count("reminders"."id")
        FROM "remindersLists"
        JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
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
        │     title: "Personal",          │
        │     position: 0                 │
        │   ),                            │
        │   remindersCount: 5             │
        │ )                               │
        ├─────────────────────────────────┤
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 2,                      │
        │     color: 15567157,            │
        │     title: "Family",            │
        │     position: 0                 │
        │   ),                            │
        │   remindersCount: 3             │
        │ )                               │
        └─────────────────────────────────┘
        """
      }
      let remindersListAndRemindersCount = RemindersListAndReminderCount.Columns(
        remindersList: RemindersList.columns,
        remindersCount: Reminder.columns.count()
      )
      assertQuery(
        #sql(
          """
          SELECT \(remindersListAndRemindersCount)
          FROM \(RemindersList.self)
          JOIN \(Reminder.self) ON \(RemindersList.id) = \(Reminder.remindersListID)
          GROUP BY \(RemindersList.id)
          """,
          as: RemindersListAndReminderCount.self
        )
      ) {
        """
        SELECT "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "remindersLists"."position", count("reminders"."id")
        FROM "remindersLists"
        JOIN "reminders" ON "remindersLists"."id" = "reminders"."remindersListID"
        GROUP BY "remindersLists"."id"
        """
      } results: {
        """
        ┌─────────────────────────────────┐
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 1,                      │
        │     color: 4889071,             │
        │     title: "Personal",          │
        │     position: 0                 │
        │   ),                            │
        │   remindersCount: 5             │
        │ )                               │
        ├─────────────────────────────────┤
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 2,                      │
        │     color: 15567157,            │
        │     title: "Family",            │
        │     position: 0                 │
        │   ),                            │
        │   remindersCount: 3             │
        │ )                               │
        ├─────────────────────────────────┤
        │ RemindersListAndReminderCount(  │
        │   remindersList: RemindersList( │
        │     id: 3,                      │
        │     color: 11689427,            │
        │     title: "Business",          │
        │     position: 0                 │
        │   ),                            │
        │   remindersCount: 2             │
        │ )                               │
        └─────────────────────────────────┘
        """
      }
    }

    @Test func outerJoin() {
      assertQuery(
        Reminder
          .limit(2)
          .leftJoin(User.all) { $0.assignedUserID.is($1.id) }
          .select {
            ReminderTitleAndAssignedUserName.Columns(
              reminderTitle: $0.title,
              assignedUserName: $1.name
            )
          }
      ) {
        """
        SELECT "reminders"."title" AS "reminderTitleAndAssignedUserNames_reminderTitle", "users"."name" AS "reminderTitleAndAssignedUserNames_assignedUserName"
        FROM "reminders"
        LEFT JOIN "users" ON ("reminders"."assignedUserID") IS ("users"."id")
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
        SELECT "reminders"."dueDate" AS "reminderDates_date"
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
        SELECT count("reminders"."id") FILTER (WHERE "reminders"."isCompleted") AS "statses_completedCount", count("reminders"."id") FILTER (WHERE "reminders"."isFlagged") AS "statses_flaggedCount", count("reminders"."id") AS "statses_totalCount"
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

    @Test func alias() {
      let baseQuery =
        RemindersList.as(RL.self).all
        .group(by: \.id)
        .limit(2)
        .join(Reminder.all) { $0.id.eq($1.remindersListID) }

      assertQuery(
        baseQuery
          .select {
            RemindersListAliasAndReminderCount.Columns(
              remindersList: $0,
              remindersCount: $1.id.count()
            )
          }
      ) {
        """
        SELECT "rLs"."id" AS "remindersListAliasAndReminderCounts_id", "rLs"."color" AS "remindersListAliasAndReminderCounts_color", "rLs"."title" AS "remindersListAliasAndReminderCounts_title", "rLs"."position" AS "remindersListAliasAndReminderCounts_position", count("reminders"."id") AS "remindersListAliasAndReminderCounts_remindersCount"
        FROM "remindersLists" AS "rLs"
        JOIN "reminders" ON ("rLs"."id") = ("reminders"."remindersListID")
        GROUP BY "rLs"."id"
        LIMIT 2
        """
      } results: {
        """
        ┌─────────────────────────────────────┐
        │ RemindersListAliasAndReminderCount( │
        │   remindersList: RemindersList(     │
        │     id: 1,                          │
        │     color: 4889071,                 │
        │     title: "Personal",              │
        │     position: 0                     │
        │   ),                                │
        │   remindersCount: 5                 │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ RemindersListAliasAndReminderCount( │
        │   remindersList: RemindersList(     │
        │     id: 2,                          │
        │     color: 15567157,                │
        │     title: "Family",                │
        │     position: 0                     │
        │   ),                                │
        │   remindersCount: 3                 │
        │ )                                   │
        └─────────────────────────────────────┘
        """
      }
    }

    @Test func optionalAlias() {
      let baseQuery =
        Reminder
        .leftJoin(RemindersList.as(RL.self).all) { $0.remindersListID.eq($1.id) }

      assertQuery(
        baseQuery
          .select {
            OptionalRemindersListAliasAndReminderCount.Columns(
              remindersList: $1,
              remindersCount: $0.id.count()
            )
          }
      ) {
        """
        SELECT "rLs"."id" AS "optionalRemindersListAliasAndReminderCounts_id", "rLs"."color" AS "optionalRemindersListAliasAndReminderCounts_color", "rLs"."title" AS "optionalRemindersListAliasAndReminderCounts_title", "rLs"."position" AS "optionalRemindersListAliasAndReminderCounts_position", count("reminders"."id") AS "optionalRemindersListAliasAndReminderCounts_remindersCount"
        FROM "reminders"
        LEFT JOIN "remindersLists" AS "rLs" ON ("reminders"."remindersListID") = ("rLs"."id")
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ OptionalRemindersListAliasAndReminderCount( │
        │   remindersList: RemindersList(             │
        │     id: 1,                                  │
        │     color: 4889071,                         │
        │     title: "Personal",                      │
        │     position: 0                             │
        │   ),                                        │
        │   remindersCount: 10                        │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @Test func duplicateSelectionColumnNames() {
      assertQuery(
        Reminder.select {
          (IDSelection.Columns(id: $0.id), AnotherIDSelection.Columns(id: $0.id))
        }
      ) {
        """
        SELECT "reminders"."id" AS "idSelections_id", "reminders"."id" AS "anotherIDSelections_id"
        FROM "reminders"
        """
      } results: {
        """
        ┌─────────────────────┬────────────────────────────┐
        │ IDSelection(id: 1)  │ AnotherIDSelection(id: 1)  │
        │ IDSelection(id: 2)  │ AnotherIDSelection(id: 2)  │
        │ IDSelection(id: 3)  │ AnotherIDSelection(id: 3)  │
        │ IDSelection(id: 4)  │ AnotherIDSelection(id: 4)  │
        │ IDSelection(id: 5)  │ AnotherIDSelection(id: 5)  │
        │ IDSelection(id: 6)  │ AnotherIDSelection(id: 6)  │
        │ IDSelection(id: 7)  │ AnotherIDSelection(id: 7)  │
        │ IDSelection(id: 8)  │ AnotherIDSelection(id: 8)  │
        │ IDSelection(id: 9)  │ AnotherIDSelection(id: 9)  │
        │ IDSelection(id: 10) │ AnotherIDSelection(id: 10) │
        └─────────────────────┴────────────────────────────┘
        """
      }
    }

    @Test func duplicateColumnNamesWithinSelectionWithColumnGroup() {
      assertQuery(
        RemindersList.select {
          SelectionWithColumnGroupAndID.Columns(id: $0.id, remindersList: $0)
        }
      ) {
        """
        SELECT "remindersLists"."id" AS "selectionWithColumnGroupAndIDs_id_1", "remindersLists"."id" AS "selectionWithColumnGroupAndIDs_id_2", "remindersLists"."color" AS "selectionWithColumnGroupAndIDs_color", "remindersLists"."title" AS "selectionWithColumnGroupAndIDs_title", "remindersLists"."position" AS "selectionWithColumnGroupAndIDs_position"
        FROM "remindersLists"
        """
      } results: {
        """
        ┌─────────────────────────────────┐
        │ SelectionWithColumnGroupAndID(  │
        │   id: 1,                        │
        │   remindersList: RemindersList( │
        │     id: 1,                      │
        │     color: 4889071,             │
        │     title: "Personal",          │
        │     position: 0                 │
        │   )                             │
        │ )                               │
        ├─────────────────────────────────┤
        │ SelectionWithColumnGroupAndID(  │
        │   id: 2,                        │
        │   remindersList: RemindersList( │
        │     id: 2,                      │
        │     color: 15567157,            │
        │     title: "Family",            │
        │     position: 0                 │
        │   )                             │
        │ )                               │
        ├─────────────────────────────────┤
        │ SelectionWithColumnGroupAndID(  │
        │   id: 3,                        │
        │   remindersList: RemindersList( │
        │     id: 3,                      │
        │     color: 11689427,            │
        │     title: "Business",          │
        │     position: 0                 │
        │   )                             │
        │ )                               │
        └─────────────────────────────────┘
        """
      }
    }

    @Test func duplicateColumnNamesWithinSelectionWithColumnGroupAlias() {
      assertQuery(
        RemindersList.as(RL.self).select {
          SelectionWithColumnGroupAliasAndID.Columns(id: $0.id, remindersList: $0)
        }
      ) {
        """
        SELECT "rLs"."id" AS "selectionWithColumnGroupAliasAndIDs_id_1", "rLs"."id" AS "selectionWithColumnGroupAliasAndIDs_id_2", "rLs"."color" AS "selectionWithColumnGroupAliasAndIDs_color", "rLs"."title" AS "selectionWithColumnGroupAliasAndIDs_title", "rLs"."position" AS "selectionWithColumnGroupAliasAndIDs_position"
        FROM "remindersLists" AS "rLs"
        """
      } results: {
        """
        ┌─────────────────────────────────────┐
        │ SelectionWithColumnGroupAliasAndID( │
        │   id: 1,                            │
        │   remindersList: RemindersList(     │
        │     id: 1,                          │
        │     color: 4889071,                 │
        │     title: "Personal",              │
        │     position: 0                     │
        │   )                                 │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ SelectionWithColumnGroupAliasAndID( │
        │   id: 2,                            │
        │   remindersList: RemindersList(     │
        │     id: 2,                          │
        │     color: 15567157,                │
        │     title: "Family",                │
        │     position: 0                     │
        │   )                                 │
        │ )                                   │
        ├─────────────────────────────────────┤
        │ SelectionWithColumnGroupAliasAndID( │
        │   id: 3,                            │
        │   remindersList: RemindersList(     │
        │     id: 3,                          │
        │     color: 11689427,                │
        │     title: "Business",              │
        │     position: 0                     │
        │   )                                 │
        │ )                                   │
        └─────────────────────────────────────┘
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

enum RL: AliasName {}

@Selection
struct RemindersListAliasAndReminderCount {
  @Columns(as: TableAlias<RemindersList, RL>.self)
  let remindersList: RemindersList
  let remindersCount: Int
}

@Selection
struct OptionalRemindersListAliasAndReminderCount {
  @Columns(as: TableAlias<RemindersList, RL>?.self)
  let remindersList: RemindersList?
  let remindersCount: Int
}

@Selection
struct Stats {
  let completedCount: Int
  let flaggedCount: Int
  let totalCount: Int
}

@Selection
struct IDSelection {
  let id: Int
}

@Selection
struct AnotherIDSelection {
  let id: Int
}

@Selection
struct SelectionWithColumnGroupAndID {
  let id: Int
  let remindersList: RemindersList
}

@Selection
struct SelectionWithColumnGroupAliasAndID {
  let id: Int
  @Columns(as: TableAlias<RemindersList, RL>.self)
  let remindersList: RemindersList
}
