import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct AggregateFunctionsTests {
    @Table
    fileprivate struct User {
      var id: Int
      var name: String
      var isAdmin: Bool
      var age: Int?
      var birthDate: Date?
    }

    @Test func average() {
      assertInlineSnapshot(of: User.columns.id.avg(), as: .sql) {
        """
        avg("users"."id")
        """
      }
      assertInlineSnapshot(of: User.columns.age.avg(), as: .sql) {
        """
        avg("users"."age")
        """
      }
      assertQuery(Reminder.select { $0.id.avg() }) {
        """
        SELECT avg("reminders"."id")
        FROM "reminders"
        """
      } results: {
        """
        ┌─────┐
        │ 5.5 │
        └─────┘
        """
      }
    }

    @Test func count() {
      assertInlineSnapshot(of: User.columns.id.count(), as: .sql) {
        """
        count("users"."id")
        """
      }
      assertInlineSnapshot(of: User.columns.id.count(distinct: true), as: .sql) {
        """
        count(DISTINCT "users"."id")
        """
      }
      assertQuery(Reminder.select { $0.id.count() }) {
        """
        SELECT count("reminders"."id")
        FROM "reminders"
        """
      } results: {
        """
        ┌────┐
        │ 10 │
        └────┘
        """
      }
      assertQuery(Reminder.select { $0.priority.count(distinct: true) }) {
        """
        SELECT count(DISTINCT "reminders"."priority")
        FROM "reminders"
        """
      } results: {
        """
        ┌───┐
        │ 3 │
        └───┘
        """
      }
    }

    @Test func unqualifiedCount() {
      assertInlineSnapshot(of: User.all.select { _ in .count() }, as: .sql) {
        """
        SELECT count(*)
        FROM "users"
        """
      }
      assertInlineSnapshot(of: User.where(\.isAdmin).count(), as: .sql) {
        """
        SELECT count(*)
        FROM "users"
        WHERE "users"."isAdmin"
        """
      }
    }

    @Test func max() {
      assertInlineSnapshot(of: User.columns.birthDate.max(), as: .sql) {
        """
        max("users"."birthDate")
        """
      }
      assertQuery(Reminder.select { $0.dueDate.max() }) {
        """
        SELECT max("reminders"."dueDate")
        FROM "reminders"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2001-01-05T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
    }

    @Test func min() {
      assertInlineSnapshot(of: User.columns.birthDate.min(), as: .sql) {
        """
        min("users"."birthDate")
        """
      }
      assertQuery(Reminder.select { $0.dueDate.min() }) {
        """
        SELECT min("reminders"."dueDate")
        FROM "reminders"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2000-06-25T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
    }

    @Test func sum() {
      assertInlineSnapshot(of: User.columns.id.sum(), as: .sql) {
        """
        sum("users"."id")
        """
      }
      assertInlineSnapshot(of: User.columns.id.sum(distinct: true), as: .sql) {
        """
        sum(DISTINCT "users"."id")
        """
      }
      assertQuery(Reminder.select { #sql("sum(\($0.id))", as: Int?.self) }) {
        """
        SELECT sum("reminders"."id")
        FROM "reminders"
        """
      } results: {
        """
        ┌────┐
        │ 55 │
        └────┘
        """
      }
      assertQuery(Reminder.select { $0.id.sum() }.where { _ in false }) {
        """
        SELECT sum("reminders"."id")
        FROM "reminders"
        WHERE 0
        """
      } results: {
        """
        ┌─────┐
        │ nil │
        └─────┘
        """
      }
    }

    @Test func total() {
      assertInlineSnapshot(of: User.columns.id.total(), as: .sql) {
        """
        total("users"."id")
        """
      }
      assertInlineSnapshot(of: User.columns.id.total(distinct: true), as: .sql) {
        """
        total(DISTINCT "users"."id")
        """
      }
      assertQuery(Reminder.select { $0.id.total() }) {
        """
        SELECT total("reminders"."id")
        FROM "reminders"
        """
      } results: {
        """
        ┌────┐
        │ 55 │
        └────┘
        """
      }
    }

    @Test func groupConcat() {
      assertInlineSnapshot(
        of: User.select { $0.name.groupConcat() },
        as: .sql
      ) {
        """
        SELECT group_concat("users"."name")
        FROM "users"
        """
      }

      assertInlineSnapshot(
        of: User.select { $0.name.groupConcat("-") },
        as: .sql
      ) {
        """
        SELECT group_concat("users"."name", '-')
        FROM "users"
        """
      }

      assertInlineSnapshot(
        of: User.select { $0.name.groupConcat($0.id) },
        as: .sql
      ) {
        """
        SELECT group_concat("users"."name", "users"."id")
        FROM "users"
        """
      }

      assertInlineSnapshot(
        of: User.select { $0.name.groupConcat(order: $0.isAdmin.desc()) },
        as: .sql
      ) {
        """
        SELECT group_concat("users"."name" ORDER BY "users"."isAdmin" DESC)
        FROM "users"
        """
      }

      assertInlineSnapshot(
        of: User.select { $0.name.groupConcat(filter: $0.isAdmin) },
        as: .sql
      ) {
        """
        SELECT group_concat("users"."name") FILTER (WHERE "users"."isAdmin")
        FROM "users"
        """
      }

      assertQuery(Tag.select { $0.title.groupConcat() }.order(by: \.title)) {
        """
        SELECT group_concat("tags"."title")
        FROM "tags"
        ORDER BY "tags"."title"
        """
      } results: {
        """
        ┌─────────────────────────────┐
        │ "car,kids,someday,optional" │
        └─────────────────────────────┘
        """
      }
      assertQuery(
        Tag
          .select {
            #sql("iif(\($0.title.length() > 5), \($0.title), NULL)", as: String?.self).groupConcat()
          }
          .order(by: \.title)
      ) {
        """
        SELECT group_concat(iif((length("tags"."title")) > (5), "tags"."title", NULL))
        FROM "tags"
        ORDER BY "tags"."title"
        """
      } results: {
        """
        ┌────────────────────┐
        │ "someday,optional" │
        └────────────────────┘
        """
      }
      assertQuery(
        Tag
          .select {
            Case()
              .when($0.title.length() > 5, then: $0.title)
              .groupConcat()
          }
          .order(by: \.title)
      ) {
        """
        SELECT group_concat(CASE WHEN (length("tags"."title")) > (5) THEN "tags"."title" END)
        FROM "tags"
        ORDER BY "tags"."title"
        """
      } results: {
        """
        ┌────────────────────┐
        │ "someday,optional" │
        └────────────────────┘
        """
      }

      assertQuery(
        Tag
          .select {
            Case($0.title.length())
              .when(7, then: $0.title)
              .groupConcat()
          }
          .order(by: \.title)
      ) {
        """
        SELECT group_concat(CASE length("tags"."title") WHEN 7 THEN "tags"."title" END)
        FROM "tags"
        ORDER BY "tags"."title"
        """
      } results: {
        """
        ┌───────────┐
        │ "someday" │
        └───────────┘
        """
      }
    }

    @Test func aggregateOfExpression() {
      assertInlineSnapshot(of: User.columns.name.length().count(distinct: true), as: .sql) {
        """
        count(DISTINCT length("users"."name"))
        """
      }

      assertInlineSnapshot(of: (User.columns.name + "!").groupConcat(", "), as: .sql) {
        """
        group_concat(("users"."name") || ('!'), ', ')
        """
      }

      assertQuery(Reminder.select { $0.title.length().count(distinct: true) }) {
        """
        SELECT count(DISTINCT length("reminders"."title"))
        FROM "reminders"
        """
      } results: {
        """
        ┌───┐
        │ 8 │
        └───┘
        """
      }
      assertQuery(Tag.select { ($0.title + "!").groupConcat(", ") }) {
        """
        SELECT group_concat(("tags"."title") || ('!'), ', ')
        FROM "tags"
        """
      } results: {
        """
        ┌────────────────────────────────────┐
        │ "car!, kids!, someday!, optional!" │
        └────────────────────────────────────┘
        """
      }
    }
  }
}
