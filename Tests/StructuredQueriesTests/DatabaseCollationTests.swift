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
      var engines = [Engine()]
      let reversed = engines[0].$reversed
      reversed.install(database.handle)
      engines.removeAll()
      // NB: A collating sequence cannot surface an error to SQLite, so the deallocated engine is
      //     reported as an issue and the comparison falls back to a byte-wise one.
      withKnownIssue {
        assertQuery(
          RemindersList.select(\.title).order { $0.title.collate(reversed) }
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
      } matching: {
        $0.description.hasSuffix("Failed to invoke 'reversed'; 'Engine' was deallocated")
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

    @DatabaseCollation
    func byByteCount(
      _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
    ) -> CollationOrder {
      let byCount = CollationOrder(lhs.count, rhs.count)
      guard byCount == .same else { return byCount }
      return lhs.elementsEqual(rhs)
        ? .same
        : lhs.lexicographicallyPrecedes(rhs) ? .ascending : .descending
    }
    @Test func rawBuffers() {
      $byByteCount.install(database.handle)
      assertQuery(
        RemindersList.select(\.title).order { $0.title.collate($byByteCount) }
      ) {
        """
        SELECT "remindersLists"."title"
        FROM "remindersLists"
        ORDER BY "remindersLists"."title" COLLATE "byByteCount"
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

    #if compiler(>=6.2)
      @DatabaseCollation
      @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *)
      func canonicallyDescending(_ lhs: UTF8Span, _ rhs: UTF8Span) -> CollationOrder {
        if rhs.isCanonicallyLessThan(lhs) { return .ascending }
        if lhs.isCanonicallyLessThan(rhs) { return .descending }
        return .same
      }
      @DatabaseCollation
      @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *)
      func bytesDescending(_ lhs: Span<UInt8>, _ rhs: Span<UInt8>) -> CollationOrder {
        let count = min(lhs.count, rhs.count)
        var index = 0
        while index < count {
          if lhs[index] != rhs[index] { return CollationOrder(rhs[index], lhs[index]) }
          index += 1
        }
        return CollationOrder(rhs.count, lhs.count)
      }
      @Test
      @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *)
      func byteSpan() {
        $bytesDescending.install(database.handle)
        assertQuery(
          RemindersList.select(\.title).order { $0.title.collate($bytesDescending) }
        ) {
          """
          SELECT "remindersLists"."title"
          FROM "remindersLists"
          ORDER BY "remindersLists"."title" COLLATE "bytesDescending"
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

      @Test
      @available(macOS 26, iOS 26, tvOS 26, watchOS 26, *)
      func utf8Span() {
        $canonicallyDescending.install(database.handle)
        assertQuery(
          RemindersList.select(\.title).order { $0.title.collate($canonicallyDescending) }
        ) {
          """
          SELECT "remindersLists"."title"
          FROM "remindersLists"
          ORDER BY "remindersLists"."title" COLLATE "canonicallyDescending"
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
    #endif

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
