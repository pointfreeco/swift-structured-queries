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
    }
  }
}
