import Dependencies
import Foundation
import InlineSnapshotTesting
import SQLite3
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct DatabaseCollationTests {
    @Dependency(\.defaultDatabase) var database

    @DatabaseCollation
    func reversed(_ lhs: String, _ rhs: String) -> CollationOrder {
      CollationOrder(rhs, lhs)
    }
    @Test func order() {
      $reversed.install(database.handle)
      assertQuery(
        RemindersList.select(\.title).order { $0.title.collate($reversed) }
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
      $caseInsensitive.install(database.handle)
      // NB: '.caseInsensitive' is a 'NamedCollation' alias of '$caseInsensitive', defined below.
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

    final class Engine {
      @DatabaseCollation("engine_reversed")
      func reversed(_ lhs: String, _ rhs: String) -> CollationOrder {
        CollationOrder(rhs, lhs)
      }
    }
    @Test func deallocatedOwner() {
      func makeCollation() -> some DatabaseCollation {
        Engine().$reversed
      }
      let collation = makeCollation()
      collation.install(database.handle)
      // NB: A collating sequence cannot surface an error to SQLite, so the deallocated engine is
      //     reported as an issue and the comparison falls back to a byte-wise one.
      withKnownIssue {
        assertQuery(
          RemindersList.select(\.title).order { $0.title.collate(collation) }
        ) {
          """
          SELECT "remindersLists"."title"
          FROM "remindersLists"
          ORDER BY "remindersLists"."title" COLLATE "engine_reversed"
          """
        } results: {
          """
          ┌────────────┐
          │ "Business" │
          │ "Family"   │
          │ "Personal" │
          └────────────┘
          """
        }
      }
    }

    @DatabaseCollation
    func byLength(_ lhs: String, _ rhs: String) -> CollationOrder {
      let byLength = CollationOrder(lhs.count, rhs.count)
      return byLength == .same ? CollationOrder(lhs, rhs) : byLength
    }
    @Test func comparisonInteger() {
      $byLength.install(database.handle)
      assertQuery(
        RemindersList.select(\.title).order { $0.title.collate($byLength) }
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
      $reversed.install(database.handle)
      assertQuery(
        RemindersList
          .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
          .order { $1.title.collate($reversed) }
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

@DatabaseCollation
func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
  CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
}

extension Collation where Self == NamedCollation {
  fileprivate static var caseInsensitive: Self { NamedCollation($caseInsensitive) }
}
