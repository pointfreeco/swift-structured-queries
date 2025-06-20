import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  struct QueryFragmentTests {
    @Test func string() {
      assertInlineSnapshot(
        of: SQLQueryExpression("'What''s the point?'", as: String.self),
        as: .sql
      ) {
        """
        'What''s the point?'
        """
      }
    }
    @Test func identifier() {
      assertInlineSnapshot(
        of: SQLQueryExpression(#""What's the point?""#, as: String.self),
        as: .sql
      ) {
        """
        "What's the point?"
        """
      }
    }
    @Test func brackets() {
      assertInlineSnapshot(
        of: SQLQueryExpression("[What's the point?]", as: String.self),
        as: .sql
      ) {
        """
        [What's the point?]
        """
      }
    }
    @Test func backticks() {
      assertInlineSnapshot(
        of: SQLQueryExpression("`What's the point?`", as: String.self),
        as: .sql
      ) {
        """
        `What's the point?`
        """
      }
    }
    @Test func prepare() {
      let query = #sql(
        """
        SELECT \(Reminder.id) FROM \(Reminder.self)
        WHERE \(Reminder.id) > \(1) AND \(Reminder.title) COLLATE NOCASE LIKE \(bind: "%get%")
        """
      )
      .query

      #expect(
        query.prepare { "$\($0)" } == (
          """
          SELECT "reminders"."id" FROM "reminders"
          WHERE "reminders"."id" > $1 AND "reminders"."title" COLLATE NOCASE LIKE $2
          """,
          [
            .int(1),
            .text("%get%"),
          ]
        )
      )
    }
  }
}
