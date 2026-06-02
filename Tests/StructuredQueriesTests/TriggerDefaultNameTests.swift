import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct TriggerDefaultNameTests {
    @Dependency(\.defaultDatabase) var db

    @Test func basics() {
      let trigger = RemindersList.createTemporaryTrigger(
        after: .insert { new in
          Values(1)
        }
      )
      assertQuery(
        trigger
      ) {
        """
        CREATE TEMPORARY TRIGGER
          "after_insert_on_remindersLists@StructuredQueriesTests/TriggerDefaultNameTests.swift:13:57"
        AFTER INSERT ON "remindersLists"
        FOR EACH ROW BEGIN
          SELECT 1;
        END
        """
      }
      assertQuery(
        trigger.drop()
      ) {
        """
        DROP TRIGGER "after_insert_on_remindersLists@StructuredQueriesTests/TriggerDefaultNameTests.swift:13:57"
        """
      }
    }
  }
}
