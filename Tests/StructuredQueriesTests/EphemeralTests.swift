import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct EphemeralTests {
    @Test func basics() {
      assertInlineSnapshot(
        of: TestTable.select { $0.firstName + ", " + $0.lastName },
        as: .sql
      ) {
        """
        SELECT (("testTables"."firstName") || (', ')) || ("testTables"."lastName")
        FROM "testTables"
        """
      }
    }

    @Test func equality() {
      #expect(TestTable(displayName: "Blob Jr") != TestTable(displayName: "Blob Sr"))
    }
  }
}

@Table private struct TestTable: Equatable {
  var firstName = ""
  var lastName = ""
  @Ephemeral
  var displayName = ""
}
