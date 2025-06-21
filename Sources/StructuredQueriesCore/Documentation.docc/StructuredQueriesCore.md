# ``StructuredQueriesCore``

A library for building SQL in a type-safe, expressive, and composable manner. This module is
automatically imported when you `import StructuredQueries`.

## Overview

StructuredQueries provides a suite of tools that empower you to write safe, expressive, composable
SQL with Swift. By simply attaching macros to types that represent your database schema:

```swift
@Table
struct Reminder {
  let id: Int
  var title = ""
  var isCompleted = false
  var priority: Int?
  var dueDate: Date?
}
```

You get instant access to a rich set of query building APIs, such as ``Table/all``,
``Table/where(_:)``, ``Table/order(by:)``, and more:

@Row {
  @Column {
    ```swift
    Reminder.all
    // => [Reminder]
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."title",
      "reminders"."isCompleted",
      "reminders"."priority",
      "reminders"."dueDate"
    FROM "reminders";
    ```
  }
}
@Row {
  @Column {
    ```swift
    Reminder
      .select {
        ($0.priority,
         $0.title.groupConcat())
      }
      .where { !$0.isCompleted }
      .group(by: \.priority)
      .order { $0.priority.desc() }
    // => [(Int?, String)]
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."priority",
      group_concat("reminders"."title")
    FROM "reminders"
    WHERE (NOT "reminders"."isCompleted")
    GROUP BY "reminders"."priority"
    ORDER BY "reminders"."priority" DESC;
    ```
  }
}

These APIs help you avoid runtime issues caused by typos and type errors, but they still embrace SQL
for what it is. StructuredQueries is not an ORM or a new query language you have to learn: its APIs
are designed to read closely to the SQL it generates, though they are often more succinct, and
always safer.

You are also never constrained by the query builder. You are free to introduce
[_safe_ SQL strings](<doc:SafeSQLStrings>) at the granularity of your choice using the `#sql`
macro. From small expressions:

```swift
Reminder.where {
  !$0.isCompleted && #sql("\($0.dueDate) < date()")
}
```

To entire statements:

```swift
#sql(
  """
  SELECT \(Reminder.columns) FROM \(Reminder.self)
  WHERE \(Reminder.priority) >= \(selectedPriority)
  """,
  as: Reminder.self
)
```

The library supports building everything from [`SELECT`](<doc:SelectStatements>),
[`INSERT`](<doc:InsertStatements>), [`UPDATE`](<doc:UpdateStatements>), and
[`DELETE`](<doc:DeleteStatements>) statements, to recursive common table expressions. Continue
reading to learn more about building SQL with StructuredQueries.

> Important: This library does not come with any database drivers for making actual database
> requests, _e.g._, to SQLite, Postgres, MySQL. This library focuses only on building SQL statements
> and providing the tools that would allow you to integrate with another library that makes the
> actual database requests. See <doc:Integration> for information on how to integrate this library
> with a database library.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:DefiningYourSchema>
- <doc:PrimaryKeyedTables>
- <doc:SafeSQLStrings>
- <doc:QueryCookbook>
- <doc:CompilerPerformance>

### Statements

- <doc:SelectStatements>
- <doc:InsertStatements>
- <doc:UpdateStatements>
- <doc:DeleteStatements>
- <doc:WhereClauses>
- <doc:Triggers>
- <doc:CommonTableExpressions>
- <doc:StatementTypes>

### Expressions

- <doc:AggregateFunctions>
- <doc:Operators>
- <doc:ScalarFunctions>
- ``Case``
- <doc:ExpressionTypes>

### Advanced

- <doc:Integration>
