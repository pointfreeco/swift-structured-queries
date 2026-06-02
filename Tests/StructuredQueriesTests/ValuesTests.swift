import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing

extension SnapshotTests {
  @Suite struct ValuesTests {
    @Dependency(\.defaultDatabase) var db

    @Test func basics() {
      assertQuery(Values(1, "Hello", true)) {
        """
        SELECT 1, 'Hello', 1
        """
      } results: {
        """
        ┌───┬─────────┬──────┐
        │ 1 │ "Hello" │ true │
        └───┴─────────┴──────┘
        """
      }
    }

    @Test func union() {
      assertQuery(
        Values(1, "Hello", true)
          .union(Values(2, "Goodbye", false))
      ) {
        """
        SELECT 1, 'Hello', 1
          UNION
        SELECT 2, 'Goodbye', 0
        """
      } results: {
        """
        ┌───┬───────────┬───────┐
        │ 1 │ "Hello"   │ true  │
        │ 2 │ "Goodbye" │ false │
        └───┴───────────┴───────┘
        """
      }
    }
  }
}
