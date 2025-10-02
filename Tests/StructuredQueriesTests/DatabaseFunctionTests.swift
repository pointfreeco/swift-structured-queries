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
    @Dependency(\.defaultDatabase) var database

    @DatabaseFunction
    func isEnabled() -> Bool {
      true
    }
    @Test func customIsEnabled() {
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

    @DatabaseFunction(as: (([String].JSONRepresentation) -> [String].JSONRepresentation).self)
    func jsonCapitalize(_ strings: [String]) -> [String] {
      strings.map(\.capitalized)
    }

    @Test func customRepresentation() {
      $jsonCapitalize.install(database.handle)
      assertQuery(
        Values($jsonCapitalize(#bind(["hello", "world"])))
      ) {
        """
        SELECT "jsonCapitalize"('[
          "hello",
          "world"
        ]')
        """
      } results: {
        """
        ┌─────────────────┐
        │ [               │
        │   [0]: "Hello", │
        │   [1]: "World"  │
        │ ]               │
        └─────────────────┘
        """
      }
    }

    @DatabaseFunction(as: (([String].JSONRepresentation, Int) -> [String].JSONRepresentation).self)
    func jsonDropFirst(_ strings: [String], _ k: Int = 1) -> [String] {
      Array(strings.dropFirst(k))
    }

    @Test func customMixedRepresentation() {
      $jsonDropFirst.install(database.handle)
      assertQuery(
        Values($jsonDropFirst(#bind(["hello", "world", "goodnight", "moon"]), 2))
      ) {
        """
        SELECT "jsonDropFirst"('[
          "hello",
          "world",
          "goodnight",
          "moon"
        ]', 2)
        """
      } results: {
        """
        ┌─────────────────────┐
        │ [                   │
        │   [0]: "goodnight", │
        │   [1]: "moon"       │
        │ ]                   │
        └─────────────────────┘
        """
      }
    }

    @DatabaseFunction(as: (([String]?.JSONRepresentation) -> Int).self)
    func jsonCount(_ strings: [String]?) -> Int {
      strings?.count ?? -1
    }

    @Test func customNilRepresentation() {
      $jsonCount.install(database.handle)
      assertQuery(
        Values($jsonCount(#bind(["hello", "world", "goodnight", "moon"])))
      ) {
        """
        SELECT "jsonCount"('[
          "hello",
          "world",
          "goodnight",
          "moon"
        ]')
        """
      } results: {
        """
        ┌───┐
        │ 4 │
        └───┘
        """
      }
      assertQuery(
        Values($jsonCount(#bind(nil)))
      ) {
        """
        SELECT "jsonCount"(NULL)
        """
      } results: {
        """
        ┌────┐
        │ -1 │
        └────┘
        """
      }
    }

    final class Logger {
      var messages: [String] = []

      @DatabaseFunction
      func log(_ message: String) {
        messages.append(message)
      }
    }

    @Test func voidState() {
      let logger = Logger()
      logger.$log.install(database.handle)

      assertQuery(
        Values(logger.$log("Hello, world!"))
      ) {
        """
        SELECT "log"('Hello, world!')
        """
      } results: {
        """
        ┌──┐
        └──┘
        """
      }

      #expect(logger.messages == ["Hello, world!"])
    }

    @DatabaseFunction(as: (([Tag].JSONRepresentation) -> String).self)
    func joinTags(_ tags: [Tag]) -> String {
      tags.map(\.title).joined(separator: ", ")
    }

    @Test func jsonArray() {
      $joinTags.install(database.handle)

      assertQuery(
        Reminder
          .group(by: \.id)
          .leftJoin(ReminderTag.all) { $0.id.eq($1.reminderID) }
          .leftJoin(Tag.all) { $1.tagID.eq($2.id) }
          .select { $joinTags($2.jsonGroupArray()) }
      ) {
        """
        SELECT "joinTags"(json_group_array(CASE WHEN ("tags"."rowid") IS NOT (NULL) THEN json_object('id', json_quote("tags"."id"), 'title', json_quote("tags"."title")) END) FILTER (WHERE ("tags"."id") IS NOT (NULL)))
        FROM "reminders"
        LEFT JOIN "remindersTags" ON ("reminders"."id") = ("remindersTags"."reminderID")
        LEFT JOIN "tags" ON ("remindersTags"."tagID") = ("tags"."id")
        GROUP BY "reminders"."id"
        """
      } results: {
        """
        ┌─────────────────────┐
        │ "someday, optional" │
        │ "someday, optional" │
        │ ""                  │
        │ "car, kids"         │
        │ ""                  │
        │ ""                  │
        │ ""                  │
        │ ""                  │
        │ ""                  │
        │ ""                  │
        └─────────────────────┘
        """
      }
    }

    @DatabaseFunction(as: ((Reminder.JSONRepresentation, Bool) -> Bool).self)
    func isJSONValid(_ reminder: Reminder, _ override: Bool = false) -> Bool {
      !reminder.title.isEmpty || override
    }
    @Test func jsonObject() {
      $isJSONValid.install(database.handle)

      assertQuery(
        Reminder.select { $isJSONValid($0.jsonObject(), true) }.limit(1)
      ) {
        """
        SELECT "isJSONValid"(json_object('id', json_quote("reminders"."id"), 'assignedUserID', json_quote("reminders"."assignedUserID"), 'dueDate', json_quote("reminders"."dueDate"), 'isCompleted', json(CASE "reminders"."isCompleted" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'isFlagged', json(CASE "reminders"."isFlagged" WHEN 0 THEN 'false' WHEN 1 THEN 'true' END), 'notes', json_quote("reminders"."notes"), 'priority', json_quote("reminders"."priority"), 'remindersListID', json_quote("reminders"."remindersListID"), 'title', json_quote("reminders"."title"), 'updatedAt', json_quote("reminders"."updatedAt")), 1)
        FROM "reminders"
        LIMIT 1
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
    func isValid(_ reminder: Reminder, _ override: Bool = false) -> Bool {
      !reminder.title.isEmpty || override
    }
    @Test func table() {
      $isValid.install(database.handle)

      assertQuery(
        Reminder.select { $isValid($0, true) }.limit(1)
      ) {
        """
        SELECT "isValid"("reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt", 1)
        FROM "reminders"
        LIMIT 1
        """
      } results: {
        """
        ┌──────┐
        │ true │
        └──────┘
        """
      }
      assertQuery(
        Reminder
          .select { _ in
            $isValid(Reminder.Columns(id: 1, remindersListID: 1), true)
          }
          .limit(1)
      ) {
        """
        SELECT "isValid"(1, NULL, NULL, 0, 0, '', NULL, 1, '', '2040-02-14 23:31:30.000', 1)
        FROM "reminders"
        LIMIT 1
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
    func isNotNull(_ tag: Tag?) -> Bool {
      tag != nil
    }
    @Test func optionalTable() {
      $isNotNull.install(database.handle)

      assertQuery(
        Tag?.select { $isNotNull($0) }.limit(1)
      ) {
        """
        SELECT "isNotNull"("tags"."id", "tags"."title")
        FROM "tags"
        LIMIT 1
        """
      } results: {
        """
        ┌──────┐
        │ true │
        └──────┘
        """
      }
    }

    enum T: AliasName {}
    @DatabaseFunction(as: ((TableAlias<Tag, T>) -> Bool).self)
    func isValidAlias(_ tag: Tag) -> Bool {
      !tag.title.isEmpty
    }
    @Test func tableAlias() {
      $isValidAlias.install(database.handle)

      assertQuery(
        Tag.as(T.self).select { $isValidAlias($0) }.limit(1)
      ) {
        """
        SELECT "isValidAlias"("ts"."id", "ts"."title")
        FROM "tags" AS "ts"
        LIMIT 1
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
    func isValidDraft(_ tag: Tag.Draft) -> Bool {
      !tag.title.isEmpty
    }
    @Test func tableDraft() {
      $isValidDraft.install(database.handle)

      assertQuery(
        Tag.Draft.select { $isValidDraft($0) }.limit(1)
      ) {
        """
        SELECT "isValidDraft"("tags"."id", "tags"."title")
        FROM "tags"
        LIMIT 1
        """
      } results: {
        """
        ┌──────┐
        │ true │
        └──────┘
        """
      }
    }
  }
}
