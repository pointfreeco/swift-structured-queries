# Aggregate functions

Aggregate data in your queries using SQL functions.

## Overview

StructuredQueries surfaces a number of aggregate functions as type-safe methods in its query
builder,
discoverable _via_ autocomplete.

@Row {
  @Column {
    ```swift
    Reminder
      .select { $0.priority.avg() }
    ```
  }
  @Column {
    ```sql
    SELECT avg("reminders"."priority")
    FROM "reminders"
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder.select {
      $0.id.count(filter: $0.isCompleted)
    }
    ```
  }
  @Column {
    ```sql
    SELECT
      count("reminders"."id") FILTER (
        WHERE "reminders"."isCompleted"
      )
    FROM "reminders"
    ```
  }
}

@Row {
  @Column {
    ```swift
    Reminder.select {
      $0.title.groupConcat(
        ", ",
        order: $0.title
      )
    }
    ```
  }
  @Column {
    ```sql
    SELECT
      group_concat(
        "reminders"."title",
        ', '
        ORDER BY "reminders"."title"
      )
    FROM "reminders"
    ```
  }
}

Explore the full list below.

## Topics

### Aggregating values

- ``QueryExpression/avg(distinct:filter:)``
- ``AggregateFunction/count()``
- ``QueryExpression/count(distinct:filter:)``
- ``QueryExpression/groupConcat(_:)``
- ``QueryExpression/groupConcat(distinct:)``
- ``QueryExpression/max()``
- ``QueryExpression/min()``
- ``QueryExpression/sum(distinct:filter:)``
- ``QueryExpression/total(distinct:filter:)``
