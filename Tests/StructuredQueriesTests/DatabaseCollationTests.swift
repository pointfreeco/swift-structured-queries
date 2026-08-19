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

    @Test func order() {
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

    @Test func equality() {
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

    @Test func sqlMacro() {
      database.install(.caseInsensitive)
      assertQuery(
        #sql(
          """
          SELECT "title" FROM \(RemindersList.self)
          WHERE ("title" COLLATE \(.caseInsensitive)) = \(bind: "PERSONAL")
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

    @Test func comparisonInteger() {
      database.install(.byLength)
      assertQuery(
        RemindersList.select(\.title).order { $0.title.collate(.byLength) }
      ) {
        """
        SELECT "remindersLists"."title"
        FROM "remindersLists"
        ORDER BY "remindersLists"."title" COLLATE "byLength"
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

    @Test func optionalText() {
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

  fileprivate static func byLength(_ lhs: String, _ rhs: String) -> CollationOrder {
    let byLength = CollationOrder(lhs.count, rhs.count)
    return byLength == .same ? CollationOrder(lhs, rhs) : byLength
  }

  fileprivate static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
    CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
  }
}
