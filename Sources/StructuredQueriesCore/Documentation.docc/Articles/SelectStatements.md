# Selects

Learn how to build queries that read data from a database.

## Overview

### Selecting columns

The ``Table/select(_:)`` function is used to specify the result columns of a query. Given a simple
table definition:

```swift
@Table
struct Reminder {
  let id: Int
  var title = ""
  var isCompleted = false
}
```

We can invoke `select` and specify any number of result columns as a variadic tuple from the table
columns passed to a trailing closure:

@Row {
  @Column {
    ```swift
    Reminder.select(\.id)
    ```
  }
  @Column {
    ```sql
    SELECT "reminders"."id"
    FROM "reminders"
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder
      .select { ($0.id, $0.title) }
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."title"
    FROM "reminders"
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder
      .select {
        ($0.id, $0.title, $0.isCompleted)
      }
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."title",
      "reminders"."isCompleted"
    FROM "reminders"
    ```
  }
}

These selected columns become the row data type that will be decoded from a database.

```swift
Reminder.select { ($0.id, $0.title, $0.isCompleted) }
// => (Int, String, Bool)
```

Selection is incremental, so multiple chained calls to `select` will result in a statement that
returns a tuple of the combined columns:

```swift
let q1 = Reminder.select(\.id)     // => Int
let q2 = q1.select(\.title)        // => (Int, String)
let q3 = q2.select(\.isCompleted)  // => (Int, String, Bool)
```

To add (or remove) a `DISTINCT` clause from a selection, use ``Select/distinct(_:)``:

@Row {
  @Column {
    ```swift
    Reminder
      .distinct()
      .select(\.title)
    ```
  }
  @Column {
    ```sql
    SELECT DISTINCT
      "reminders"."title"
    FROM "reminders"
    ```
  }
}

To bundle selected columns up into a custom data type, you can annotate a struct of decoded results
with the `@Selection` macro:

```swift
@Selection
struct ReminderResult {
  let title: String
  let isCompleted: Bool
}

let query = Reminder.select {
  ReminderResult.Columns(
    title: $0.title,
    isCompleted: $0.isCompleted
  )
}
// => ReminderResult
```

To bundle up incrementally-selected columns, you can use the ``Select/map(_:)`` operator, which is
handed the currently-selected columns:

@Row {
  @Column {
    ```swift
    let query = Reminder
      .select(\.id)
      .select(\.title)
      .select(\.isCompleted)

    query.map { _, title, isCompleted in
      ReminderResult.Columns(
        title: $0.title,
        isCompleted: $0.isCompleted
      )
    }
    // => ReminderResult
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."title",
      "reminders"."isCompleted"
    FROM "reminders"
    ```
  }
}

### Joining tables

The `join`, `leftJoin`, `rightJoin`, and `fullJoin` functions are used to specify the various
flavors of joins in a query. Each take a query on the join table, as well as trailing closure that
is given the columns of each table so that it can describe the join constraint:

@Row {
  @Column {
    ```swift
    RemindersList
      .join(Reminder.all) {
        $0.id == $1.remindersListID
      }
    // => (RemindersList, Reminder)
    ```
  }
  @Column {
    ```sql
    SELECT
      "remindersLists".…,
      "reminders".…
    FROM "remindersLists"
    JOIN "reminders"
      ON "remindersLists"."id"
        = "reminders"."remindersListID"
    ```
  }
}

> Tip: The `==` function is heavily overloaded in Swift and can slow down the compiler. Consider
> using [`eq`](<doc:QueryExpression/eq(_:)>) and [`is`](<doc:QueryExpression/is(_:)>) instead. See
> <doc:CompilerPerformance> for more information.

The joined query has access to both tables' columns in subsequent chained builder methods:

@Row {
  @Column {
    ```swift
    RemindersList
      .join(Reminder.all) {
        $0.id == $1.remindersListID
      }
      .select { ($0.title, $1.title) }
    // => (String, String)
    ```
  }
  @Column {
    ```sql
    SELECT
      "remindersLists"."title",
      "reminders"."title"
    FROM "remindersLists"
    JOIN "reminders"
      ON "remindersLists"."id"
        = "reminders"."remindersListID"
    ```
  }
}

Joins are incremental, so multiple chained calls to `join` will result in a statement of all the
joins:

@Row {
  @Column {
    ```swift
    RemindersList
      .join(Reminder.all) {
        $0.id == $1.remindersListID
      }
      .join(User.all) {
        $1.assignedUserID == $2.id
      }
    // => (RemindersList, Reminder, User)
    ```
  }
  @Column {
    ```sql
    SELECT
      "remindersLists".…,
      "reminders".…,
      "users".…
    FROM "remindersLists"
    JOIN "reminders"
      ON "remindersLists"."id"
        = "reminders"."remindersListID"
    JOIN "users"
      ON "reminders"."assignedUserID"
        = "users"."id"
    ```
  }
}

Joins combine each query together by concatenating their existing clauses together, including
selected columns, joins, filters, and more.

@Row {
  @Column {
    ```swift
    RemindersList
      .select(\.title)
      .join(Reminder.select(\.title) {
        // ...
      }
    // => (String, String)
    ```
  }
  @Column {
    ```sql
    SELECT
      "remindersLists"."title",
      "reminders"."title"
    FROM "remindersLists"
    JOIN "reminders"
      ON "remindersLists"."id"
        = "reminders"."remindersListID"
    ```
  }
}

@Row {
  @Column {
    ```swift
    RemindersList
      .where { $0.id == 1 }
      .join(Reminder.where(\.isFlagged) {
        // ...
      }
    // => (RemindersList, Reminder)
    ```
  }
  @Column {
    ```sql
    SELECT
      "remindersLists".…,
      "reminders".…
    FROM "remindersLists"
    JOIN "reminders"
      ON "remindersLists"."id"
        = "reminders"."remindersListID"
    WHERE ("remindersLists"."id" = 1)
      AND "reminders"."isFlagged"
    ```
  }
}

Outer joins---left, right, and full---optionalize the data of the _outer_ side(s) of the joins.

| Join operator                           | Result columns                |
| --------------------------------------- | ----------------------------- |
| `RemindersList.join(Reminder.all)`      | `(RemindersList, Reminder)`   |
| `RemindersList.leftJoin(Reminder.all)`  | `(RemindersList, Reminder?)`  |
| `RemindersList.rightJoin(Reminder.all)` | `(RemindersList?, Reminder)`  |
| `RemindersList.fulljoin(Reminder.all)`  | `(RemindersList?, Reminder?)` |

Tables that join themselves must be aliased to disambiguate the resulting SQL. This can be done by
introducing an ``AliasName`` conformance and passing it to ``Table/as(_:)``:

```swift
@Table
struct User {
  let id: Int
  var name = ""
  var referrerID: Int?
}
enum Referrer: AliasName {}
```

@Row {
  @Column {
    ```swift
    let usersWithReferrers = User
      .leftJoin(User.as(Referrer.self).all) {
        $0.referrerID == $1.id
      }
      .select { ($0.name, $1.name) }
    // => (String, String?)
    ```
  }
  @Column {
    ```sql
    SELECT
      "users"."name",
      "referrers"."name"
    FROM "users"
    JOIN "users" AS "referrers"
      ON "users"."referrerID"
        = "referrers"."id"
    ```
  }
}

### Filtering results

The `where` function is used to filter the results of a query. It passes the table columns to a
closure that specifies a predicate expression:

@Row {
  @Column {
    ```swift
    Reminder
      .where(\.isCompleted)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    WHERE "reminders"."isCompleted"
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder
      .where {
        !$0.isCompleted
          && $0.title.like("%groceries%")
      }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    WHERE "reminders"."isCompleted"
    AND (
      "reminders"."title"
        LIKE '%groceries%'
    )
    ```
  }
}

> Tip: ``Table/where(_:)`` returns a ``Where`` clause, which builds into a ``Select``, ``Update``,
> or ``Delete`` depending on the method chaining. See <doc:WhereClauses> for more.

Filtering is incremental, so multiple chained calls to `where` will result in a statement that
returns an `AND` of the combined predicates:

@Row {
  @Column {
    ```swift
    Reminder
      .where(\.isCompleted)
      .where {
        $0.title.like("%groceries%")
      }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    WHERE "reminders"."isCompleted"
    AND (
      "reminders"."title"
        LIKE '%groceries%'
    )
    ```
  }
}

The closure is a result builder that can conditionally generate parts of the predicate:

@Row {
  @Column {
    ```swift
    var showCompleted = true
    Reminder.where {
      if !showCompleted {
        !$0.isCompleted
      }
    }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    WHERE (
      NOT "reminders"."isCompleted"
    )
    ```
  }
}

@Row {
  @Column {
    ```swift
    let showCompleted = false
    Reminder.where {
      if !showCompleted {
        !$0.isCompleted
      }
    }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    ```
  }
}


Existing `Where` clauses can be added to a query using the `and` and `or` methods:

```swift
extension Reminder {
  static let completed = Self.where(\.isCompleted)
  static let flagged = Self.where(\.isFlagged)
}
```

@Row {
  @Column {
    ```swift
    Reminder.completed
      .and(Reminder.flagged)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    WHERE ("reminders"."isCompleted")
      AND ("reminders"."isFlagged")
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder.completed
      .or(Reminder.flagged)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    WHERE ("reminders"."isCompleted")
      OR ("reminders"."isFlagged")
    ```
  }
}

### Grouping results

The `group(by:)` function is used to add a grouping to a query.

@Row {
  @Column {
    ```swift
    Reminder
      .group(by: \.priority)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    GROUP BY "reminders"."priority"
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder
      .group {
        ($0.isCompleted, $0.priority)
      }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    GROUP BY
      "reminders"."isCompleted",
      "reminders"."priority"
    ```
  }
}

Grouping is incremental, so multiple chained calls to `group(by:)` will result in a statement that
combines them:

@Row {
  @Column {
    ```swift
    Reminder
      .group(by: \.isCompleted)
      .group(by: \.priority)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    GROUP BY
      "reminders"."isCompleted",
      "reminders"."priority"
    ```
  }
}

### Filtering by aggregates

The `having` function is used to add a predicate to a query's `HAVING` clause.

@Row {
  @Column {
    ```swift
    Reminder
      .group(by: \.priority)
      .having { $0.id.count() > 1 }
      .select {
        ($0.priority, $0.id.count())
      }
    // => (Int?, Int)
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."priority",
      count("reminders"."id")
    GROUP BY "reminders"."priority"
    HAVING count("reminders"."id") > 1
    ```
  }
}

Like `where`, `having` is incremental, and multiple chained calls will `AND` their predicates
together.

### Sorting results

The `order(by:)` function is used to add an ordering term to a query's `ORDER BY` clause.

@Row {
  @Column {
    ```swift
    Reminder
      .order(by: \.title)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    ORDER BY "reminders"."title"
    ```
  }
}

Any number of ordering terms can be specified in a call to `order`, and
``QueryExpression/asc(nulls:)`` and ``QueryExpression/desc(nulls:)`` can be used to specify the
direction.

@Row {
  @Column {
    ```swift
    Reminder
      .order {
        ($0.priority.desc(nulls: .first),
         $0.title.asc())
      }
    ```
  }
  @Column {
    ```sql
     SELECT … FROM "reminders"
    ORDER BY
      "reminders"."priority" DESC
        NULLS FIRST,
      "reminders"."title" ASC
    ```
  }
}

Multiple chained calls to `order` will accumulate each term:

@Row {
  @Column {
    ```swift
    Reminder
      .order { $0.priority.desc() }
      .order(by: \.title)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    ORDER BY
      "reminders"."priority" DESC,
      "reminders"."title"
    ```
  }
}

The closure is a result builder that can conditionally generate ordering terms:

```swift
enum Ordering {
  case dueDate
  case priority
  case title
}
```

@Row {
  @Column {
    ```swift
    var ordering: Ordering = .dueDate
    Reminder.order {
      switch ordering {
      case .dueDate:
        ($0.isCompleted, $0.date)
      case .priority:
        ($0.isCompleted, $0.priority.desc(), $0.isFlagged.desc())
      case .title:
        ($0.isCompleted, $0.title)
      }
    }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    ORDER BY 
      "reminders"."isCompleted", 
      "reminders"."date"
    ```
  }
}

### Paginating results

The `limit(_:offset:)` function is used to change a query's `LIMIT` and `OFFSET` clauses.

@Row {
  @Column {
    ```swift
    Reminder.limit(10)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    LIMIT 10
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder.limit(10, offset: 10)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    LIMIT 10 OFFSET 10
    ```
  }
}

Multiple chained calls to `limit` will override the limit and offset to the last call:

@Row {
  @Column {
    ```swift
    Reminder
      .limit(10, offset: 10)
      .limit(20)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    LIMIT 20
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder
      .limit(10)
      .limit(20, offset: 20)
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    LIMIT 20 OFFSET 20
    ```
  }
}

### Compound selects

It is possible to combine multiple selects together using the `union`, `intersect`, and `except`
functions, which apply the appropriate SQL operator between each statement.

@Row {
  @Column {
    ```swift
    RemindersList.select(\.title)
      .union(Reminder.select(\.title))
    ```
  }
  @Column {
    ```sql
    SELECT "remindersLists"."title"
    FROM "remindersLists"
      UNION
    SELECT "reminders"."title"
    FROM "reminders"
    ```
  }
}

@Row {
  @Column {
    ```swift
    RemindersList.select(\.title)
      .intersect(Reminder.select(\.title))
    ```
  }
  @Column {
    ```sql
    SELECT "remindersLists"."title"
    FROM "remindersLists"
      INTERSECT
    SELECT "reminders"."title"
    FROM "reminders"
    ```
  }
}

@Row {
  @Column {
    ```swift
    RemindersList.select(\.title)
      .intersect(Reminder.select(\.title))
    ```
  }
  @Column {
    ```sql
    SELECT "remindersLists"."title"
    FROM "remindersLists"
      EXCEPT
    SELECT "reminders"."title"
    FROM "reminders"
    ```
  }
}

## Topics

### Statement types

- ``Select``
- ``SelectStatement``
- ``PartialSelectStatement``
- ``Values``

### Convenience type aliases

- ``SelectStatementOf``

### Supporting types

- ``NullOrdering``

### Self-joins

- ``TableAlias``
- ``AliasName``

<!--### Compound selects-->
