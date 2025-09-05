# "Where" clauses

Learn how to share filtering logic across `SELECT`, `UPDATE`, and `DELETE` statements.

## Overview

StructuredQueries models `WHERE` clauses as a distinct type, ``Where``, that can be used to
produce ``Select``, ``Update``, or ``Delete`` statements accordingly.

Values of this type are returned from ``Table/where(_:)``, and only become another statement type
when chaining into other builder methods, like ``Where/select(_:)``, ``Where/update(set:)``, and
``Where/delete()``.

By default, a ``Where`` statement is executed as a `SELECT`:

@Row {
  @Column {
    ```swift
    Reminder.where(\.isCompleted)
    // Where<Reminder>
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    WHERE "reminders"."isCompleted"
    ```
  }
}

But chaining into the `update` function will return an `UPDATE` statement filtered by the `WHERE`
clause:

@Row {
  @Column {
    ```swift
    Reminder
      .where(\.isCompleted)
      .update {
        $0.isCompleted = false
      }
    ```
  }
  @Column {
    ```sql
    UPDATE "reminders" SET
      "isCompleted" = 0
    WHERE "reminders"."isCompleted"
    ```
  }
}

Likewise chaining into `delete` will return a filtered `DELETE` statement:

@Row {
  @Column {
    ```swift
    Reminder
      .where(\.isCompleted)
      .delete()
    ```
  }
  @Column {
    ```sql
    DELETE FROM "reminders"
    WHERE "reminders"."isCompleted"
    ```
  }
}

## Topics

### Statements

- ``Where``
