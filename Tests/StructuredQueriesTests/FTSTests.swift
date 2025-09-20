import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
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

    @Test func bm25() {
      assertQuery(
        ReminderText
          .where { $0.match("Week") }
          .order { $0.bm25([\.title: 10, \.notes: 5, \.tags: 2]) }
      ) {
        """
        SELECT "reminderTexts"."reminderID", "reminderTexts"."title", "reminderTexts"."notes", "reminderTexts"."listID", "reminderTexts"."listTitle", "reminderTexts"."tags"
        FROM "reminderTexts"
        WHERE ("reminderTexts" MATCH 'Week')
        ORDER BY bm25("reminderTexts", (SELECT CASE "name" WHEN 'title' THEN 10.0 WHEN 'notes' THEN 5.0 WHEN 'tags' THEN 2.0 ELSE 1 END FROM pragma_table_info('reminderTexts') WHERE "cid" = 0), (SELECT CASE "name" WHEN 'title' THEN 10.0 WHEN 'notes' THEN 5.0 WHEN 'tags' THEN 2.0 ELSE 1 END FROM pragma_table_info('reminderTexts') WHERE "cid" = 1), (SELECT CASE "name" WHEN 'title' THEN 10.0 WHEN 'notes' THEN 5.0 WHEN 'tags' THEN 2.0 ELSE 1 END FROM pragma_table_info('reminderTexts') WHERE "cid" = 2), (SELECT CASE "name" WHEN 'title' THEN 10.0 WHEN 'notes' THEN 5.0 WHEN 'tags' THEN 2.0 ELSE 1 END FROM pragma_table_info('reminderTexts') WHERE "cid" = 3), (SELECT CASE "name" WHEN 'title' THEN 10.0 WHEN 'notes' THEN 5.0 WHEN 'tags' THEN 2.0 ELSE 1 END FROM pragma_table_info('reminderTexts') WHERE "cid" = 4), (SELECT CASE "name" WHEN 'title' THEN 10.0 WHEN 'notes' THEN 5.0 WHEN 'tags' THEN 2.0 ELSE 1 END FROM pragma_table_info('reminderTexts') WHERE "cid" = 5))
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ ReminderText(                  │
        │   reminderID: 10,              │
        │   title: "Send weekly emails", │
        │   notes: "",                   │
        │   listID: 3,                   │
        │   listTitle: "Business",       │
        │   tags: ""                     │
        │ )                              │
        └────────────────────────────────┘
        """
      }
      assertQuery(
        ReminderText
          .where { $0.match("Week") }
          .order { $0.bm25() }
      ) {
        """
        SELECT "reminderTexts"."reminderID", "reminderTexts"."title", "reminderTexts"."notes", "reminderTexts"."listID", "reminderTexts"."listTitle", "reminderTexts"."tags"
        FROM "reminderTexts"
        WHERE ("reminderTexts" MATCH 'Week')
        ORDER BY bm25("reminderTexts")
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ ReminderText(                  │
        │   reminderID: 10,              │
        │   title: "Send weekly emails", │
        │   notes: "",                   │
        │   listID: 3,                   │
        │   listTitle: "Business",       │
        │   tags: ""                     │
        │ )                              │
        └────────────────────────────────┘
        """
      }
    }

    @Test func outerJoin() {
      assertQuery(
        Reminder
          .leftJoin(ReminderText.all) { $0.rowid.eq($1.rowid) }
          .select { $1.tags.highlight("**", "**") }
          .order { $1.bm25() }
      ) {
        """
        SELECT highlight("reminderTexts", (SELECT "cid" FROM pragma_table_info('reminderTexts') WHERE "name" = 'tags'),
        '**', '**')
        FROM "reminders"
        LEFT JOIN "reminderTexts" ON ("reminders"."rowid") = ("reminderTexts"."rowid")
        ORDER BY bm25("reminderTexts")
        """
      } results: {
        """
        ┌────────────────────┐
        │ "someday optional" │
        │ "someday optional" │
        │ ""                 │
        │ "car kids"         │
        │ ""                 │
        │ ""                 │
        │ ""                 │
        │ ""                 │
        │ ""                 │
        │ ""                 │
        └────────────────────┘
        """
      }
    }

    @Test func alias() {
      enum RT: AliasName {}
      assertQuery(
        Reminder
          .leftJoin(ReminderText.as(RT.self).all) { $0.rowid.eq($1.rowid) }
          .select { $1.tags.highlight("**", "**") }
          .order { $1.bm25() }
      ) {
        """
        SELECT highlight("reminderTexts", (SELECT "cid" FROM pragma_table_info('reminderTexts') WHERE "name" = 'tags'),
        '**', '**')
        FROM "reminders"
        LEFT JOIN "reminderTexts" AS "rTs" ON ("reminders"."rowid") = ("rTs"."rowid")
        ORDER BY bm25("reminderTexts")
        """
      } results: {
        """
        ┌────────────────────┐
        │ "someday optional" │
        │ "someday optional" │
        │ ""                 │
        │ "car kids"         │
        │ ""                 │
        │ ""                 │
        │ ""                 │
        │ ""                 │
        │ ""                 │
        │ ""                 │
        └────────────────────┘
        """
      }
    }
  }
}
