import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct ValuesTests {
    @Dependency(\.defaultDatabase) var db

    @Test func basics() {
      assertQuery(
        Values {
          (1, "Hello", true)
        }
      ) {
        """
        VALUES (1, 'Hello', 1)
        """
      } results: {
        """
        ┌───┬─────────┬──────┐
        │ 1 │ "Hello" │ true │
        └───┴─────────┴──────┘
        """
      }
    }

    @Test func multipleRows() {
      assertQuery(
        Values {
          (1, "Hello", true)
          (2, "Goodbye", false)
        }
      ) {
        """
        VALUES (1, 'Hello', 1), (2, 'Goodbye', 0)
        """
      } results: {
        """
        ┌───┬───────────┬───────┐
        │ 1 │ "Hello"   │ true  │
        │ 2 │ "Goodbye" │ false │
        └───┴───────────┴───────┘
        """
      }
    }

    @Test func controlFlow() {
      let includeGoodbye = false
      assertQuery(
        Values {
          for n in 1...2 {
            (n, "Hello")
          }
          if includeGoodbye {
            (3, "Goodbye")
          }
        }
      ) {
        """
        VALUES (1, 'Hello'), (2, 'Hello')
        """
      } results: {
        """
        ┌───┬─────────┐
        │ 1 │ "Hello" │
        │ 2 │ "Hello" │
        └───┴─────────┘
        """
      }
    }

    @Test func singleColumn() {
      assertQuery(
        Values {
          "Hello"
          "Goodbye"
        }
      ) {
        """
        VALUES ('Hello'), ('Goodbye')
        """
      } results: {
        """
        ┌───────────┐
        │ "Hello"   │
        │ "Goodbye" │
        └───────────┘
        """
      }
    }

    @Test func union() {
      assertQuery(
        Values {
          (1, "Hello", true)
        }
        .union(
          Values {
            (2, "Goodbye", false)
          }
        )
      ) {
        """
        VALUES (1, 'Hello', 1)
          UNION
        VALUES (2, 'Goodbye', 0)
        """
      } results: {
        """
        ┌───┬───────────┬───────┐
        │ 1 │ "Hello"   │ true  │
        │ 2 │ "Goodbye" │ false │
        └───┴───────────┴───────┘
        """
      }
    }

    @Test func select() {
      assertQuery(
        Select(
          Values {
            (1, "Hello", true)
            (2, "Goodbye", false)
          }
        )
        .where(\.2)
      ) {
        """
        SELECT "column1", "column2", "column3"
        FROM (
          VALUES (1, 'Hello', 1), (2, 'Goodbye', 0)
        )
        WHERE ("column3")
        """
      } results: {
        """
        ┌───┬─────────┬──────┐
        │ 1 │ "Hello" │ true │
        └───┴─────────┴──────┘
        """
      }
    }

    @Test func selectClosure() {
      assertQuery(
        Select(
          Values {
            (1, "Hello", true)
            (2, "Goodbye", false)
          }
        )
        .where { $2 }
      ) {
        """
        SELECT "column1", "column2", "column3"
        FROM (
          VALUES (1, 'Hello', 1), (2, 'Goodbye', 0)
        )
        WHERE ("column3")
        """
      } results: {
        """
        ┌───┬─────────┬──────┐
        │ 1 │ "Hello" │ true │
        └───┴─────────┴──────┘
        """
      }
    }

    @Test func selectOrder() {
      assertQuery(
        Select(
          Values {
            (1, "Hello", true)
            (2, "Goodbye", false)
          }
        )
        .order { first, second, _ in (first.desc(), second) }
      ) {
        """
        SELECT "column1", "column2", "column3"
        FROM (
          VALUES (1, 'Hello', 1), (2, 'Goodbye', 0)
        )
        ORDER BY "column1" DESC, "column2"
        """
      } results: {
        """
        ┌───┬───────────┬───────┐
        │ 2 │ "Goodbye" │ false │
        │ 1 │ "Hello"   │ true  │
        └───┴───────────┴───────┘
        """
      }
    }

    @Test func selectOrderKeyPath() {
      assertQuery(
        Select(
          Values {
            (2, "Goodbye", false)
            (1, "Hello", true)
          }
        )
        .order(by: \.0)
      ) {
        """
        SELECT "column1", "column2", "column3"
        FROM (
          VALUES (2, 'Goodbye', 0), (1, 'Hello', 1)
        )
        ORDER BY "column1"
        """
      } results: {
        """
        ┌───┬───────────┬───────┐
        │ 1 │ "Hello"   │ true  │
        │ 2 │ "Goodbye" │ false │
        └───┴───────────┴───────┘
        """
      }
    }

    @Test func selectExecute() throws {
      let rows = try db.execute(
        Select(
          Values {
            (1, "Hello", true)
            (2, "Goodbye", false)
          }
        )
        .where(\.2)
      )
      #expect(rows.count == 1)
      #expect(rows[0] == (1, "Hello", true))
    }

    @Test func insertSelectEmpty() throws {
      let condition = false
      let statement = Tag.insert {
        $0.title
      } select: {
        Select(
          Values {
            if condition {
              "chores"
            }
          }
        )
      }
      #expect(statement.query.isEmpty)
      try db.execute(statement)
    }

    @Test func selectEmpty() throws {
      let condition = false
      let statement = Select(
        Values {
          if condition {
            (1, "Hello")
          }
        }
      )
      #expect(statement.query.isEmpty)
      #expect(try db.execute(statement).isEmpty)
    }

    @Test func selectSingleColumn() {
      assertQuery(
        Select(
          Values {
            1
            2
          }
        )
      ) {
        """
        SELECT "column1"
        FROM (
          VALUES (1), (2)
        )
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

    @Test func selectionRows() {
      assertQuery(
        Values {
          HighScore.Columns(score: 100, player: "Blob")
          HighScore.Columns(score: 50, player: "Blob Jr")
        }
      ) {
        """
        VALUES (100, 'Blob'), (50, 'Blob Jr')
        """
      } results: {
        """
        ┌─────────────────────┐
        │ HighScore(          │
        │   score: 100,       │
        │   player: "Blob"    │
        │ )                   │
        ├─────────────────────┤
        │ HighScore(          │
        │   score: 50,        │
        │   player: "Blob Jr" │
        │ )                   │
        └─────────────────────┘
        """
      }
    }

    @Test func selectSelectionRows() {
      assertQuery(
        Select(
          Values {
            HighScore.Columns(score: 100, player: "Blob")
            HighScore.Columns(score: 50, player: "Blob Jr")
          }
        )
        .where { $0.player.eq("Blob") }
      ) {
        """
        SELECT "column1" AS "score", "column2" AS "player"
        FROM (
          VALUES (100, 'Blob'), (50, 'Blob Jr')
        ) AS "highScores"
        WHERE (("player") = ('Blob'))
        """
      } results: {
        """
        ┌──────────────────┐
        │ HighScore(       │
        │   score: 100,    │
        │   player: "Blob" │
        │ )                │
        └──────────────────┘
        """
      }
    }

    @Test func mixedRows() {
      assertQuery(
        Values {
          (1, HighScore.Columns(score: 100, player: "Blob"), true)
          (2, HighScore.Columns(score: 50, player: "Blob Jr"), false)
        }
      ) {
        """
        VALUES (1, 100, 'Blob', 1), (2, 50, 'Blob Jr', 0)
        """
      } results: {
        """
        ┌───┬─────────────────────┬───────┐
        │ 1 │ HighScore(          │ true  │
        │   │   score: 100,       │       │
        │   │   player: "Blob"    │       │
        │   │ )                   │       │
        ├───┼─────────────────────┼───────┤
        │ 2 │ HighScore(          │ false │
        │   │   score: 50,        │       │
        │   │   player: "Blob Jr" │       │
        │   │ )                   │       │
        └───┴─────────────────────┴───────┘
        """
      }
    }

    @Test func selectMixedRows() {
      assertQuery(
        Select(
          Values {
            (1, HighScore.Columns(score: 100, player: "Blob"), true)
            (2, HighScore.Columns(score: 50, player: "Blob Jr"), false)
          }
        )
        .where(\.2)
        .order(by: \.1.score)
      ) {
        """
        SELECT "column1", "column2" AS "score", "column3" AS "player", "column4"
        FROM (
          VALUES (1, 100, 'Blob', 1), (2, 50, 'Blob Jr', 0)
        )
        WHERE ("column4")
        ORDER BY "score"
        """
      } results: {
        """
        ┌───┬──────────────────┬──────┐
        │ 1 │ HighScore(       │ true │
        │   │   score: 100,    │      │
        │   │   player: "Blob" │      │
        │   │ )                │      │
        └───┴──────────────────┴──────┘
        """
      }
    }

    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
    @Test func selectRepresentableColumns() {
      let values = Values {
        TaggedScore.Columns(score: 100, tags: #bind(["blob", "jr"]))
      }
      assertQuery(Select(values)) {
        """
        SELECT "column1" AS "score", json("column2") AS "tags"
        FROM (
          VALUES (100, jsonb('[
          "blob",
          "jr"
        ]'))
        ) AS "taggedScores"
        """
      } results: {
        """
        ┌──────────────────┐
        │ TaggedScore(     │
        │   score: 100,    │
        │   tags: [        │
        │     [0]: "blob", │
        │     [1]: "jr"    │
        │   ]              │
        │ )                │
        └──────────────────┘
        """
      }
    }

    @Test func selectMixedRowsPositional() {
      assertQuery(
        Select(
          Values {
            (1, HighScore.Columns(score: 100, player: "Blob"), true)
            (2, HighScore.Columns(score: 50, player: "Blob Jr"), false)
          }
        )
        .where { _, _, flag in flag }
        .order { _, highScore, _ in highScore.player }
      ) {
        """
        SELECT "column1", "column2" AS "score", "column3" AS "player", "column4"
        FROM (
          VALUES (1, 100, 'Blob', 1), (2, 50, 'Blob Jr', 0)
        )
        WHERE ("column4")
        ORDER BY "player"
        """
      } results: {
        """
        ┌───┬──────────────────┬──────┐
        │ 1 │ HighScore(       │ true │
        │   │   score: 100,    │      │
        │   │   player: "Blob" │      │
        │   │ )                │      │
        └───┴──────────────────┴──────┘
        """
      }
    }

    @Test func selectMixedRowsMultiKeyOrder() {
      assertQuery(
        Select(
          Values {
            (1, HighScore.Columns(score: 100, player: "Blob"), true)
            (2, HighScore.Columns(score: 50, player: "Blob Jr"), false)
          }
        )
        .order { _, highScore, _ in highScore }
      ) {
        """
        SELECT "column1", "column2" AS "score", "column3" AS "player", "column4"
        FROM (
          VALUES (1, 100, 'Blob', 1), (2, 50, 'Blob Jr', 0)
        )
        ORDER BY "score", "player"
        """
      } results: {
        """
        ┌───┬─────────────────────┬───────┐
        │ 2 │ HighScore(          │ false │
        │   │   score: 50,        │       │
        │   │   player: "Blob Jr" │       │
        │   │ )                   │       │
        ├───┼─────────────────────┼───────┤
        │ 1 │ HighScore(          │ true  │
        │   │   score: 100,       │       │
        │   │   player: "Blob"    │       │
        │   │ )                   │       │
        └───┴─────────────────────┴───────┘
        """
      }
    }

    @Test func selectControlFlowSelectionRows() {
      assertQuery(
        Select(
          Values {
            for score in [100, 50] {
              HighScore.Columns(score: score, player: "Blob \(score)")
            }
          }
        )
      ) {
        """
        SELECT "column1" AS "score", "column2" AS "player"
        FROM (
          VALUES (100, 'Blob 100'), (50, 'Blob 50')
        ) AS "highScores"
        """
      } results: {
        """
        ┌──────────────────────┐
        │ HighScore(           │
        │   score: 100,        │
        │   player: "Blob 100" │
        │ )                    │
        ├──────────────────────┤
        │ HighScore(           │
        │   score: 50,         │
        │   player: "Blob 50"  │
        │ )                    │
        └──────────────────────┘
        """
      }
    }

    @Test func insertGroupValues() throws {
      try db.execute(
        """
        CREATE TABLE "players" ("name" TEXT, "score" INTEGER, "player" TEXT)
        """
      )
      assertQuery(
        Player.insert {
          ($0.name, $0.highScore)
        } values: {
          ("blob", HighScore(score: 100, player: "Blob"))
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "players"
        ("name", "score", "player")
        VALUES
        ('blob', 100, 'Blob')
        RETURNING "name", "score", "player"
        """
      } results: {
        """
        ┌─────────────────────────┐
        │ Player(                 │
        │   name: "blob",         │
        │   highScore: HighScore( │
        │     score: 100,         │
        │     player: "Blob"      │
        │   )                     │
        │ )                       │
        └─────────────────────────┘
        """
      }
    }

    @Test func selectionCommonTableExpression() {
      assertQuery(
        With {
          Select(
            Values {
              HighScore.Columns(score: 100, player: "Blob")
              HighScore.Columns(score: 50, player: "Blob Jr")
            }
          )
        } query: {
          HighScore.all
        }
      ) {
        """
        WITH "highScores" AS (
          SELECT "column1" AS "score", "column2" AS "player"
          FROM (
            VALUES (100, 'Blob'), (50, 'Blob Jr')
          ) AS "highScores"
        )
        SELECT "highScores"."score", "highScores"."player"
        FROM "highScores"
        """
      } results: {
        """
        ┌─────────────────────┐
        │ HighScore(          │
        │   score: 100,       │
        │   player: "Blob"    │
        │ )                   │
        ├─────────────────────┤
        │ HighScore(          │
        │   score: 50,        │
        │   player: "Blob Jr" │
        │ )                   │
        └─────────────────────┘
        """
      }
    }

    @Test func insertSelect() {
      assertQuery(
        Tag.insert {
          $0.title
        } select: {
          Select(Values { "vacation" })
        }
      ) {
        """
        INSERT INTO "tags"
        ("title")
        SELECT "column1"
        FROM (
          VALUES ('vacation')
        )
        """
      }
      assertQuery(
        Tag.insert {
          $0.title
        } select: {
          Values { "chores" }
        }
      ) {
        """
        INSERT INTO "tags"
        ("title")
        VALUES ('chores')
        """
      }
    }

    @Test func selectOrderPositional() {
      assertQuery(
        Select(
          Values {
            (2, "Goodbye", false)
            (1, "Hello", true)
          }
        )
        .order { first, _, _ in first }
      ) {
        """
        SELECT "column1", "column2", "column3"
        FROM (
          VALUES (2, 'Goodbye', 0), (1, 'Hello', 1)
        )
        ORDER BY "column1"
        """
      } results: {
        """
        ┌───┬───────────┬───────┐
        │ 1 │ "Hello"   │ true  │
        │ 2 │ "Goodbye" │ false │
        └───┴───────────┴───────┘
        """
      }
    }
  }
}

@Table
private struct Player {
  var name = ""
  var highScore: HighScore = HighScore(score: 0, player: "")
}

@Selection
private struct HighScore {
  let score: Int
  let player: String
}

@available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
@Selection
private struct TaggedScore {
  let score: Int
  @Column(as: [String].JSONBRepresentation.self)
  let tags: [String]
}
