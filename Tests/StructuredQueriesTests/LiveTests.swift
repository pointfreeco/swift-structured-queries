import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import Testing

extension SnapshotTests {
  @Suite struct LiveTests {
    @Test func selectAll() {
      assertQuery(Reminder.all) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "reminders"
        """
      } results: {
        #"""
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
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 2,                                   │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2000-12-30T00:00:00.000Z), │
        │   isCompleted: false,                      │
        │   isFlagged: true,                         │
        │   notes: "",                               │
        │   priority: nil,                           │
        │   remindersListID: 1,                      │
        │   title: "Haircut"                         │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 3,                                   │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │
        │   isCompleted: false,                      │
        │   isFlagged: false,                        │
        │   notes: "Ask about diet",                 │
        │   priority: .high,                         │
        │   remindersListID: 1,                      │
        │   title: "Doctor appointment"              │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 4,                                   │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2000-06-25T00:00:00.000Z), │
        │   isCompleted: true,                       │
        │   isFlagged: false,                        │
        │   notes: "",                               │
        │   priority: nil,                           │
        │   remindersListID: 1,                      │
        │   title: "Take a walk"                     │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 5,                                   │
        │   assignedUserID: nil,                     │
        │   dueDate: nil,                            │
        │   isCompleted: false,                      │
        │   isFlagged: false,                        │
        │   notes: "",                               │
        │   priority: nil,                           │
        │   remindersListID: 1,                      │
        │   title: "Buy concert tickets"             │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 6,                                   │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2001-01-03T00:00:00.000Z), │
        │   isCompleted: false,                      │
        │   isFlagged: true,                         │
        │   notes: "",                               │
        │   priority: .high,                         │
        │   remindersListID: 2,                      │
        │   title: "Pick up kids from school"        │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 7,                                   │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2000-12-30T00:00:00.000Z), │
        │   isCompleted: true,                       │
        │   isFlagged: false,                        │
        │   notes: "",                               │
        │   priority: .low,                          │
        │   remindersListID: 2,                      │
        │   title: "Get laundry"                     │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 8,                                   │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2001-01-05T00:00:00.000Z), │
        │   isCompleted: false,                      │
        │   isFlagged: false,                        │
        │   notes: "",                               │
        │   priority: .high,                         │
        │   remindersListID: 2,                      │
        │   title: "Take out trash"                  │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 9,                                   │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2001-01-03T00:00:00.000Z), │
        │   isCompleted: false,                      │
        │   isFlagged: false,                        │
        │   notes: """                               │
        │     Status of tax return                   │
        │     Expenses for next year                 │
        │     Changing payroll company               │
        │     """,                                   │
        │   priority: nil,                           │
        │   remindersListID: 3,                      │
        │   title: "Call accountant"                 │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 10,                                  │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2000-12-30T00:00:00.000Z), │
        │   isCompleted: true,                       │
        │   isFlagged: false,                        │
        │   notes: "",                               │
        │   priority: .medium,                       │
        │   remindersListID: 3,                      │
        │   title: "Send weekly emails"              │
        │ )                                          │
        └────────────────────────────────────────────┘
        """#
      }
    }

    @Test func select() {
      let averagePriority = Reminder.select { $0.priority.cast(as: Int?.self).avg() }
      assertQuery(
        Reminder
          .select { ($0.title, $0.priority, averagePriority) }
          .where { #sql("\($0.priority) < (\(averagePriority))") || $0.priority == nil }
          .order { $0.priority.desc() }
      ) {
        """
        SELECT "reminders"."title", "reminders"."priority", (
          SELECT avg(CAST("reminders"."priority" AS INTEGER))
          FROM "reminders"
        )
        FROM "reminders"
        WHERE ("reminders"."priority" < (SELECT avg(CAST("reminders"."priority" AS INTEGER))
        FROM "reminders") OR ("reminders"."priority" IS NULL))
        ORDER BY "reminders"."priority" DESC
        """
      } results: {
        """
        ┌───────────────────────┬─────────┬─────┐
        │ "Send weekly emails"  │ .medium │ 2.4 │
        │ "Get laundry"         │ .low    │ 2.4 │
        │ "Groceries"           │ nil     │ 2.4 │
        │ "Haircut"             │ nil     │ 2.4 │
        │ "Take a walk"         │ nil     │ 2.4 │
        │ "Buy concert tickets" │ nil     │ 2.4 │
        │ "Call accountant"     │ nil     │ 2.4 │
        └───────────────────────┴─────────┴─────┘
        """
      }
    }

    @Test func remindersListWithReminderCount() {
      assertQuery(
        RemindersList
          .group(by: \.id)
          .join(Reminder.all) { $0.id.eq($1.remindersListID) }
          .select { ($0, $1.id.count()) }
      ) {
        """
        SELECT "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", count("reminders"."id")
        FROM "remindersLists"
        JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
        GROUP BY "remindersLists"."id"
        """
      } results: {
        """
        ┌─────────────────────┬───┐
        │ RemindersList(      │ 5 │
        │   id: 1,            │   │
        │   color: 4889071,   │   │
        │   title: "Personal" │   │
        │ )                   │   │
        ├─────────────────────┼───┤
        │ RemindersList(      │ 3 │
        │   id: 2,            │   │
        │   color: 15567157,  │   │
        │   title: "Family"   │   │
        │ )                   │   │
        ├─────────────────────┼───┤
        │ RemindersList(      │ 2 │
        │   id: 3,            │   │
        │   color: 11689427,  │   │
        │   title: "Business" │   │
        │ )                   │   │
        └─────────────────────┴───┘
        """
      }
    }

    @Test func remindersWithTags() {
      assertQuery(
        Reminder
          .group(by: \.id)
          .join(ReminderTag.all) { $0.id.eq($1.reminderID) }
          .join(Tag.all) { $1.tagID.eq($2.id) }
          .select { ($0, $2.title.groupConcat()) }
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", group_concat("tags"."title")
        FROM "reminders"
        JOIN "remindersTags" ON ("reminders"."id" = "remindersTags"."reminderID")
        JOIN "tags" ON ("remindersTags"."tagID" = "tags"."id")
        GROUP BY "reminders"."id"
        """
      } results: {
        """
        ┌────────────────────────────────────────────┬────────────────────┐
        │ Reminder(                                  │ "someday,optional" │
        │   id: 1,                                   │                    │
        │   assignedUserID: 1,                       │                    │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │                    │
        │   isCompleted: false,                      │                    │
        │   isFlagged: false,                        │                    │
        │   notes: "Milk, Eggs, Apples",             │                    │
        │   priority: nil,                           │                    │
        │   remindersListID: 1,                      │                    │
        │   title: "Groceries"                       │                    │
        │ )                                          │                    │
        ├────────────────────────────────────────────┼────────────────────┤
        │ Reminder(                                  │ "someday,optional" │
        │   id: 2,                                   │                    │
        │   assignedUserID: nil,                     │                    │
        │   dueDate: Date(2000-12-30T00:00:00.000Z), │                    │
        │   isCompleted: false,                      │                    │
        │   isFlagged: true,                         │                    │
        │   notes: "",                               │                    │
        │   priority: nil,                           │                    │
        │   remindersListID: 1,                      │                    │
        │   title: "Haircut"                         │                    │
        │ )                                          │                    │
        ├────────────────────────────────────────────┼────────────────────┤
        │ Reminder(                                  │ "car,kids"         │
        │   id: 4,                                   │                    │
        │   assignedUserID: nil,                     │                    │
        │   dueDate: Date(2000-06-25T00:00:00.000Z), │                    │
        │   isCompleted: true,                       │                    │
        │   isFlagged: false,                        │                    │
        │   notes: "",                               │                    │
        │   priority: nil,                           │                    │
        │   remindersListID: 1,                      │                    │
        │   title: "Take a walk"                     │                    │
        │ )                                          │                    │
        └────────────────────────────────────────────┴────────────────────┘
        """
      }
    }

    @Test func basics() throws {
      let db = try Database()
      try db.execute(
        #sql(
          """
          CREATE TABLE "syncUps" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
            "isActive" BOOLEAN NOT NULL DEFAULT 1,
            "title" TEXT NOT NULL DEFAULT '',
            "createdAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          CREATE TABLE "attendees" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
            "name" TEXT NOT NULL DEFAULT '',
            "syncUpID" INTEGER NOT NULL,
            "createdAt" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
          )
          """
        )
      )
      try db.execute(
        SyncUp.insert()
      )
      #expect(
        try #require(
          try db.execute(SyncUp.all.select(\.createdAt)).first
        )
        .timeIntervalSinceNow < 1
      )

      #expect(
        try #require(try db.execute(SyncUp.all).first).id == 1
      )
    }

    @Table
    struct SyncUp {
      let id: Int
      var isActive: Bool
      var title: String
      @Column(as: Date.ISO8601Representation.self)
      var createdAt: Date
    }

    @Table
    struct Attendee {
      let id: Int
      var name: String
      var syncUpID: Int
      @Column(as: Date.ISO8601Representation.self)
      var createdAt: Date
    }
  }
}
