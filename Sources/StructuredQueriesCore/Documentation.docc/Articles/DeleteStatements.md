# Deletes

Learn how to build queries that delete data from a database.

## Overview

### Deleting rows

You can create a ``Delete`` statement by invoking a table's ``Table/delete()`` function:

```swift
Reminder.delete()
// DELETE FROM "reminders"
```

> Important: Deleting from a table in an unconstrained fashion like this is probably not what you
> want, 99.99% of the time, as it will delete _every single row_ in the table. Instead, you should
> filter the delete to a specific row or set of rows that match a certain condition. See
> <doc:#Filtering-deletes>, below.

### Filtering deletes

You can filter an ``Delete`` statement by providing predicates _via_ the ``Delete/where(_:)``
method.

```swift
Reminder.delete() {
  .where { $0.id == 42 }
// DELETE FROM "reminders"
// WHERE ("reminders"."id" = 42)
```

> Tip: You can also create a ``Where`` clause and chain into its ``Where/delete()`` method to
> provide the filter up front.
>
> ```swift
> Reminder
>   .where { $0.id == 42 }
>   .delete()
> ```
>
> See <doc:WhereClauses> for more information.

### Deleting records

When it comes to tables with primary keys, you can create an ``Delete`` statement from a table value
that deletes the row with that primary key:

```swift
let reminder = … // Fetch reminder from database
Reminder.delete(reminder)
// DELETE FROM "reminders"
// WHERE ("reminders"."id" = 42)
```

### Returning

By default, ``Delete`` statements are fire-and-forget and do not return any results from the
database. To return the data deleted from the database, you can use `returning(_:)`, which
adds a `RETURNING` clause to the statement.

```swift
Reminder.delete()
  .where { $0.id == 42 }
  .returning(\.self)
// DELETE FROM "reminders"
// WHERE ("id" = 42)
// RETURNING "id", "isCompleted", "title", "priority"
// => Reminder
```

> Tip: The ``Insert`` and ``Update`` statements support `RETURNING` clauses, as well.

## Topics

### Building deletes

- ``Table/delete()``
- ``Where/delete()``

### Statement types

- ``Delete``
