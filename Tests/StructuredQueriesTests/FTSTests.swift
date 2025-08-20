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
          .select { ($0.title.highlight("**", "**"), $0.notes.snippet("**", "**", "...", 10)) }
      ) {
        """
        SELECT highlight("reminderTexts", (SELECT "cid" FROM pragma_table_info('reminderTexts') WHERE "name" = 'title'),
        '**', '**'), snippet("reminderTexts", (SELECT "cid" FROM pragma_table_info('reminderTexts') WHERE "name" = 'notes'),
        '**', '**', '...', 10)
        FROM "reminderTexts"
        WHERE ("reminderTexts" MATCH 'take OR apple')
        ORDER BY "reminderTexts"."rank"
        """
      } results: {
        """
        ┌──────────────────────┬───────────────────────┐
        │ "Groceries"          │ "...Eggs, **Apple**s" │
        │ "**Take** out trash" │ ""                    │
        │ "**Take** a walk"    │ ""                    │
        └──────────────────────┴───────────────────────┘
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

    @Test func columnMatch() {
      assertQuery(
        ReminderText
          .where { $0.title.match("take") }
      ) {
        """
        SELECT "reminderTexts"."reminderID", "reminderTexts"."title", "reminderTexts"."notes", "reminderTexts"."listID", "reminderTexts"."listTitle", "reminderTexts"."tags"
        FROM "reminderTexts"
        WHERE ("reminderTexts" MATCH 'title:"take"')
        """
      } results: {
        """
        ┌────────────────────────────┐
        │ ReminderText(              │
        │   reminderID: 4,           │
        │   title: "Take a walk",    │
        │   notes: "",               │
        │   listID: 1,               │
        │   listTitle: "Personal",   │
        │   tags: "car kids"         │
        │ )                          │
        ├────────────────────────────┤
        │ ReminderText(              │
        │   reminderID: 8,           │
        │   title: "Take out trash", │
        │   notes: "",               │
        │   listID: 2,               │
        │   listTitle: "Family",     │
        │   tags: ""                 │
        │ )                          │
        └────────────────────────────┘
        """
      }
    }

  }
}
