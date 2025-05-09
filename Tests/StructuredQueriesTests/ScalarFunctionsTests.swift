import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  struct ScalarFunctionTests {
    @Table
    struct User {
      var id: Int
      var name: String
      var isAdmin: Bool
      var salary: Double
      var referrerID: Int?
      var updatedAt: Date
      var image: [UInt8]
    }

    @Test func likelihood() {
      assertInlineSnapshot(of: User.columns.isAdmin.likely(), as: .sql) {
        """
        likely("users"."isAdmin")
        """
      }
      assertInlineSnapshot(of: User.columns.isAdmin.unlikely(), as: .sql) {
        """
        unlikely("users"."isAdmin")
        """
      }
      assertInlineSnapshot(of: User.columns.isAdmin.likelihood(0.5), as: .sql) {
        """
        likelihood("users"."isAdmin", 0.5)
        """
      }
    }

    @Test func blob() {
      assertInlineSnapshot(of: 10.randomblob(), as: .sql) {
        """
        randomblob(10)
        """
      }
      assertInlineSnapshot(of: 10.zeroblob(), as: .sql) {
        """
        zeroblob(10)
        """
      }
    }

    @Test func arithmetic() {
      assertInlineSnapshot(of: User.columns.id.abs(), as: .sql) {
        """
        abs("users"."id")
        """
      }
      assertInlineSnapshot(of: User.columns.salary.abs(), as: .sql) {
        """
        abs("users"."salary")
        """
      }
      assertInlineSnapshot(of: User.columns.id.sign(), as: .sql) {
        """
        sign("users"."id")
        """
      }
      assertInlineSnapshot(of: User.columns.salary.sign(), as: .sql) {
        """
        sign("users"."salary")
        """
      }
      assertInlineSnapshot(of: User.columns.salary.round(), as: .sql) {
        """
        round("users"."salary")
        """
      }
      assertInlineSnapshot(of: User.columns.salary.round(2), as: .sql) {
        """
        round("users"."salary", 2)
        """
      }
    }

    @Test func strings() {
      assertInlineSnapshot(of: "Jr".instr(User.columns.name), as: .sql) {
        """
        instr('Jr', "users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.length(), as: .sql) {
        """
        length("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.lower(), as: .sql) {
        """
        lower("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.ltrim(), as: .sql) {
        """
        ltrim("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.ltrim(" "), as: .sql) {
        """
        ltrim("users"."name", ' ')
        """
      }
      assertInlineSnapshot(of: User.columns.name.octetLength(), as: .sql) {
        """
        octet_length("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.quote(), as: .sql) {
        """
        quote("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.quote(), as: .sql) {
        """
        quote("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.replace("a", "b"), as: .sql) {
        """
        replace("users"."name", 'a', 'b')
        """
      }
      assertInlineSnapshot(of: User.columns.name.rtrim(), as: .sql) {
        """
        rtrim("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.rtrim(" "), as: .sql) {
        """
        rtrim("users"."name", ' ')
        """
      }
      assertInlineSnapshot(of: User.columns.name.substr(10), as: .sql) {
        """
        substr("users"."name", 10)
        """
      }
      assertInlineSnapshot(of: User.columns.name.substr(10, 10), as: .sql) {
        """
        substr("users"."name", 10, 10)
        """
      }
      assertInlineSnapshot(of: User.columns.name.trim(), as: .sql) {
        """
        trim("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.trim(" "), as: .sql) {
        """
        trim("users"."name", ' ')
        """
      }
      assertInlineSnapshot(of: User.columns.name.unhex(), as: .sql) {
        """
        unhex("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.unhex("<->"), as: .sql) {
        """
        unhex("users"."name", '<->')
        """
      }
      assertInlineSnapshot(of: User.columns.name.unicode(), as: .sql) {
        """
        unicode("users"."name")
        """
      }
      assertInlineSnapshot(of: User.columns.name.upper(), as: .sql) {
        """
        upper("users"."name")
        """
      }
    }

    @Test func bytes() {
      assertInlineSnapshot(of: User.columns.image.hex(), as: .sql) {
        """
        hex("users"."image")
        """
      }
    }

    @available(*, deprecated)
    @Test func deprecatedCount() {
      assertInlineSnapshot(of: User.columns.name.count, as: .sql) {
        """
        length("users"."name")
        """
      }
    }

    @available(*, deprecated)
    @Test func deprecatedCoalesce() {
      assertInlineSnapshot(of: User.columns.name ?? User.columns.name, as: .sql) {
        """
        coalesce("users"."name", "users"."name")
        """
      }
    }

    @Test func ifnull() {
      assertQuery(Reminder.select { ($0.priority, $0.priority.ifnull(Priority.low)) }) {
        """
        SELECT "reminders"."priority", ifnull("reminders"."priority", 1)
        FROM "reminders"
        """
      } results: {
        """
        ┌─────────┬─────────────────┐
        │ nil     │ Priority.low    │
        │ nil     │ Priority.low    │
        │ .high   │ Priority.high   │
        │ nil     │ Priority.low    │
        │ nil     │ Priority.low    │
        │ .high   │ Priority.high   │
        │ .low    │ Priority.low    │
        │ .high   │ Priority.high   │
        │ nil     │ Priority.low    │
        │ .medium │ Priority.medium │
        └─────────┴─────────────────┘
        """
      }
    }
  }
}
