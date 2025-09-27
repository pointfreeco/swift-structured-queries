import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  struct OperatorsTests {
    @Test func equality() {
      assertInlineSnapshot(of: Row.columns.c == Row.columns.c, as: .sql) {
        """
        ("rows"."c") = ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c == Row.columns.a, as: .sql) {
        """
        ("rows"."c") = ("rows"."a")
        """
      }
      assertInlineSnapshot(of: Row.columns.c == nil as Int?, as: .sql) {
        """
        ("rows"."c") IS (NULL)
        """
      }
      assertInlineSnapshot(of: Row.columns.a == Row.columns.c, as: .sql) {
        """
        ("rows"."a") IS ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.a == Row.columns.a, as: .sql) {
        """
        ("rows"."a") IS ("rows"."a")
        """
      }
      assertInlineSnapshot(of: Row.columns.a == nil as Int?, as: .sql) {
        """
        ("rows"."a") IS (NULL)
        """
      }
      assertInlineSnapshot(of: nil as Int? == Row.columns.c, as: .sql) {
        """
        (NULL) IS ("rows"."c")
        """
      }
      assertInlineSnapshot(of: nil as Int? == Row.columns.a, as: .sql) {
        """
        (NULL) IS ("rows"."a")
        """
      }
      assertInlineSnapshot(of: Row.columns.c != Row.columns.c, as: .sql) {
        """
        ("rows"."c") <> ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c != Row.columns.a, as: .sql) {
        """
        ("rows"."c") <> ("rows"."a")
        """
      }
      assertInlineSnapshot(of: Row.columns.c != nil as Int?, as: .sql) {
        """
        ("rows"."c") IS NOT (NULL)
        """
      }
      assertInlineSnapshot(of: Row.columns.a != Row.columns.c, as: .sql) {
        """
        ("rows"."a") IS NOT ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.a != Row.columns.a, as: .sql) {
        """
        ("rows"."a") IS NOT ("rows"."a")
        """
      }
      assertInlineSnapshot(of: Row.columns.a != nil as Int?, as: .sql) {
        """
        ("rows"."a") IS NOT (NULL)
        """
      }
      assertInlineSnapshot(of: nil as Int? != Row.columns.c, as: .sql) {
        """
        (NULL) IS NOT ("rows"."c")
        """
      }
      assertInlineSnapshot(of: nil as Int? != Row.columns.a, as: .sql) {
        """
        (NULL) IS NOT ("rows"."a")
        """
      }
    }

    @available(*, deprecated)
    @Test func deprecatedEquality() {
      assertInlineSnapshot(of: Row.columns.c == nil, as: .sql) {
        """
        ("rows"."c") IS (NULL)
        """
      }
      assertInlineSnapshot(of: Row.columns.c != nil, as: .sql) {
        """
        ("rows"."c") IS NOT (NULL)
        """
      }
    }

    @Test func comparison() {
      assertInlineSnapshot(of: Row.columns.c < Row.columns.c, as: .sql) {
        """
        ("rows"."c") < ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c > Row.columns.c, as: .sql) {
        """
        ("rows"."c") > ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c <= Row.columns.c, as: .sql) {
        """
        ("rows"."c") <= ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c >= Row.columns.c, as: .sql) {
        """
        ("rows"."c") >= ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.bool < Row.columns.bool, as: .sql) {
        """
        ("rows"."bool") < ("rows"."bool")
        """
      }
    }

    @Test func logic() {
      assertInlineSnapshot(of: Row.columns.bool && Row.columns.bool, as: .sql) {
        """
        ("rows"."bool") AND ("rows"."bool")
        """
      }
      assertInlineSnapshot(of: Row.columns.bool || Row.columns.bool, as: .sql) {
        """
        ("rows"."bool") OR ("rows"."bool")
        """
      }
      assertInlineSnapshot(of: !Row.columns.bool, as: .sql) {
        """
        NOT ("rows"."bool")
        """
      }
      assertInlineSnapshot(of: Row.update { $0.bool.toggle() }, as: .sql) {
        """
        UPDATE "rows"
        SET "bool" = NOT ("rows"."bool")
        """
      }
    }

    @Test func arithmetic() {
      assertInlineSnapshot(of: Row.columns.c + Row.columns.c, as: .sql) {
        """
        ("rows"."c") + ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c - Row.columns.c, as: .sql) {
        """
        ("rows"."c") - ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c * Row.columns.c, as: .sql) {
        """
        ("rows"."c") * ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c / Row.columns.c, as: .sql) {
        """
        ("rows"."c") / ("rows"."c")
        """
      }
      assertInlineSnapshot(of: -Row.columns.c, as: .sql) {
        """
        -("rows"."c")
        """
      }
      assertInlineSnapshot(of: +Row.columns.c, as: .sql) {
        """
        +("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c += 1 }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ("rows"."c") + (1)
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c -= 2 }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ("rows"."c") - (2)
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c *= 3 }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ("rows"."c") * (3)
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c /= 4 }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ("rows"."c") / (4)
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c = -$0.c }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = -("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c = +$0.c }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = +("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c.negate() }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = -("rows"."c")
        """
      }
    }

    @Test func bitwise() {
      assertInlineSnapshot(of: Row.columns.c % Row.columns.c, as: .sql) {
        """
        ("rows"."c") % ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c & Row.columns.c, as: .sql) {
        """
        ("rows"."c") & ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c | Row.columns.c, as: .sql) {
        """
        ("rows"."c") | ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c << Row.columns.c, as: .sql) {
        """
        ("rows"."c") << ("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.columns.c >> Row.columns.c, as: .sql) {
        """
        ("rows"."c") >> ("rows"."c")
        """
      }
      assertInlineSnapshot(of: ~Row.columns.c, as: .sql) {
        """
        ~("rows"."c")
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c &= 2 }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ("rows"."c") & (2)
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c |= 3 }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ("rows"."c") | (3)
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c <<= 4 }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ("rows"."c") << (4)
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c >>= 5 }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ("rows"."c") >> (5)
        """
      }
      assertInlineSnapshot(of: Row.update { $0.c = ~$0.c }, as: .sql) {
        """
        UPDATE "rows"
        SET "c" = ~("rows"."c")
        """
      }
    }

    @Test func coalesce() {
      assertInlineSnapshot(of: Row.columns.a ?? Row.columns.b ?? Row.columns.c, as: .sql) {
        """
        coalesce("rows"."a", "rows"."b", "rows"."c")
        """
      }
    }

    @Test func strings() {
      assertInlineSnapshot(of: Row.columns.string + Row.columns.string, as: .sql) {
        """
        ("rows"."string") || ("rows"."string")
        """
      }
      assertInlineSnapshot(of: Row.columns.string.collate(.nocase), as: .sql) {
        """
        "rows"."string" COLLATE "NOCASE"
        """
      }
      assertInlineSnapshot(of: Row.columns.string.glob("a*"), as: .sql) {
        """
        ("rows"."string") GLOB ('a*')
        """
      }
      assertInlineSnapshot(of: Row.columns.string.like("a%"), as: .sql) {
        """
        ("rows"."string" LIKE 'a%')
        """
      }
      assertInlineSnapshot(of: Row.columns.string.like("a%", escape: #"\"#), as: .sql) {
        #"""
        ("rows"."string" LIKE 'a%' ESCAPE '\')
        """#
      }
      assertInlineSnapshot(of: Row.columns.string.hasPrefix("a"), as: .sql) {
        """
        ("rows"."string" LIKE 'a%')
        """
      }
      assertInlineSnapshot(of: Row.columns.string.hasSuffix("a"), as: .sql) {
        """
        ("rows"."string" LIKE '%a')
        """
      }
      assertInlineSnapshot(of: Row.columns.string.contains("a"), as: .sql) {
        """
        ("rows"."string" LIKE '%a%')
        """
      }
      assertInlineSnapshot(of: Row.columns.string.contains("a"[...]), as: .sql) {
        """
        ("rows"."string" LIKE '%a%')
        """
      }
      assertInlineSnapshot(of: Row.update { $0.string += "!" }, as: .sql) {
        """
        UPDATE "rows"
        SET "string" = ("rows"."string") || ('!')
        """
      }
      assertInlineSnapshot(of: Row.update { $0.string.append("!") }, as: .sql) {
        """
        UPDATE "rows"
        SET "string" = ("rows"."string") || ('!')
        """
      }
      assertInlineSnapshot(of: Row.update { $0.string.append(contentsOf: "!") }, as: .sql) {
        """
        UPDATE "rows"
        SET "string" = ("rows"."string") || ('!')
        """
      }
    }

    @Test func collectionIn() async throws {
      assertInlineSnapshot(
        of: Row.columns.c.in([1, 2, 3]),
        as: .sql
      ) {
        """
        ("rows"."c") IN ((1), (2), (3))
        """
      }
      assertInlineSnapshot(
        of: Row.columns.c.in(Row.select(\.c)),
        as: .sql
      ) {
        """
        ("rows"."c") IN ((SELECT "rows"."c"
        FROM "rows"))
        """
      }
      assertInlineSnapshot(
        of: [1, 2, 3].contains(Row.columns.c),
        as: .sql
      ) {
        """
        ("rows"."c") IN ((1), (2), (3))
        """
      }
      assertInlineSnapshot(
        of: Row.select(\.c).contains(Row.columns.c),
        as: .sql
      ) {
        """
        ("rows"."c") IN ((SELECT "rows"."c"
        FROM "rows"))
        """
      }
    }

    @Test func rangeContains() async throws {
      assertInlineSnapshot(
        of: (0...10).contains(Row.columns.c),
        as: .sql
      ) {
        """
        "rows"."c" BETWEEN 0 AND 10
        """
      }
      assertInlineSnapshot(
        of: Row.columns.c.between(0, and: 10),
        as: .sql
      ) {
        """
        "rows"."c" BETWEEN 0 AND 10
        """
      }
      assertQuery(
        Reminder.where {
          $0.id.between(
            Reminder.select { $0.id.min() } ?? 0,
            and: (Reminder.select { $0.id.max() } ?? 0) / 3
          )
        }
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        WHERE "reminders"."id" BETWEEN coalesce((
          SELECT min("reminders"."id")
          FROM "reminders"
        ), 0) AND (coalesce((
          SELECT max("reminders"."id")
          FROM "reminders"
        ), 0)) / (3)
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Reminder(                                   │
        │   id: 1,                                    │
        │   assignedUserID: 1,                        │
        │   dueDate: Date(2001-01-01T00:00:00.000Z),  │
        │   isCompleted: false,                       │
        │   isFlagged: false,                         │
        │   notes: "Milk, Eggs, Apples",              │
        │   priority: nil,                            │
        │   remindersListID: 1,                       │
        │   title: "Groceries",                       │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        ├─────────────────────────────────────────────┤
        │ Reminder(                                   │
        │   id: 2,                                    │
        │   assignedUserID: nil,                      │
        │   dueDate: Date(2000-12-30T00:00:00.000Z),  │
        │   isCompleted: false,                       │
        │   isFlagged: true,                          │
        │   notes: "",                                │
        │   priority: nil,                            │
        │   remindersListID: 1,                       │
        │   title: "Haircut",                         │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        ├─────────────────────────────────────────────┤
        │ Reminder(                                   │
        │   id: 3,                                    │
        │   assignedUserID: nil,                      │
        │   dueDate: Date(2001-01-01T00:00:00.000Z),  │
        │   isCompleted: false,                       │
        │   isFlagged: false,                         │
        │   notes: "Ask about diet",                  │
        │   priority: .high,                          │
        │   remindersListID: 1,                       │
        │   title: "Doctor appointment",              │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @Test func selectSubquery() {
      assertInlineSnapshot(
        of: Row.select { ($0.a, Row.count()) },
        as: .sql
      ) {
        """
        SELECT "rows"."a", (
          SELECT count(*)
          FROM "rows"
        )
        FROM "rows"
        """
      }
    }

    @Test func whereSubquery() async throws {
      assertInlineSnapshot(
        of: Row.where {
          $0.c.in(Row.select { $0.bool.cast(as: Int.self) })
        },
        as: .sql
      ) {
        """
        SELECT "rows"."a", "rows"."b", "rows"."c", "rows"."bool", "rows"."string"
        FROM "rows"
        WHERE ("rows"."c") IN ((SELECT CAST("rows"."bool" AS INTEGER)
        FROM "rows"))
        """
      }
      assertInlineSnapshot(
        of: Row.where {
          $0.c.cast() >= Row.select { $0.c.avg() ?? 0 } && $0.c.cast() > 1.0
        },
        as: .sql
      ) {
        """
        SELECT "rows"."a", "rows"."b", "rows"."c", "rows"."bool", "rows"."string"
        FROM "rows"
        WHERE ((CAST("rows"."c" AS REAL)) >= ((
          SELECT coalesce(avg("rows"."c"), 0.0)
          FROM "rows"
        ))) AND ((CAST("rows"."c" AS REAL)) > (1.0))
        """
      }
    }

    @Test func containsCollectionElement() {
      assertQuery(
        Reminder.select { $0.id }.where { [1, 2].contains($0.id) }
      ) {
        """
        SELECT "reminders"."id"
        FROM "reminders"
        WHERE ("reminders"."id") IN ((1), (2))
        """
      } results: {
        """
        ┌───┐
        │ 1 │
        │ 2 │
        └───┘
        """
      }
    }

    @Test func moduloZero() {
      assertQuery(Reminder.select { $0.id % 0 }) {
        """
        SELECT ("reminders"."id") % (0)
        FROM "reminders"
        """
      } results: {
        """
        ┌─────┐
        │ nil │
        │ nil │
        │ nil │
        │ nil │
        │ nil │
        │ nil │
        │ nil │
        │ nil │
        │ nil │
        │ nil │
        └─────┘
        """
      }
    }

    @Test func exists() {
      assertQuery(Values(Reminder.exists())) {
        """
        SELECT EXISTS (
          SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
          FROM "reminders"
        )
        """
      } results: {
        """
        ┌──────┐
        │ true │
        └──────┘
        """
      }
      assertQuery(Values(Reminder.where { $0.id == 1 }.exists())) {
        """
        SELECT EXISTS (
          SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
          FROM "reminders"
          WHERE ("reminders"."id") = (1)
        )
        """
      } results: {
        """
        ┌──────┐
        │ true │
        └──────┘
        """
      }
      assertQuery(Values(Reminder.where { $0.id == 100 }.exists())) {
        """
        SELECT EXISTS (
          SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
          FROM "reminders"
          WHERE ("reminders"."id") = (100)
        )
        """
      } results: {
        """
        ┌───────┐
        │ false │
        └───────┘
        """
      }
    }

    @Table
    struct Row {
      var a: Int?
      var b: Int?
      var c: Int
      var bool: Bool
      var string: String
    }
  }
}
