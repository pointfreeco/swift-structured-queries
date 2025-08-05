import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct FTSTests {
    @Test func basics() {
      assertQuery(
        ReminderText
          .where { $0.match("take OR apple") }
          .order(by: \.rank)
          .select { ($0.title.highlight("**", "**"), $0.notes.highlight("**", "**")) }
      ) {
        """
        SELECT highlight("reminderTexts", (SELECT "cid" FROM pragma_table_info('reminderTexts') WHERE "name" = 'title'),
        '**', '**'), highlight("reminderTexts", (SELECT "cid" FROM pragma_table_info('reminderTexts') WHERE "name" = 'notes'),
        '**', '**')
        FROM "reminderTexts"
        WHERE ("reminderTexts" MATCH 'take OR apple')
        ORDER BY "reminderTexts"."rank"
        """
      } results: {
        """
        ┌──────────────────────┬──────────────────────────┐
        │ "Groceries"          │ "Milk, Eggs, **Apple**s" │
        │ "**Take** out trash" │ ""                       │
        │ "**Take** a walk"    │ ""                       │
        └──────────────────────┴──────────────────────────┘
        """
      }
    }

    @Test func unranked() {
      assertQuery(
        ReminderText
          .select { ($0.listTitle, $0.rank) }
          .limit(1)
      ) {
        """
        SELECT "reminderTexts"."listTitle", "reminderTexts"."rank"
        FROM "reminderTexts"
        LIMIT 1
        """
      } results: {
        """
        ┌────────────┬─────┐
        │ "Personal" │ nil │
        └────────────┴─────┘
        """
      }
    }
  }
}
