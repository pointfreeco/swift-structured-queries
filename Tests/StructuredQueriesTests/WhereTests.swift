import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
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

    @Test(.snapshots(record: .never)) func emptyResults() {
      withKnownIssue("This assert should fail") {
        assertQuery(
          Reminder.where { $0.isCompleted && !$0.isCompleted }
        ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."isCompleted") AND ("reminders"."isFlagged")
        """
        } results: {
          """
          Results
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

    @Test func optionalBoolean() throws {
      @Dependency(\.defaultDatabase) var db
      let remindersListIDs = try db.execute(
        RemindersList.insert {
          RemindersList.Draft(title: "New list")
        }
        .returning(\.id)
      )
      let remindersListID = try #require(remindersListIDs.first)

      assertQuery(
        RemindersList
          .find(remindersListID)
          .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
          .where { $1.isCompleted }
      ) {
        """
        SELECT "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "remindersLists"
        LEFT JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
        WHERE ("remindersLists"."id" = 4) AND "reminders"."isCompleted"
        """
      }
    }
  }
}
