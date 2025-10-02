import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct TableTests {
    struct DefaultSelect {
      @Dependency(\.defaultDatabase) var db

      @Table
      struct Row {
        static let all = unscoped.where { !$0.isDeleted }.order { $0.id.desc() }
        let id: Int
        var isDeleted = false
      }

      init() throws {
        try db.execute(
          #sql(
            """
            CREATE TABLE "rows" (
              "id" INTEGER PRIMARY KEY AUTOINCREMENT,
              "isDeleted" BOOLEAN NOT NULL DEFAULT 0
            )
            """
          )
        )
        try db.execute(
          Row.insert {
            Row.Draft(isDeleted: false)
            Row.Draft(isDeleted: true)
          }
        )
      }

      @Test func basics() throws {
        assertQuery(Row.where { $0.id > 0 }) {
          """
          SELECT "rows"."id", "rows"."isDeleted"
          FROM "rows"
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          ORDER BY "rows"."id" DESC
          """
        } results: {
          """
          ┌─────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultSelect.Row( │
          │   id: 1,                                    │
          │   isDeleted: false                          │
          │ )                                           │
          └─────────────────────────────────────────────┘
          """
        }
        assertQuery(Row.Draft.where { $0.id > Optional(0) }) {
          """
          SELECT "rows"."id", "rows"."isDeleted"
          FROM "rows"
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          ORDER BY "rows"."id" DESC
          """
        } results: {
          """
          ┌───────────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultSelect.Row.Draft( │
          │   id: 1,                                          │
          │   isDeleted: false                                │
          │ )                                                 │
          └───────────────────────────────────────────────────┘
          """
        }
        assertQuery(Row.select(\.id)) {
          """
          SELECT "rows"."id"
          FROM "rows"
          WHERE NOT ("rows"."isDeleted")
          ORDER BY "rows"."id" DESC
          """
        } results: {
          """
          ┌───┐
          │ 1 │
          └───┘
          """
        }
        assertQuery(Row.unscoped) {
          """
          SELECT "rows"."id", "rows"."isDeleted"
          FROM "rows"
          """
        } results: {
          """
          ┌─────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultSelect.Row( │
          │   id: 1,                                    │
          │   isDeleted: false                          │
          │ )                                           │
          ├─────────────────────────────────────────────┤
          │ SnapshotTests.TableTests.DefaultSelect.Row( │
          │   id: 2,                                    │
          │   isDeleted: true                           │
          │ )                                           │
          └─────────────────────────────────────────────┘
          """
        }
      }

      @Test func delete() throws {
        assertQuery(
          Row
            .where { $0.id > 0 }
            .delete()
            .returning(\.self)
        ) {
          """
          DELETE FROM "rows"
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """
          ┌─────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultSelect.Row( │
          │   id: 1,                                    │
          │   isDeleted: false                          │
          │ )                                           │
          └─────────────────────────────────────────────┘
          """
        }
        assertQuery(
          Row
            .delete()
            .where { $0.id > 0 }
            .returning(\.self)
        ) {
          """
          DELETE FROM "rows"
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """

          """
        }

        assertQuery(
          Row
            .unscoped
            .where { $0.id > 0 }
            .delete()
            .returning(\.self)
        ) {
          """
          DELETE FROM "rows"
          WHERE ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """
          ┌─────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultSelect.Row( │
          │   id: 2,                                    │
          │   isDeleted: true                           │
          │ )                                           │
          └─────────────────────────────────────────────┘
          """
        }
      }

      @Test func update() throws {
        assertQuery(
          Row
            .update { $0.isDeleted.toggle() }
            .where { $0.id > 0 }
            .returning(\.self)
        ) {
          """
          UPDATE "rows"
          SET "isDeleted" = NOT ("rows"."isDeleted")
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """
          ┌─────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultSelect.Row( │
          │   id: 1,                                    │
          │   isDeleted: true                           │
          │ )                                           │
          └─────────────────────────────────────────────┘
          """
        }
        assertQuery(
          Row
            .where { $0.id > 0 }
            .update { $0.isDeleted.toggle() }
            .returning(\.self)
        ) {
          """
          UPDATE "rows"
          SET "isDeleted" = NOT ("rows"."isDeleted")
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """

          """
        }

        assertQuery(
          Row
            .unscoped
            .where { $0.id > 0 }
            .update { $0.isDeleted.toggle() }
            .returning(\.self)
        ) {
          """
          UPDATE "rows"
          SET "isDeleted" = NOT ("rows"."isDeleted")
          WHERE ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """
          ┌─────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultSelect.Row( │
          │   id: 1,                                    │
          │   isDeleted: false                          │
          │ )                                           │
          ├─────────────────────────────────────────────┤
          │ SnapshotTests.TableTests.DefaultSelect.Row( │
          │   id: 2,                                    │
          │   isDeleted: false                          │
          │ )                                           │
          └─────────────────────────────────────────────┘
          """
        }
      }

      #if compiler(>=6.1)
        @Test func rescope() {
          assertQuery(Row.unscoped.all) {
            """
            SELECT "rows"."id", "rows"."isDeleted"
            FROM "rows"
            WHERE NOT ("rows"."isDeleted")
            ORDER BY "rows"."id" DESC
            """
          } results: {
            """
            ┌─────────────────────────────────────────────┐
            │ SnapshotTests.TableTests.DefaultSelect.Row( │
            │   id: 1,                                    │
            │   isDeleted: false                          │
            │ )                                           │
            └─────────────────────────────────────────────┘
            """
          }
        }

        @Test func doubleScope() {
          assertQuery(Row.all.all) {
            """
            SELECT "rows"."id", "rows"."isDeleted"
            FROM "rows"
            WHERE NOT ("rows"."isDeleted")
            ORDER BY "rows"."id" DESC
            """
          } results: {
            """
            ┌─────────────────────────────────────────────┐
            │ SnapshotTests.TableTests.DefaultSelect.Row( │
            │   id: 1,                                    │
            │   isDeleted: false                          │
            │ )                                           │
            └─────────────────────────────────────────────┘
            """
          }
        }
      #endif

      @Test func doubleConditional() {
        assertQuery(Row.select(\.id)) {
          """
          SELECT "rows"."id"
          FROM "rows"
          WHERE NOT ("rows"."isDeleted")
          ORDER BY "rows"."id" DESC
          """
        } results: {
          """
          ┌───┐
          │ 1 │
          └───┘
          """
        }
      }

      @Test func tableAliases() {
        enum R: AliasName {}
        assertQuery(Row.as(R.self).select(\.id)) {
          """
          SELECT "rs"."id"
          FROM "rows" AS "rs"
          WHERE NOT ("rs"."isDeleted")
          ORDER BY "rs"."id" DESC
          """
        } results: {
          """
          ┌───┐
          │ 1 │
          └───┘
          """
        }
        assertQuery(Row.as(R.self).unscoped.select(\.id)) {
          """
          SELECT "rs"."id"
          FROM "rows" AS "rs"
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
    }

    struct DefaultWhere {
      @Dependency(\.defaultDatabase) var db

      @Table
      struct Row {
        static let all = Self.where { !$0.isDeleted }
        let id: Int
        var isDeleted = false
      }

      init() throws {
        try db.execute(
          #sql(
            """
            CREATE TABLE "rows" (
              "id" INTEGER PRIMARY KEY AUTOINCREMENT,
              "isDeleted" BOOLEAN NOT NULL DEFAULT 0
            )
            """
          )
        )
        try db.execute(
          Row.insert {
            Row.Draft(isDeleted: false)
            Row.Draft(isDeleted: true)
          }
        )
      }

      @Test func basics() throws {
        assertQuery(Row.where { $0.id > 0 }) {
          """
          SELECT "rows"."id", "rows"."isDeleted"
          FROM "rows"
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          """
        } results: {
          """
          ┌────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultWhere.Row( │
          │   id: 1,                                   │
          │   isDeleted: false                         │
          │ )                                          │
          └────────────────────────────────────────────┘
          """
        }
        assertQuery(Row.Draft.where { $0.id > Optional(0) }) {
          """
          SELECT "rows"."id", "rows"."isDeleted"
          FROM "rows"
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          """
        } results: {
          """
          ┌──────────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultWhere.Row.Draft( │
          │   id: 1,                                         │
          │   isDeleted: false                               │
          │ )                                                │
          └──────────────────────────────────────────────────┘
          """
        }
        assertQuery(Row.unscoped) {
          """
          SELECT "rows"."id", "rows"."isDeleted"
          FROM "rows"
          """
        } results: {
          """
          ┌────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultWhere.Row( │
          │   id: 1,                                   │
          │   isDeleted: false                         │
          │ )                                          │
          ├────────────────────────────────────────────┤
          │ SnapshotTests.TableTests.DefaultWhere.Row( │
          │   id: 2,                                   │
          │   isDeleted: true                          │
          │ )                                          │
          └────────────────────────────────────────────┘
          """
        }
      }

      @Test func delete() throws {
        assertQuery(
          Row
            .delete()
            .where { $0.id > 0 }
            .returning(\.self)
        ) {
          """
          DELETE FROM "rows"
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """
          ┌────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultWhere.Row( │
          │   id: 1,                                   │
          │   isDeleted: false                         │
          │ )                                          │
          └────────────────────────────────────────────┘
          """
        }
        assertQuery(
          Row
            .where { $0.id > 0 }
            .delete()
            .returning(\.self)
        ) {
          """
          DELETE FROM "rows"
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """

          """
        }

        assertQuery(
          Row
            .unscoped
            .where { $0.id > 0 }
            .delete()
            .returning(\.self)
        ) {
          """
          DELETE FROM "rows"
          WHERE ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """
          ┌────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultWhere.Row( │
          │   id: 2,                                   │
          │   isDeleted: true                          │
          │ )                                          │
          └────────────────────────────────────────────┘
          """
        }
      }

      @Test func update() throws {
        assertQuery(
          Row
            .update { $0.isDeleted.toggle() }
            .where { $0.id > 0 }
            .returning(\.self)
        ) {
          """
          UPDATE "rows"
          SET "isDeleted" = NOT ("rows"."isDeleted")
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """
          ┌────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultWhere.Row( │
          │   id: 1,                                   │
          │   isDeleted: true                          │
          │ )                                          │
          └────────────────────────────────────────────┘
          """
        }
        assertQuery(
          Row
            .where { $0.id > 0 }
            .update { $0.isDeleted.toggle() }
            .returning(\.self)
        ) {
          """
          UPDATE "rows"
          SET "isDeleted" = NOT ("rows"."isDeleted")
          WHERE NOT ("rows"."isDeleted") AND ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """

          """
        }

        assertQuery(
          Row
            .unscoped
            .where { $0.id > 0 }
            .update { $0.isDeleted.toggle() }
            .returning(\.self)
        ) {
          """
          UPDATE "rows"
          SET "isDeleted" = NOT ("rows"."isDeleted")
          WHERE ("rows"."id") > (0)
          RETURNING "id", "isDeleted"
          """
        } results: {
          """
          ┌────────────────────────────────────────────┐
          │ SnapshotTests.TableTests.DefaultWhere.Row( │
          │   id: 1,                                   │
          │   isDeleted: false                         │
          │ )                                          │
          ├────────────────────────────────────────────┤
          │ SnapshotTests.TableTests.DefaultWhere.Row( │
          │   id: 2,                                   │
          │   isDeleted: false                         │
          │ )                                          │
          └────────────────────────────────────────────┘
          """
        }
      }

      #if compiler(>=6.1)
        @Test func rescope() {
          assertQuery(Row.unscoped.all) {
            """
            SELECT "rows"."id", "rows"."isDeleted"
            FROM "rows"
            WHERE NOT ("rows"."isDeleted")
            """
          } results: {
            """
            ┌────────────────────────────────────────────┐
            │ SnapshotTests.TableTests.DefaultWhere.Row( │
            │   id: 1,                                   │
            │   isDeleted: false                         │
            │ )                                          │
            └────────────────────────────────────────────┘
            """
          }
        }

        @Test func doubleScope() {
          assertQuery(Row.all.all) {
            """
            SELECT "rows"."id", "rows"."isDeleted"
            FROM "rows"
            WHERE NOT ("rows"."isDeleted")
            """
          } results: {
            """
            ┌────────────────────────────────────────────┐
            │ SnapshotTests.TableTests.DefaultWhere.Row( │
            │   id: 1,                                   │
            │   isDeleted: false                         │
            │ )                                          │
            └────────────────────────────────────────────┘
            """
          }
        }
      #endif

      @Test func doubleConditional() {
        assertQuery(Row.select(\.id)) {
          """
          SELECT "rows"."id"
          FROM "rows"
          WHERE NOT ("rows"."isDeleted")
          """
        } results: {
          """
          ┌───┐
          │ 1 │
          └───┘
          """
        }
      }
    }

    struct InvalidDefaultScope {
      @Dependency(\.defaultDatabase) var db

      @Table
      struct Row {
        static let all =
          unscoped
          .where {
            #sql(
              """
              CAST(\($0.id) AS TEXT) = '"rows"'
              """
            )
          }
        let id: Int
        var isDeleted = false
      }

      init() throws {
        try db.execute(
          #sql(
            """
            CREATE TABLE "rows" (
              "id" INTEGER PRIMARY KEY AUTOINCREMENT,
              "isDeleted" BOOLEAN NOT NULL DEFAULT 0
            )
            """
          )
        )
        try db.execute(
          Row.insert {
            Row.Draft(isDeleted: false)
            Row.Draft(isDeleted: true)
          }
        )
      }

      // NB: Ideally this shouldn't rewrite the text containing the table name
      @Test func invalidDefaultScope() {
        enum R: AliasName {}
        assertQuery(Row.as(R.self).select(\.id)) {
          """
          SELECT "rs"."id"
          FROM "rows" AS "rs"
          WHERE CAST("rs"."id" AS TEXT) = '"rs"'
          """
        } results: {
          """

          """
        }
      }
    }
  }
}
