import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

#if canImport(Darwin)
  import SQLite3
#else
  import _StructuredQueriesSQLite3
#endif

extension SnapshotTests {
  @Suite struct DatabaseCollationTests {
    @Dependency(\.defaultDatabase) var database

    @Test func `order collate reversed`() {
      database.install(.reversed)
      assertQuery(
        RemindersList.select(\.title).order { $0.title.collate(.reversed) }
      ) {
        """
        SELECT "remindersLists"."title"
        FROM "remindersLists"
        ORDER BY "remindersLists"."title" COLLATE "reversed"
        """
      } results: {
        """
        ┌────────────┐
        │ "Personal" │
        │ "Family"   │
        │ "Business" │
        └────────────┘
        """
      }
    }

    @Test func `case insensitive collation equality check`() {
      database.install(.caseInsensitive)
      assertQuery(
        RemindersList
          .where { $0.title.collate(.caseInsensitive).eq("PERSONAL") }
          .select(\.title)
      ) {
        """
        SELECT "remindersLists"."title"
        FROM "remindersLists"
        WHERE (("remindersLists"."title" COLLATE "caseInsensitive") = ('PERSONAL'))
        """
      } results: {
        """
        ┌────────────┐
        │ "Personal" │
        └────────────┘
        """
      }
    }

    @Test func `interpolation with #sql macro`() {
      database.install(.caseInsensitive)
      assertQuery(
        #sql(
          """
          SELECT "title" FROM \(RemindersList.self)
          WHERE ("title" COLLATE \(.caseInsensitive)) = 'PERSONAL'
          """,
          as: String.self
        )
      ) {
        """
        SELECT "title" FROM "remindersLists"
        WHERE ("title" COLLATE "caseInsensitive") = 'PERSONAL'
        """
      } results: {
        """
        ┌────────────┐
        │ "Personal" │
        └────────────┘
        """
      }
    }

    @Test func `order collate by string length`() {
      database.install(.byLength)
      assertQuery(
        RemindersList.select(\.title).order { $0.title.collate(.byLength) }
      ) {
        """
        SELECT "remindersLists"."title"
        FROM "remindersLists"
        ORDER BY "remindersLists"."title" COLLATE "by_length"
        """
      } results: {
        """
        ┌────────────┐
        │ "Family"   │
        │ "Business" │
        │ "Personal" │
        └────────────┘
        """
      }
    }

    @Test func `collate NULL text`() {
      database.install(.fail)
      assertQuery(
        #sql(
          """
          SELECT "column1" FROM (VALUES ('Business'), (NULL), ('Personal'))
          ORDER BY "column1" COLLATE \(.fail) NULLS LAST
          """,
          as: String?.self
        )
      ) {
        """
        SELECT "column1" FROM (VALUES ('Business'), (NULL), ('Personal'))
        ORDER BY "column1" COLLATE "fail" NULLS LAST
        """
      } results: {
        """
        ┌────────────┐
        │ "Business" │
        │ "Personal" │
        │ nil        │
        └────────────┘
        """
      }
    }

    @Test func `collate optional text`() {
      database.install(.reversed)
      assertQuery(
        RemindersList
          .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
          .order { $1.title.collate(.reversed) }
          .select { $1.title }
          .limit(3)
      ) {
        """
        SELECT "reminders"."title"
        FROM "remindersLists"
        LEFT JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
        ORDER BY "reminders"."title" COLLATE "reversed"
        LIMIT 3
        """
      } results: {
        """
        ┌──────────────────────┐
        │ "Take out trash"     │
        │ "Take a walk"        │
        │ "Send weekly emails" │
        └──────────────────────┘
        """
      }
    }
  }
}

@DatabaseCollations
extension Collation where Self == CustomCollation {
  fileprivate static func reversed(_ lhs: String, _ rhs: String) -> CollationOrder {
    CollationOrder(rhs, lhs)
  }

  @DatabaseCollation("by_length")
  fileprivate static func byLength(_ lhs: String, _ rhs: String) -> CollationOrder {
    CollationOrder(lhs.count, rhs.count)
      .combine(with: CollationOrder(lhs, rhs))
  }

  fileprivate static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
    CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
  }

  fileprivate static func fail(_: String, _: String) -> CollationOrder {
    Issue.record("This should  never be called")
    return .same
  }
}
