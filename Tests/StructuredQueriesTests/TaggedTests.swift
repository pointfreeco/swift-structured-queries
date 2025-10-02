#if StructuredQueriesTagged
  import Dependencies
  import Foundation
  import InlineSnapshotTesting
  import StructuredQueries
  import Tagged
  import Testing
  import _StructuredQueriesSQLite

  extension SnapshotTests {
    @Suite struct TaggedTests {
      @Test func basics() {
        assertQuery(
          Reminder
            .insert {
              Reminder(id: 11 as Reminder.ID, remindersListID: 1 as Tagged<RemindersList, Int>)
            }
            .returning(\.self)
        ) {
          """
          INSERT INTO "reminders"
          ("id", "remindersListID")
          VALUES
          (11, 1)
          RETURNING "id", "remindersListID"
          """
        } results: {
          """
          ┌────────────────────────────────────────┐
          │ SnapshotTests.TaggedTests.Reminder(    │
          │   id: Tagged(rawValue: 11),            │
          │   remindersListID: Tagged(rawValue: 1) │
          │ )                                      │
          └────────────────────────────────────────┘
          """
        }
      }

      @Table
      fileprivate struct Reminder {
        typealias ID = Tagged<Self, Int>

        let id: ID
        let remindersListID: Tagged<RemindersList, Int>
      }
    }
  }
#endif
