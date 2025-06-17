import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct SelectTests {
    func compileTimeTests() {
      _ = Reminder.select(\.id)
      _ = Reminder.select { $0.id }
      _ = Reminder.select { ($0.id, $0.isCompleted) }
      _ = Reminder.all.select(\.id)
      _ = Reminder.all.select { $0.id }
      _ = Reminder.all.select { ($0.id, $0.isCompleted) }
      _ = Reminder.where(\.isCompleted).select(\.id)
      _ = Reminder.where(\.isCompleted).select { $0.id }
      _ = Reminder.where(\.isCompleted).select { ($0.id, $0.isCompleted) }

      let condition1 = Int?.some(1) == 2
      #expect(condition1 == false)
      let condition2 = Int?.some(1) != 2
      #expect(condition2 == true)
    }

    @Test func selectAll() {
      assertQuery(Tag.all) {
        """
        SELECT "tags"."id", "tags"."title"
        FROM "tags"
        """
      } results: {
        """
        ┌─────────────────────┐
        │ Tag(                │
        │   id: 1,            │
        │   title: "car"      │
        │ )                   │
        ├─────────────────────┤
        │ Tag(                │
        │   id: 2,            │
        │   title: "kids"     │
        │ )                   │
        ├─────────────────────┤
        │ Tag(                │
        │   id: 3,            │
        │   title: "someday"  │
        │ )                   │
        ├─────────────────────┤
        │ Tag(                │
        │   id: 4,            │
        │   title: "optional" │
        │ )                   │
        └─────────────────────┘
        """
      }
    }

    @Test func selectDistinct() {
      assertQuery(Reminder.distinct().select(\.priority)) {
        """
        SELECT DISTINCT "reminders"."priority"
        FROM "reminders"
        """
      } results: {
        """
        ┌─────────┐
        │ nil     │
        │ .high   │
        │ .low    │
        │ .medium │
        └─────────┘
        """
      }
    }

    @Test func select() {
      assertQuery(Reminder.select { ($0.id, $0.title) }) {
        """
        SELECT "reminders"."id", "reminders"."title"
        FROM "reminders"
        """
      } results: {
        """
        ┌────┬────────────────────────────┐
        │ 1  │ "Groceries"                │
        │ 2  │ "Haircut"                  │
        │ 3  │ "Doctor appointment"       │
        │ 4  │ "Take a walk"              │
        │ 5  │ "Buy concert tickets"      │
        │ 6  │ "Pick up kids from school" │
        │ 7  │ "Get laundry"              │
        │ 8  │ "Take out trash"           │
        │ 9  │ "Call accountant"          │
        │ 10 │ "Send weekly emails"       │
        └────┴────────────────────────────┘
        """
      }
    }

    @Test func selectSingleColumn() {
      assertQuery(Tag.select(\.title)) {
        """
        SELECT "tags"."title"
        FROM "tags"
        """
      } results: {
        """
        ┌────────────┐
        │ "car"      │
        │ "kids"     │
        │ "someday"  │
        │ "optional" │
        └────────────┘
        """
      }
    }

    @Test func selectChaining() {
      assertQuery(Tag.select(\.id).select(\.title)) {
        """
        SELECT "tags"."id", "tags"."title"
        FROM "tags"
        """
      } results: {
        """
        ┌───┬────────────┐
        │ 1 │ "car"      │
        │ 2 │ "kids"     │
        │ 3 │ "someday"  │
        │ 4 │ "optional" │
        └───┴────────────┘
        """
      }
    }

    @Test func selectChainingWithJoin() {
      assertQuery(
        Reminder
          .select(\.id)
          .join(RemindersList.select(\.id)) { $0.remindersListID.eq($1.id) }
      ) {
        """
        SELECT "reminders"."id", "remindersLists"."id"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")
        """
      } results: {
        """
        ┌────┬───┐
        │ 1  │ 1 │
        │ 2  │ 1 │
        │ 3  │ 1 │
        │ 4  │ 1 │
        │ 5  │ 1 │
        │ 6  │ 2 │
        │ 7  │ 2 │
        │ 8  │ 2 │
        │ 9  │ 3 │
        │ 10 │ 3 │
        └────┴───┘
        """
      }
    }

    @Test func join() {
      assertQuery(
        Reminder
          .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "remindersLists"."id", "remindersLists"."color", "remindersLists"."title"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")
        """
      } results: {
        #"""
        ┌────────────────────────────────────────────┬─────────────────────┐
        │ Reminder(                                  │ RemindersList(      │
        │   id: 1,                                   │   id: 1,            │
        │   assignedUserID: 1,                       │   color: 4889071,   │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │   title: "Personal" │
        │   isCompleted: false,                      │ )                   │
        │   isFlagged: false,                        │                     │
        │   notes: "Milk, Eggs, Apples",             │                     │
        │   priority: nil,                           │                     │
        │   remindersListID: 1,                      │                     │
        │   title: "Groceries"                       │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 2,                                   │   id: 1,            │
        │   assignedUserID: nil,                     │   color: 4889071,   │
        │   dueDate: Date(2000-12-30T00:00:00.000Z), │   title: "Personal" │
        │   isCompleted: false,                      │ )                   │
        │   isFlagged: true,                         │                     │
        │   notes: "",                               │                     │
        │   priority: nil,                           │                     │
        │   remindersListID: 1,                      │                     │
        │   title: "Haircut"                         │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 3,                                   │   id: 1,            │
        │   assignedUserID: nil,                     │   color: 4889071,   │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │   title: "Personal" │
        │   isCompleted: false,                      │ )                   │
        │   isFlagged: false,                        │                     │
        │   notes: "Ask about diet",                 │                     │
        │   priority: .high,                         │                     │
        │   remindersListID: 1,                      │                     │
        │   title: "Doctor appointment"              │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 4,                                   │   id: 1,            │
        │   assignedUserID: nil,                     │   color: 4889071,   │
        │   dueDate: Date(2000-06-25T00:00:00.000Z), │   title: "Personal" │
        │   isCompleted: true,                       │ )                   │
        │   isFlagged: false,                        │                     │
        │   notes: "",                               │                     │
        │   priority: nil,                           │                     │
        │   remindersListID: 1,                      │                     │
        │   title: "Take a walk"                     │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 5,                                   │   id: 1,            │
        │   assignedUserID: nil,                     │   color: 4889071,   │
        │   dueDate: nil,                            │   title: "Personal" │
        │   isCompleted: false,                      │ )                   │
        │   isFlagged: false,                        │                     │
        │   notes: "",                               │                     │
        │   priority: nil,                           │                     │
        │   remindersListID: 1,                      │                     │
        │   title: "Buy concert tickets"             │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 6,                                   │   id: 2,            │
        │   assignedUserID: nil,                     │   color: 15567157,  │
        │   dueDate: Date(2001-01-03T00:00:00.000Z), │   title: "Family"   │
        │   isCompleted: false,                      │ )                   │
        │   isFlagged: true,                         │                     │
        │   notes: "",                               │                     │
        │   priority: .high,                         │                     │
        │   remindersListID: 2,                      │                     │
        │   title: "Pick up kids from school"        │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 7,                                   │   id: 2,            │
        │   assignedUserID: nil,                     │   color: 15567157,  │
        │   dueDate: Date(2000-12-30T00:00:00.000Z), │   title: "Family"   │
        │   isCompleted: true,                       │ )                   │
        │   isFlagged: false,                        │                     │
        │   notes: "",                               │                     │
        │   priority: .low,                          │                     │
        │   remindersListID: 2,                      │                     │
        │   title: "Get laundry"                     │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 8,                                   │   id: 2,            │
        │   assignedUserID: nil,                     │   color: 15567157,  │
        │   dueDate: Date(2001-01-05T00:00:00.000Z), │   title: "Family"   │
        │   isCompleted: false,                      │ )                   │
        │   isFlagged: false,                        │                     │
        │   notes: "",                               │                     │
        │   priority: .high,                         │                     │
        │   remindersListID: 2,                      │                     │
        │   title: "Take out trash"                  │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 9,                                   │   id: 3,            │
        │   assignedUserID: nil,                     │   color: 11689427,  │
        │   dueDate: Date(2001-01-03T00:00:00.000Z), │   title: "Business" │
        │   isCompleted: false,                      │ )                   │
        │   isFlagged: false,                        │                     │
        │   notes: """                               │                     │
        │     Status of tax return                   │                     │
        │     Expenses for next year                 │                     │
        │     Changing payroll company               │                     │
        │     """,                                   │                     │
        │   priority: nil,                           │                     │
        │   remindersListID: 3,                      │                     │
        │   title: "Call accountant"                 │                     │
        │ )                                          │                     │
        ├────────────────────────────────────────────┼─────────────────────┤
        │ Reminder(                                  │ RemindersList(      │
        │   id: 10,                                  │   id: 3,            │
        │   assignedUserID: nil,                     │   color: 11689427,  │
        │   dueDate: Date(2000-12-30T00:00:00.000Z), │   title: "Business" │
        │   isCompleted: true,                       │ )                   │
        │   isFlagged: false,                        │                     │
        │   notes: "",                               │                     │
        │   priority: .medium,                       │                     │
        │   remindersListID: 3,                      │                     │
        │   title: "Send weekly emails"              │                     │
        │ )                                          │                     │
        └────────────────────────────────────────────┴─────────────────────┘
        """#
      }

      assertQuery(
        RemindersList
          .join(Reminder.all) { $0.id.eq($1.remindersListID) }
          .select { ($0.title, $1.title) }
      ) {
        """
        SELECT "remindersLists"."title", "reminders"."title"
        FROM "remindersLists"
        JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
        """
      } results: {
        """
        ┌────────────┬────────────────────────────┐
        │ "Personal" │ "Groceries"                │
        │ "Personal" │ "Haircut"                  │
        │ "Personal" │ "Doctor appointment"       │
        │ "Personal" │ "Take a walk"              │
        │ "Personal" │ "Buy concert tickets"      │
        │ "Family"   │ "Pick up kids from school" │
        │ "Family"   │ "Get laundry"              │
        │ "Family"   │ "Take out trash"           │
        │ "Business" │ "Call accountant"          │
        │ "Business" │ "Send weekly emails"       │
        └────────────┴────────────────────────────┘
        """
      }

      assertQuery(
        Reminder.all
          .leftJoin(User.all) { $0.assignedUserID.eq($1.id) }
          .select { ($0.title, $1.name) }
          .limit(2)
      ) {
        """
        SELECT "reminders"."title", "users"."name"
        FROM "reminders"
        LEFT JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")
        LIMIT 2
        """
      } results: {
        """
        ┌─────────────┬────────┐
        │ "Groceries" │ "Blob" │
        │ "Haircut"   │ nil    │
        └─────────────┴────────┘
        """
      }

      assertQuery(
        User.all
          .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
          .limit(2)
      ) {
        """
        SELECT "users"."id", "users"."name", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "users"
        RIGHT JOIN "reminders" ON ("users"."id" IS "reminders"."assignedUserID")
        LIMIT 2
        """
      } results: {
        """
        ┌────────────────┬────────────────────────────────────────────┐
        │ User(          │ Reminder(                                  │
        │   id: 1,       │   id: 1,                                   │
        │   name: "Blob" │   assignedUserID: 1,                       │
        │ )              │   dueDate: Date(2001-01-01T00:00:00.000Z), │
        │                │   isCompleted: false,                      │
        │                │   isFlagged: false,                        │
        │                │   notes: "Milk, Eggs, Apples",             │
        │                │   priority: nil,                           │
        │                │   remindersListID: 1,                      │
        │                │   title: "Groceries"                       │
        │                │ )                                          │
        ├────────────────┼────────────────────────────────────────────┤
        │ nil            │ Reminder(                                  │
        │                │   id: 2,                                   │
        │                │   assignedUserID: nil,                     │
        │                │   dueDate: Date(2000-12-30T00:00:00.000Z), │
        │                │   isCompleted: false,                      │
        │                │   isFlagged: true,                         │
        │                │   notes: "",                               │
        │                │   priority: nil,                           │
        │                │   remindersListID: 1,                      │
        │                │   title: "Haircut"                         │
        │                │ )                                          │
        └────────────────┴────────────────────────────────────────────┘
        """
      }

      assertQuery(
        User.all
          .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
          .limit(2)
          .select { ($0, $1) }
      ) {
        """
        SELECT "users"."id", "users"."name", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "users"
        RIGHT JOIN "reminders" ON ("users"."id" IS "reminders"."assignedUserID")
        LIMIT 2
        """
      } results: {
        """
        ┌────────────────┬────────────────────────────────────────────┐
        │ User(          │ Reminder(                                  │
        │   id: 1,       │   id: 1,                                   │
        │   name: "Blob" │   assignedUserID: 1,                       │
        │ )              │   dueDate: Date(2001-01-01T00:00:00.000Z), │
        │                │   isCompleted: false,                      │
        │                │   isFlagged: false,                        │
        │                │   notes: "Milk, Eggs, Apples",             │
        │                │   priority: nil,                           │
        │                │   remindersListID: 1,                      │
        │                │   title: "Groceries"                       │
        │                │ )                                          │
        ├────────────────┼────────────────────────────────────────────┤
        │ nil            │ Reminder(                                  │
        │                │   id: 2,                                   │
        │                │   assignedUserID: nil,                     │
        │                │   dueDate: Date(2000-12-30T00:00:00.000Z), │
        │                │   isCompleted: false,                      │
        │                │   isFlagged: true,                         │
        │                │   notes: "",                               │
        │                │   priority: nil,                           │
        │                │   remindersListID: 1,                      │
        │                │   title: "Haircut"                         │
        │                │ )                                          │
        └────────────────┴────────────────────────────────────────────┘
        """
      }

      assertQuery(
        User.all
          .rightJoin(Reminder.all) { $0.id.is($1.assignedUserID) }
          .select { ($1.title, $0.name) }
          .limit(2)
      ) {
        """
        SELECT "reminders"."title", "users"."name"
        FROM "users"
        RIGHT JOIN "reminders" ON ("users"."id" IS "reminders"."assignedUserID")
        LIMIT 2
        """
      } results: {
        """
        ┌─────────────┬────────┐
        │ "Groceries" │ "Blob" │
        │ "Haircut"   │ nil    │
        └─────────────┴────────┘
        """
      }

      assertQuery(
        Reminder.all
          .fullJoin(User.all) { $0.assignedUserID.eq($1.id) }
          .select { ($0.title, $1.name) }
          .limit(2)
      ) {
        """
        SELECT "reminders"."title", "users"."name"
        FROM "reminders"
        FULL JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")
        LIMIT 2
        """
      } results: {
        """
        ┌─────────────┬────────┐
        │ "Groceries" │ "Blob" │
        │ "Haircut"   │ nil    │
        └─────────────┴────────┘
        """
      }
    }

    @Test func `where`() {
      assertQuery(
        Reminder.where(\.isCompleted)
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "reminders"
        WHERE "reminders"."isCompleted"
        """
      } results: {
        """
        ┌────────────────────────────────────────────┐
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
        """
      }
    }

    @Test func whereConditionalTrue() {
      let includeConditional = true
      assertQuery(
        Reminder.all
          .select(\.id)
          .where {
            if includeConditional {
              $0.isCompleted
            }
          }
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE "reminders"."isCompleted"
        """
      } results: {
        """
        ┌────┐
        │ 4  │
        │ 7  │
        │ 10 │
        └────┘
        """
      }
    }

    @Test func whereConditionalFalse() {
      let includeConditional = false
      assertQuery(
        Reminder.all
          .select(\.id)
          .where {
            if includeConditional {
              $0.isCompleted
            }
          }
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        """
      } results: {
        """
        ┌────┐
        │ 1  │
        │ 2  │
        │ 3  │
        │ 4  │
        │ 5  │
        │ 6  │
        │ 7  │
        │ 8  │
        │ 9  │
        │ 10 │
        └────┘
        """
      }
    }

    @Test func whereAnd() {
      assertQuery(
        Reminder.where(\.isCompleted).and(.where(\.isFlagged))
          .count()
      ) {
        """
        SELECT count(*)
        FROM "reminders"
        WHERE ("reminders"."isCompleted") AND ("reminders"."isFlagged")
        """
      } results: {
        """
        ┌───┐
        │ 0 │
        └───┘
        """
      }
    }

    @Test func whereOr() {
      assertQuery(
        Reminder.where(\.isCompleted).or(.where(\.isFlagged))
          .count()
      ) {
        """
        SELECT count(*)
        FROM "reminders"
        WHERE ("reminders"."isCompleted") OR ("reminders"."isFlagged")
        """
      } results: {
        """
        ┌───┐
        │ 5 │
        └───┘
        """
      }
    }

    @Test func group() {
      assertQuery(
        Reminder.select { ($0.isCompleted, $0.id.count()) }.group(by: \.isCompleted)
      ) {
        """
        SELECT "reminders"."isCompleted", count("reminders"."id")
        FROM "reminders"
        GROUP BY "reminders"."isCompleted"
        """
      } results: {
        """
        ┌───────┬───┐
        │ false │ 7 │
        │ true  │ 3 │
        └───────┴───┘
        """
      }

      assertQuery(
        Reminder.select { ($0.isCompleted, $0.id.count()) }.group { #sql("\($0.isCompleted)") }
      ) {
        """
        SELECT "reminders"."isCompleted", count("reminders"."id")
        FROM "reminders"
        GROUP BY "reminders"."isCompleted"
        """
      } results: {
        """
        ┌───────┬───┐
        │ false │ 7 │
        │ true  │ 3 │
        └───────┴───┘
        """
      }
    }

    @Test func having() {
      assertQuery(
        Reminder
          .select { ($0.isCompleted, $0.id.count()) }
          .group(by: \.isCompleted)
          .having { $0.id.count() > 3 }
      ) {
        """
        SELECT "reminders"."isCompleted", count("reminders"."id")
        FROM "reminders"
        GROUP BY "reminders"."isCompleted"
        HAVING (count("reminders"."id") > 3)
        """
      } results: {
        """
        ┌───────┬───┐
        │ false │ 7 │
        └───────┴───┘
        """
      }
    }

    @Test func havingConditionalTrue() {
      let includeConditional: Bool = true
      assertQuery(
        Reminder
          .select { ($0.isCompleted, $0.id.count()) }
          .group(by: \.isCompleted)
          .having {
            if includeConditional {
              $0.id.count() > 3
            }
          }
      ) {
        """
        SELECT "reminders"."isCompleted", count("reminders"."id")
        FROM "reminders"
        GROUP BY "reminders"."isCompleted"
        HAVING (count("reminders"."id") > 3)
        """
      } results: {
        """
        ┌───────┬───┐
        │ false │ 7 │
        └───────┴───┘
        """
      }
    }

    @Test func havingConditionalFalse() {
      let includeConditional: Bool = false
      assertQuery(
        Reminder
          .select { ($0.isCompleted, $0.id.count()) }
          .group(by: \.isCompleted)
          .having {
            if includeConditional {
              $0.id.count() > 3
            }
          }
      ) {
        """
        SELECT "reminders"."isCompleted", count("reminders"."id")
        FROM "reminders"
        GROUP BY "reminders"."isCompleted"
        """
      } results: {
        """
        ┌───────┬───┐
        │ false │ 7 │
        │ true  │ 3 │
        └───────┴───┘
        """
      }
    }

    @Test func order() {
      assertQuery(
        Reminder
          .select(\.title)
          .order(by: \.title)
      ) {
        """
        SELECT "reminders"."title"
        FROM "reminders"
        ORDER BY "reminders"."title"
        """
      } results: {
        """
        ┌────────────────────────────┐
        │ "Buy concert tickets"      │
        │ "Call accountant"          │
        │ "Doctor appointment"       │
        │ "Get laundry"              │
        │ "Groceries"                │
        │ "Haircut"                  │
        │ "Pick up kids from school" │
        │ "Send weekly emails"       │
        │ "Take a walk"              │
        │ "Take out trash"           │
        └────────────────────────────┘
        """
      }
      assertQuery(
        Reminder
          .select { ($0.isCompleted, $0.dueDate) }
          .order { ($0.isCompleted.asc(), $0.dueDate.desc()) }
      ) {
        """
        SELECT "reminders"."isCompleted", "reminders"."dueDate"
        FROM "reminders"
        ORDER BY "reminders"."isCompleted" ASC, "reminders"."dueDate" DESC
        """
      } results: {
        """
        ┌───────┬────────────────────────────────┐
        │ false │ Date(2001-01-05T00:00:00.000Z) │
        │ false │ Date(2001-01-03T00:00:00.000Z) │
        │ false │ Date(2001-01-03T00:00:00.000Z) │
        │ false │ Date(2001-01-01T00:00:00.000Z) │
        │ false │ Date(2001-01-01T00:00:00.000Z) │
        │ false │ Date(2000-12-30T00:00:00.000Z) │
        │ false │ nil                            │
        │ true  │ Date(2000-12-30T00:00:00.000Z) │
        │ true  │ Date(2000-12-30T00:00:00.000Z) │
        │ true  │ Date(2000-06-25T00:00:00.000Z) │
        └───────┴────────────────────────────────┘
        """
      }
      assertQuery(
        Reminder
          .select { ($0.priority, $0.dueDate) }
          .order {
            if true {
              (
                $0.priority.asc(nulls: .last),
                $0.dueDate.desc(nulls: .first),
                $0.title.collate(.nocase).desc()
              )
            }
          }
      ) {
        """
        SELECT "reminders"."priority", "reminders"."dueDate"
        FROM "reminders"
        ORDER BY "reminders"."priority" ASC NULLS LAST, "reminders"."dueDate" DESC NULLS FIRST, ("reminders"."title" COLLATE "NOCASE") DESC
        """
      } results: {
        """
        ┌─────────┬────────────────────────────────┐
        │ .low    │ Date(2000-12-30T00:00:00.000Z) │
        │ .medium │ Date(2000-12-30T00:00:00.000Z) │
        │ .high   │ Date(2001-01-05T00:00:00.000Z) │
        │ .high   │ Date(2001-01-03T00:00:00.000Z) │
        │ .high   │ Date(2001-01-01T00:00:00.000Z) │
        │ nil     │ nil                            │
        │ nil     │ Date(2001-01-03T00:00:00.000Z) │
        │ nil     │ Date(2001-01-01T00:00:00.000Z) │
        │ nil     │ Date(2000-12-30T00:00:00.000Z) │
        │ nil     │ Date(2000-06-25T00:00:00.000Z) │
        └─────────┴────────────────────────────────┘
        """
      }
    }

    @Test func limit() {
      assertQuery(Reminder.select(\.id).limit(2)) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        LIMIT 2
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        │ 2 │
        └───┘
        """
      }
      assertQuery(Reminder.select(\.id).limit(2, offset: 2)) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        LIMIT 2 OFFSET 2
        """
      } results: {
        """
        ┌───┐
        │ 3 │
        │ 4 │
        └───┘
        """
      }
    }

    @Test func count() {
      assertQuery(Reminder.count()) {
        """
        SELECT count(*)
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

    @Test func countFilter() {
      assertQuery(Reminder.count { !$0.isCompleted }) {
        """
        SELECT count(*) FILTER (WHERE NOT ("reminders"."isCompleted"))
        FROM "reminders"
        """
      } results: {
        """
        ┌───┐
        │ 7 │
        └───┘
        """
      }
    }

    @Test func map() {
      assertQuery(Reminder.limit(1).select { ($0.id, $0.title) }.map { ($1, $0) }) {
        """
        SELECT "reminders"."title", "reminders"."id"
        FROM "reminders"
        LIMIT 1
        """
      } results: {
        """
        ┌─────────────┬───┐
        │ "Groceries" │ 1 │
        └─────────────┴───┘
        """
      }
      assertQuery(Reminder.limit(1).select { ($0.id, $0.title) }.map { _, _ in }) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "reminders"
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
      assertQuery(Reminder.limit(1).select { ($0.id, $0.title) }.map { ($1, $0) }) {
        """
        SELECT "reminders"."title", "reminders"."id"
        FROM "reminders"
        LIMIT 1
        """
      } results: {
        """
        ┌─────────────┬───┐
        │ "Groceries" │ 1 │
        └─────────────┴───┘
        """
      }
    }

    #if compiler(>=6.1)
      @Test func dynamicMember() {
        assertQuery(
          RemindersList
            .limit(1)
            .select(\.title)
            .withReminderCount
        ) {
          """
          SELECT "remindersLists"."title", count("reminders"."id")
          FROM "remindersLists"
          JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
          GROUP BY "remindersLists"."id"
          LIMIT 1
          """
        } results: {
          """
          ┌────────────┬───┐
          │ "Personal" │ 5 │
          └────────────┴───┘
          """
        }
      }
    #endif

    @Test func selfJoin() {
      enum R1: AliasName {}
      enum R2: AliasName {}
      assertQuery(
        Reminder.as(R1.self)
          .join(Reminder.as(R2.self).all) { $0.id.eq($1.id) }
          .limit(1)
      ) {
        """
        SELECT "r1s"."id", "r1s"."assignedUserID", "r1s"."dueDate", "r1s"."isCompleted", "r1s"."isFlagged", "r1s"."notes", "r1s"."priority", "r1s"."remindersListID", "r1s"."title", "r2s"."id", "r2s"."assignedUserID", "r2s"."dueDate", "r2s"."isCompleted", "r2s"."isFlagged", "r2s"."notes", "r2s"."priority", "r2s"."remindersListID", "r2s"."title"
        FROM "reminders" AS "r1s"
        JOIN "reminders" AS "r2s" ON ("r1s"."id" = "r2s"."id")
        LIMIT 1
        """
      } results: {
        """
        ┌────────────────────────────────────────────┬────────────────────────────────────────────┐
        │ Reminder(                                  │ Reminder(                                  │
        │   id: 1,                                   │   id: 1,                                   │
        │   assignedUserID: 1,                       │   assignedUserID: 1,                       │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │   dueDate: Date(2001-01-01T00:00:00.000Z), │
        │   isCompleted: false,                      │   isCompleted: false,                      │
        │   isFlagged: false,                        │   isFlagged: false,                        │
        │   notes: "Milk, Eggs, Apples",             │   notes: "Milk, Eggs, Apples",             │
        │   priority: nil,                           │   priority: nil,                           │
        │   remindersListID: 1,                      │   remindersListID: 1,                      │
        │   title: "Groceries"                       │   title: "Groceries"                       │
        │ )                                          │ )                                          │
        └────────────────────────────────────────────┴────────────────────────────────────────────┘
        """
      }
    }

    @Test func selfLeftJoinSelect() {
      enum R1: AliasName {}
      enum R2: AliasName {}
      assertQuery(
        Reminder.as(R1.self)
          .leftJoin(Reminder.as(R2.self).all) { $0.id.eq($1.id) }
          .limit(1)
          .select { ($0.id, $1.id) }
      ) {
        """
        SELECT "r1s"."id", "r2s"."id"
        FROM "reminders" AS "r1s"
        LEFT JOIN "reminders" AS "r2s" ON ("r1s"."id" = "r2s"."id")
        LIMIT 1
        """
      } results: {
        """
        ┌───┬───┐
        │ 1 │ 1 │
        └───┴───┘
        """
      }

      assertQuery(
        Reminder.as(R1.self)
          .group(by: \.id)
          .leftJoin(Reminder.as(R2.self).all) { $0.id.eq($1.id) }
          .limit(1)
          .select { ($0, $1.jsonGroupArray()) }
      ) {
        """
        SELECT "r1s"."id", "r1s"."assignedUserID", "r1s"."dueDate", "r1s"."isCompleted", "r1s"."isFlagged", "r1s"."notes", "r1s"."priority", "r1s"."remindersListID", "r1s"."title", json_group_array(CASE WHEN ("r2s"."id" IS NOT NULL) THEN json_object('id', json_quote("r2s"."id"), 'assignedUserID', json_quote("r2s"."assignedUserID"), 'dueDate', json_quote("r2s"."dueDate"), 'isCompleted', json(CASE "r2s"."isCompleted" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'isFlagged', json(CASE "r2s"."isFlagged" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'notes', json_quote("r2s"."notes"), 'priority', json_quote("r2s"."priority"), 'remindersListID', json_quote("r2s"."remindersListID"), 'title', json_quote("r2s"."title")) END)
        FROM "reminders" AS "r1s"
        LEFT JOIN "reminders" AS "r2s" ON ("r1s"."id" = "r2s"."id")
        GROUP BY "r1s"."id"
        LIMIT 1
        """
      } results: {
        """
        ┌────────────────────────────────────────────┬────────────────────────────────────────────────┐
        │ Reminder(                                  │ [                                              │
        │   id: 1,                                   │   [0]: TableAlias(                             │
        │   assignedUserID: 1,                       │     base: Reminder(                            │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │       id: 1,                                   │
        │   isCompleted: false,                      │       assignedUserID: 1,                       │
        │   isFlagged: false,                        │       dueDate: Date(2001-01-01T00:00:00.000Z), │
        │   notes: "Milk, Eggs, Apples",             │       isCompleted: false,                      │
        │   priority: nil,                           │       isFlagged: false,                        │
        │   remindersListID: 1,                      │       notes: "Milk, Eggs, Apples",             │
        │   title: "Groceries"                       │       priority: nil,                           │
        │ )                                          │       remindersListID: 1,                      │
        │                                            │       title: "Groceries"                       │
        │                                            │     )                                          │
        │                                            │   )                                            │
        │                                            │ ]                                              │
        └────────────────────────────────────────────┴────────────────────────────────────────────────┘
        """
      }
    }

    @Test func `case`() {
      assertQuery(
        Values(
          Case()
            .when(true, then: "present")
            .else("unknown")
        )
      ) {
        """
        SELECT CASE WHEN 1 THEN 'present' ELSE 'unknown' END
        """
      } results: {
        """
        ┌───────────┐
        │ "present" │
        └───────────┘
        """
      }
    }

    @Table @Selection
    struct VecExample {
      let rowid: Int
      let distance: Double
    }

    @Test func vec0() {
      let xs = [0.890, 0.544, 0.825, 0.961, 0.358, 0.0196, 0.521, 0.175]
      assertInlineSnapshot(
        of:
          VecExample
          .where { _ in
            #sql("sample_embedding match \(#bind(xs, as: [Double].JSONRepresentation.self))")
          }
          .order(by: \.distance)
          .limit(2),
        as: .sql
      ) {
        """
        SELECT "vecExamples"."rowid", "vecExamples"."distance"
        FROM "vecExamples"
        WHERE sample_embedding match '[
          0.89,
          0.544,
          0.825,
          0.961,
          0.358,
          0.0196,
          0.521,
          0.175
        ]'
        ORDER BY "vecExamples"."distance"
        LIMIT 2
        """
      }
    }

    @Test func reusableHelperOnLeftJoinedTable() {
      assertQuery(
        RemindersList
          .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
          .where { $1.isHighPriority.ifnull(false) }
      ) {
        """
        SELECT "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "remindersLists"
        LEFT JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
        WHERE ifnull(("reminders"."priority" IS 3), 0)
        """
      } results: {
        """
        ┌─────────────────────┬────────────────────────────────────────────┐
        │ RemindersList(      │ Reminder(                                  │
        │   id: 1,            │   id: 3,                                   │
        │   color: 4889071,   │   assignedUserID: nil,                     │
        │   title: "Personal" │   dueDate: Date(2001-01-01T00:00:00.000Z), │
        │ )                   │   isCompleted: false,                      │
        │                     │   isFlagged: false,                        │
        │                     │   notes: "Ask about diet",                 │
        │                     │   priority: .high,                         │
        │                     │   remindersListID: 1,                      │
        │                     │   title: "Doctor appointment"              │
        │                     │ )                                          │
        ├─────────────────────┼────────────────────────────────────────────┤
        │ RemindersList(      │ Reminder(                                  │
        │   id: 2,            │   id: 6,                                   │
        │   color: 15567157,  │   assignedUserID: nil,                     │
        │   title: "Family"   │   dueDate: Date(2001-01-03T00:00:00.000Z), │
        │ )                   │   isCompleted: false,                      │
        │                     │   isFlagged: true,                         │
        │                     │   notes: "",                               │
        │                     │   priority: .high,                         │
        │                     │   remindersListID: 2,                      │
        │                     │   title: "Pick up kids from school"        │
        │                     │ )                                          │
        ├─────────────────────┼────────────────────────────────────────────┤
        │ RemindersList(      │ Reminder(                                  │
        │   id: 2,            │   id: 8,                                   │
        │   color: 15567157,  │   assignedUserID: nil,                     │
        │   title: "Family"   │   dueDate: Date(2001-01-05T00:00:00.000Z), │
        │ )                   │   isCompleted: false,                      │
        │                     │   isFlagged: false,                        │
        │                     │   notes: "",                               │
        │                     │   priority: .high,                         │
        │                     │   remindersListID: 2,                      │
        │                     │   title: "Take out trash"                  │
        │                     │ )                                          │
        └─────────────────────┴────────────────────────────────────────────┘
        """
      }
    }

    @Test func reusableStaticHelperOnDraft() {
      assertQuery(
        Reminder.Draft.incomplete.select(\.id)
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted")
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        │ 2 │
        │ 3 │
        │ 5 │
        │ 6 │
        │ 8 │
        │ 9 │
        └───┘
        """
      }
      assertQuery(
        Reminder.Draft.where { _ in true }.incomplete.select(\.id)
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE 1 AND NOT ("reminders"."isCompleted")
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        │ 2 │
        │ 3 │
        │ 5 │
        │ 6 │
        │ 8 │
        │ 9 │
        └───┘
        """
      }
      assertQuery(
        Reminder.Draft.select(\.id).incomplete
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted")
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        │ 2 │
        │ 3 │
        │ 5 │
        │ 6 │
        │ 8 │
        │ 9 │
        └───┘
        """
      }
      assertQuery(
        Reminder.Draft.all.incomplete.select(\.id)
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted")
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        │ 2 │
        │ 3 │
        │ 5 │
        │ 6 │
        │ 8 │
        │ 9 │
        └───┘
        """
      }
    }

    @Test func reusableColumnHelperOnDraft() {
      assertQuery(
        Reminder.Draft.select(\.isHighPriority)
      ) {
        """
        SELECT ("reminders"."priority" IS 3)
        FROM "reminders"
        """
      } results: {
        """
        ┌───────┐
        │ false │
        │ false │
        │ true  │
        │ false │
        │ false │
        │ true  │
        │ false │
        │ true  │
        │ false │
        │ false │
        └───────┘
        """
      }
    }

    @Test func optionalMapAndFlatMap() {
      do {
        let query: some Statement<Bool?> = Reminder.select {
          $0.priority.map { $0 < Priority.high }
        }
        assertQuery(query) {
          """
          SELECT ("reminders"."priority" < 3)
          FROM "reminders"
          """
        } results: {
          """
          ┌───────┐
          │ nil   │
          │ nil   │
          │ false │
          │ nil   │
          │ nil   │
          │ false │
          │ true  │
          │ false │
          │ nil   │
          │ true  │
          └───────┘
          """
        }
      }
      do {
        let query: some Statement<Priority?> = Reminder.select { $0.priority.flatMap { $0.max() } }
        assertQuery(query) {
          """
          SELECT max("reminders"."priority")
          FROM "reminders"
          """
        } results: {
          """
          ┌───────┐
          │ .high │
          └───────┘
          """
        }
      }
    }
  }
}

extension Reminder.TableColumns {
  var isHighPriority: some QueryExpression<Bool> {
    self.priority == Priority.high
  }
}
