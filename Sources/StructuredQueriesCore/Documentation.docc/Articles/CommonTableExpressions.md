# Common table expressions

Learn how to build statements that factor subqueries into temporary tables, and create hierarchical
or recursive queries of trees and graphs.

## Overview

One can build [common table expressions][] (commonly referred to as CTEs) by using the ``With``
statement, along with the `@Selection` macro. CTEs allow you to refactor complex queries into
smaller pieces, and they allow you to execute recursive queries that can traverse tree-like and
graph-like tables.

[common table expressions]: https://sqlite.org/lang_with.html

### The basics

In its most basic form, CTEs are a tool to refactor complex queries into simpler, smaller pieces.
They allow you to define a kind of "virtual table" that represents a data set, and then use
that table in larger `SELECT`, `INSERT`, `UPDATE`, and `DELETE` statements.

To begin one uses the ``With`` statement to act as an entry point into CTE syntax, which takes a
trailing closure where the CTE tables can be defined in a result builder context, and another
trailing closure where the CTE tables can be queried and joined:

```swift
With {
  // Define CTE tables here
} query: {
  // Use CTE tables to build query here
}
```

As a simple example, consider selecting all reminders lists whose average priority of the reminders
in the list is greater than 1.5. One can do this with the following query:

```swift
RemindersList
  .group(by: \.id)
  .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
  .select { remindersList, _ in remindersList }
  .having { $1.priority.avg() > 1.5 }
```

This works well enough, but this query may get more complicated in the future with additional joins,
more `where` logic, orders, _etc._ CTEs give you the opportunity to refactor the core logic of
selecting only lists whose average priority of reminders is greater than 1.5 into a separate "table"
that can then be used in another query.

One can define a new type that represents the data you want to pre-compute as a CTE, and you
annotate the type with `@Selection`:

```swift
@Selection
struct HighPriorityRemindersList {
  let id: RemindersList.ID
}
```

You can think of this as a "virtual table" of sorts, rather than an actual database table.

Then you can select into this table in the first trailing closure of ``With``:

```swift
With {
  RemindersList
    .group(by: \.id)
    .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
    .select { remindersList, _ in
      HighPriorityRemindersList.Columns(
        id: remindersList.id
      )
    }
    .having { $1.priority.avg() > 1.5 }
} query: {
  // Use CTE tables here
}
```

And finally you can write a new query that involves the CTE table defined:

```swift
With {
  RemindersList
    .group(by: \.id)
    .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
    .select { remindersList, _ in
      HighPriorityRemindersList.Columns(
        id: remindersList.id
      )
    }
    .having { $1.priority.avg() > 1.5 }
} query: {
  RemindersList
    .where { $0.id.in(HighPriorityRemindersList.select(\.id)) }
}
```

Notice that `HighPriorityRemindersList` behaves as if it is a regular table even though it is a
CTE table and not actually stored anywhere. And now you can chain on additional operators and logic
without conflating it with the core logic of the `HighPriorityRemindersList` CTE:

```swift
With {
  RemindersList
    .group(by: \.id)
    .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
    .select { remindersList, _ in
      HighPriorityRemindersList.Columns(
        id: remindersList.id
      )
    }
    .having { $1.priority.avg() > 1.5 }
} query: {
  RemindersList
    .where { $0.id.in(HighPriorityRemindersList.select(\.id)) }
    .where { $0.title.contains("work") }
    .order(by: \.title)
}
```

The CTE syntax also works with `INSERT`, `UPDATE`, and `DELETE` statements. For example, to update
the title of every "high priority" list one can do the following:

```swift
With {
  RemindersList
    .group(by: \.id)
    .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
    .select { remindersList, _ in
      HighPriorityRemindersList.Columns(
        id: remindersList.id
      )
    }
    .having { $1.priority.avg() > 1.5 }
} query: {
  RemindersList
    .where { $0.id.in(HighPriorityRemindersList.select(\.id)) }
    .update {
      $0.title += " (Urgent!)"
    }
}
```

Or, if you wanted to delete all of the lists that are _not_ high priority:

```swift
With {
  RemindersList
    .group(by: \.id)
    .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
    .select { remindersList, _ in
      HighPriorityRemindersList.Columns(
        id: remindersList.id
      )
    }
    .having { $1.priority.avg() > 1.5 }
} query: {
  RemindersList
    .where { !$0.id.in(HighPriorityRemindersList.select(\.id)) }
    .delete()
}
```

### Recursive queries

CTEs become more than just a refactoring tool when they recursively refer to themselves. They can
be used to recursively compute data as well as traverse of tree-like and graph-like data structures
held in tables.

##### Counter query

As a simple example let's construct a query that selects the numbers from 1 to 100. We can start
by defining a CTE data type that holds the data we want to compute:

```swift
@Selection
struct Counts {
  let value: Int
}
```

With that done we can begin our CTE using the ``With`` statement which takes a trailing closure
for builder syntax:

```swift
With {
}
```

In the trailing closure we first specify the initial condition of a recursive query by stating
the number we want to start with in our counter. In our case it will be 1:

```swift
With {
  Counts(value: 1)
}
```

Then we use the ``PartialSelectStatement/union(all:_:)`` operator to union the initial condition
with the recursive query:

```swift
With {
  Counts(value: 1)
    .union(
      all: true,
      // Recursive query
    )
}
```

And then we can implement the recursive query by selecting from `Counts` and incrementing its value
by 1:

```swift
With {
  Counts(value: 1)
    .union(
      all: true,
      Counts.select {
        Counts.Columns(value: $0.value + 1)
      }
    )
}
```

This constructs the CTE table from which we can select and limit to the first 100 values:

@Row {
  @Column {
    ```swift
    With {
      Counts(value: 1)
        .union(
          all: true,
          Counts.select {
            Counts.Columns(
              value: $0.value + 1
            )
          }
        )
    } query: {
      Counts.limit(100)
    }
    ```
  }
  @Column {
    ```sql
    WITH "counts" AS (
      SELECT 1 AS "value"
        UNION ALL
      SELECT
        ("counts"."value" + 1) AS "value"
      FROM "counts"
    )
    SELECT "counts"."value"
    FROM "counts"
    LIMIT 100
    ```
  }
}

##### Fibonacci query

The previous query was a simple example of what is known as a "[recurrence relation][]."
Another example of a recurrence relation is the Fibonacci sequence, where each term in
the sequence is the sum of the previous two terms. We can construct a query to compute the
first 10 Fibonacci numbers by first defining a data type that holds an index and its corresponding
Fibonacci number, as well as the previous Fibonacci number:

[recurrence relation]: https://en.wikipedia.org/wiki/Recurrence_relation

```swift
@Selection
private struct Fibonacci {
  let n: Int
  let prevFib: Int
  let fib: Int
}
```

Then we can construct a CTE table by seeding the initial value and `union`ing that with the
recursive query that increments the index by one, stores the current Fibonacci number in
the previous value, and sums the previous and current Fibonacci number:

@Row {
  @Column {
    ```swift
    With {
      Fibonacci(n: 1, prevFib: 0, fib: 1)
        .union(
          all: true,
          Fibonacci
            .select {
              Fibonacci.Columns(
                n: $0.n + 1,
                prevFib: $0.fib,
                fib: $0.prevFib + $0.fib
              )
            }
        )
    } query: {
      Fibonacci
        .select(\.fib)
        .limit(10)
    }
    ```
  }
  @Column {
    ```sql
    WITH "fibonaccis" AS (
      SELECT
        1 AS "n",
        0 AS "prevFib",
        1 AS "fib"
      UNION ALL
      SELECT
        ("fibonaccis"."n" + 1) AS "n",
        "fibonaccis"."fib" AS "prevFib",
        ("fibonaccis"."prevFib"
          + "fibonaccis"."fib") AS "fib"
      FROM "fibonaccis"
    )
    SELECT "fibonaccis"."fib"
    FROM "fibonaccis"
    LIMIT 10
    ```
  }
}


## Topics

### Statements

- ``With``

### Supporting types

- ``CommonTableExpressionBuilder``
- ``CommonTableExpressionClause``
