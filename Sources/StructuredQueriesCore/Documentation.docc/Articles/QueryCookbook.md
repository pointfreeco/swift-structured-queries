# Query cookbook

Learn advanced techniques in writing queries with this library, including reusing queries, default
scopes, and decoding into custom data types.

## Overview

The library comes with a variety of tools that allow you to define helpers for composing together
large and complex queries.

* [Reusable table queries](#Reusable-table-queries)
* [Reusable column queries](#Reusable-column-queries)
* [Default scopes](#Default-scopes)
* [Custom selections](#Custom-selections)

### Reusable table queries

One can define query helpers as statics on their tables in order to facilitate using those
queries in a variety of situations. For example, suppose that the `Reminder` and `RemindersList`
tables had a `deletedAt` column that represents when the record was deleted so that the record
could be restored for a certain amount of time. These tables can be represented like so:

```swift
@Table
struct RemindersList: Identifiable {
  let id: Int
  var title = ""
  var deletedAt: Date?
}
@Table
struct Reminder: Identifiable {
  let id: Int
  var title = ""
  var isCompleted = false
  var dueAt: Date?
  var deletedAt: Date?
  var remindersListID: RemindersList.ID
}
```

It is then possible to define a `notDeleted` helper that automatically applies a `where` clause
to filter out deleted lists and reminders:

```swift
extension RemindersList {
  static let notDeleted = Self.where { $0.deletedAt.isNot(nil) }
}
extension Reminder {
  static let notDeleted = Self.where { $0.deletedAt.isNot(nil) }
}
```

> Note: If your project is using [default main actor isolation] then you further need to annotate
> your extension as `nonisolated`, or define the helpers directly in the declaration of the struct.
[default main actor isolation]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md

Then these helpers can be used when composing together a larger, more complex query. For example,
we can select all non-deleted lists with the count of all non-deleted reminders in each list like
so:

@Row {
  @Column {
    ```swift
    RemindersList
      .notDeleted
      .group(by: \.id)
      .leftJoin(Reminder.notDeleted) {
        $0.id.eq($1.remindersListID)
      }
      .select { ($0.title, $1.id.count()) }
    ```
  }
  @Column {
    ```sql
      SELECT
        "remindersLists"."title",
        count("reminders"."id")
      FROM "remindersLists"
      LEFT JOIN "reminders"
      ON "remindersLists"."id"
        = "reminders"."remindersListID"
      WHERE "remindersLists"."deletedAt"
        IS NOT NULL
      AND "reminders"."deletedAt"
        IS NOT NULL
    ```
  }
}

Further, if you are compiling with Swift 6.1 or higher, then you can chain these static helpers
anywhere in the query builder, not just directly on the type of the table. For example, we can
specify `notDeleted` after the `group(by:)` clause:

```swift
RemindersList
  .group(by: \.id)
  .notDeleted
  .leftJoin(Reminder.notDeleted) { $0.id.eq($1.remindersListID) }
  .select { ($0.title, $1.id.count()) }
```

This produces the same query even though the `notDeleted` static helper is chained after the
`group(by:)` clause.

> Tip: If you are familiar with Ruby on Rails, this feature is similar to Active Record
> [scopes](https://guides.rubyonrails.org/active_record_querying.html#scopes):
>
> ```ruby
> class Reminder < ApplicationRecord
>   scope :not_deleted, -> { where(deleted_at: nil) }
> end
>
> Reminder.not_deleted
> Reminder.group(:id).not_deleted
> ```

### Reusable column queries

It is also possible to define helpers on the ``Table/TableColumns`` type inside each table that
make it easier to share column logic amongst many queries. For example, you can define helpers on
`Reminder.TableColumns` that query for reminders that are "past due", "due today" or "scheduled
for later":

```swift
extension Reminder.TableColumns {
  var isPastDue: some QueryExpression<Bool> {
    !isCompleted && #sql("date(\(dueAt)) < date()")
  }
  var isToday: some QueryExpression<Bool> {
    !isCompleted && #sql("date(\(dueAt)) = date()")
  }
  var isScheduled: some QueryExpression<Bool> {
    !isCompleted && #sql("date(\(dueAt)) > date()")
  }
}
```

> Note: If your project is using [default main actor isolation] then you further need to annotate
> your extension as `nonisolated`.
[default main actor isolation]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md

Then you can use these helpers when building a query. For example, you can use
``PrimaryKeyedTableDefinition/count(distinct:filter:)`` to count the number of past due, current and
scheduled reminders in one single query like so:

@Row {
  @Column {
    ```swift
    Reminder
      .select {
        (
          $0.count(filter: $0.isPastDue),
          $0.count(filter: $0.isToday),
          $0.count(filter: $0.isScheduled)
        )
      }
    // => (Int, Int, Int)
    ```
  }
  @Column {
    ```sql
    SELECT
      count(
        "id" FILTER (
          WHERE (NOT "isCompleted")
          AND (date("dueAt") < date())
        )
      ),
      count(
        "id" FILTER (
          WHERE (NOT "isCompleted")
          AND (date("dueAt") = date())
        )
      ),
      count(
        "id" FILTER (
          WHERE (NOT "isCompleted")
          AND (date("dueAt") > date())
        )
      )
    FROM "reminders"
    ```
  }
}

### Default scopes

By default, every ``Table`` conformance comes with an ``Table/all`` property that represents
selecting all rows from the table:

@Row {
  @Column {
    ```swift
    Reminder.all
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    ```
  }
}

It is possible to provide an alternative implementation to ``Table/all`` for your tables so that
certain SQL clauses are automatically applied. For example, if the `Reminder` table has a
`deletedAt` column to represent when the record was deleted without actually deleting it from
the database, then you can default `Reminder.all` to query for only non-deleted records:

```swift
struct Reminder {
  let id: Int
  var title = ""
  var isCompleted = false
  var deletedAt: Date?

  static let all = Self.where { $0.isDeleted.isNot(nil) }
}
```

Now when `Reminder.all` is used it will automatically filter out deleted reminders. This also
includes when using ``Table/where(_:)``, ``Table/select(_:)``, ``Table/order(by:)``, and
other query entry points:

@Row {
  @Column {
    ```swift
    Reminder
      .where { !$0.isCompleted }
    ```
  }
  @Column {
    ```sql
    SELECT …
    FROM "reminders"
    WHERE ("deletedAt" IS NOT NULL)
    AND (NOT "isCompleted")
    ```
  }
}

If you ever want to reset the default scope back to select all rows with no SQL clauses applied,
you can use the ``Table/unscoped`` property:

@Row {
  @Column {
    ```swift
    Reminder.unscoped
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    ```
  }
}

> Tip: If you are familiar with Ruby on Rails, this feature is similar to Active Record's [default scopes](https://guides.rubyonrails.org/active_record_querying.html#applying-a-default-scope).
>
> ```ruby
> class Reminder < ApplicationRecord
>   default_scope { where(deleted_at: nil) }
> end
>
> Reminder.all      # all non-deleted reminders
> Reminder.unscope  # all reminders
> ```

### Custom selections

It will often be the case that you want to select very specific data from your database and then
decode that data into a custom Swift data type. For example, if you are displaying a list of
reminders and only need their titles for the list, it would be wasteful to decode an array of all
reminder data. The `@Selection` macro allows you to define a custom data type of only the fields you
want to decode:

```swift
@Selection
struct ReminderTitle {
  let title: String
}
```

Then when selecting the columns for your query you can use this data type:

@Row {
  @Column {
    ```swift
    Reminder
      .where { !$0.isCompleted }
      .select {
        ReminderTitle.Columns(
          title: $0.title
        )
      }
    // => ReminderTitle
    ```
  }
  @Column {
    ```sql
    SELECT "title"
    FROM "reminders"
    WHERE (NOT "isCompleted")
    ```
  }
}

As another example, consider the query that selects all reminders lists with the count of reminders
in each list. A data type can be defined like so:

```swift
@Selection
struct RemindersListWithCount {
  let remindersCount: Int
  let remindersList: RemindersList
}
```

And a query that selects into this type can be defined like so:

@Row {
  @Column {
    ```swift
    RemindersList
      .group(by: \.id)
      .join(Reminder.all) {
        $0.id.eq($1.remindersListID)
      }
      .select {
        RemindersListWithCount.Columns(
          remindersCount: $1.count()
          remindersList: $0
        )
      }
    // => RemindersListWithCount
    ```
  }
  @Column {
    ```sql
    SELECT
      count("reminders"."id")
        AS "remindersCount",
      "remindersLists".…
    FROM "remindersLists"
    JOIN "reminders"
    ON "remindersLists"."id"
      = "reminders"."remindersListID"
    GROUP BY "remindersLists"."id"
    ```
  }
}
