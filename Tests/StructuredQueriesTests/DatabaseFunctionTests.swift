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
  @Suite struct DatabaseFunctionTests {
    @DatabaseFunction
    func isEnabled() -> Bool {
      true
    }
    @Test func customIsEnabled() {
      @Dependency(\.defaultDatabase) var database
      $isEnabled.install(database.handle)
      assertQuery(
        Values($isEnabled())
      ) {
        """
        SELECT "isEnabled"()
        """
      } results: {
        """
        ┌──────┐
        │ true │
        └──────┘
        """
      }
    }

    @DatabaseFunction
    func dateTime(_ format: String? = nil) -> Date? {
      Date(timeIntervalSince1970: 0)
    }
    @Test func customDateTime() {
      @Dependency(\.defaultDatabase) var database
      $dateTime.install(database.handle)
      assertQuery(
        Values($dateTime())
      ) {
        """
        SELECT "dateTime"(NULL)
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(1970-01-01T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
    }

    @DatabaseFunction
    func concat(first: String = "", second: String = "") -> String {
      first + second
    }
    @Test func customConcat() {
      @Dependency(\.defaultDatabase) var database
      $concat.install(database.handle)
      assertQuery(
        Values($concat(first: "foo", second: "bar"))
      ) {
        """
        SELECT "concat"('foo', 'bar')
        """
      } results: {
        """
        ┌──────────┐
        │ "foobar" │
        └──────────┘
        """
      }
    }

    @Test func erasedConcat() {
      @Dependency(\.defaultDatabase) var database
      $concat.install(database.handle)
      assertQuery(
        Values($concat("foo", "bar"))
      ) {
        """
        SELECT "concat"('foo', 'bar')
        """
      } results: {
        """
        ┌──────────┐
        │ "foobar" │
        └──────────┘
        """
      }
    }

    @DatabaseFunction
    func throwing() throws -> String {
      struct Failure: LocalizedError {
        var errorDescription: String? {
          "Oops!"
        }
      }
      throw Failure()
    }
    @Test func customThrowing() {
      @Dependency(\.defaultDatabase) var database
      $throwing.install(database.handle)
      assertQuery(
        Values($throwing())
      ) {
        """
        SELECT "throwing"()
        """
      } results: {
        """
        Oops!
        """
      }
    }

    @DatabaseFunction(isDeterministic: true)
    func `default`() -> Int {
      42
    }

    enum Completion: Int, QueryBindable {
      case incomplete, complete, completing
    }
    @DatabaseFunction
    func toggle(_ completion: Completion) -> Completion {
      completion == .incomplete ? .completing : .incomplete
    }
    @Test func customToggle() {
      @Dependency(\.defaultDatabase) var database
      $toggle.install(database.handle)
      assertQuery(
        Values($toggle(Completion.incomplete))
      ) {
        """
        SELECT "toggle"(0)
        """
      } results: {
        """
        ┌───────────────────────────────────────────────────────────┐
        │ SnapshotTests.DatabaseFunctionTests.Completion.completing │
        └───────────────────────────────────────────────────────────┘
        """
      }
    }
  }
}
