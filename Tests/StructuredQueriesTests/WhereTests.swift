import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing

extension SnapshotTests {
  @Suite struct WhereTests {
    @Test func and() {
      assertQuery(
        Reminder.where(\.isCompleted).and(Reminder.where(\.isFlagged))
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
      assertQuery(
        (Reminder.where(\.isCompleted) && Reminder.where(\.isFlagged))
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

    @Test func emptyResults() {
      withKnownIssue("This assert should fail") {
        assertQuery(
          Reminder.where(\.isCompleted).and(Reminder.where(\.isFlagged))
        ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."isCompleted") AND ("reminders"."isFlagged")
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
    }

    @Test func or() {
      assertQuery(
        Reminder.where(\.isCompleted).or(Reminder.where(\.isFlagged))
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
      assertQuery(
        (Reminder.where(\.isCompleted) || Reminder.where(\.isFlagged))
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

    @Test func not() {
      assertQuery(
        Reminder.where(\.isCompleted).not()
          .count()
      ) {
        """
        SELECT count(*)
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted")
        """
      } results: {
        """
        ┌───┐
        │ 7 │
        └───┘
        """
      }
      assertQuery(
        (!Reminder.where(\.isCompleted))
          .count()
      ) {
        """
        SELECT count(*)
        FROM "reminders"
        WHERE NOT ("reminders"."isCompleted")
        """
      } results: {
        """
        ┌───┐
        │ 7 │
        └───┘
        """
      }
    }
  }
}
