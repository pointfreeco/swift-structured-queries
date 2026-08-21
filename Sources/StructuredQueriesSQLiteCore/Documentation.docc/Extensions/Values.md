# ``Values``

A `VALUES` statement can be executed on its own, or it can be wrapped in a `Select` to filter and
order its rows using SQLite's automatic `"column1"` through `"columnN"` names:

```swift
Select(
  Values {
    (1, "Hello", true)
    (2, "Goodbye", false)
  }
)
.where { $2 }
// SELECT "column1", "column2", "column3"
// FROM (VALUES (1, 'Hello', 1), (2, 'Goodbye', 0))
// WHERE ("column3")
```

Rows of `@Selection` and `@Table` values alias the automatic names back to their column names,
which makes a wrapped `Values` a convenient seed for a common table expression:

```swift
Select(
  Values {
    HighScore.Columns(score: 100, player: "Blob")
  }
)
// SELECT "column1" AS "score", "column2" AS "player"
// FROM (VALUES (100, 'Blob')) AS "highScores"
```

## Topics

### Creating a values statement

- ``init(_:)``

### Referring to values

- ``TableColumns``
