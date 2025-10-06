# Triggers

Learn how to build trigger statements that can monitor the database for events and react.

## Overview

[Triggers](https://sqlite.org/lang_createtrigger.html) are operations that execute in your database
when some specific database event occurs. StructuredQueries comes with tools to create _temporary_
triggers in a type-safe and schema-safe fashion.

### Trigger basics

One of the most common use cases for a trigger is refreshing an "updatedAt" timestamp on a row when
it is updated in the database. One can create such a trigger SQL statement using the
``StructuredQueriesCore/Table/createTemporaryTrigger(_:ifNotExists:after:fileID:line:column:)``
static method:

@Row {
  @Column {
    ```swift
    Reminder.createTemporaryTrigger(
      after: .update { _, _ in
        Reminder.update {
          $0.updatedAt = #sql("datetime('subsec')")
        }
      }
    )
    ```
  }
  @Column {
    ```sql
    CREATE TEMPORARY TRIGGER "after_update_on_reminders@…"
    AFTER UPDATE ON "reminders"
    FOR EACH ROW
    BEGIN
      UPDATE "reminders"
      SET "updatedAt" = datetime('subsec');
    END
    ```
  }
}

This will make it so that anytime a reminder is updated in the database its `updatedAt` will be
refreshed with the current time immediately.

This pattern of updating a timestamp when a row changes is so common that the library comes with
a specialized tool just for that kind of trigger,
``TemporaryTrigger/Operation/update(touch:when:)``:

@Row {
  @Column {
    ```swift
    Reminder.createTemporaryTrigger(
      after: .update: {
        $0.updatedAt = datetime('subsec')
      }
    )
    ```
  }
  @Column {
    ```sql
    CREATE TEMPORARY TRIGGER "after_update_on_reminders@…"
    AFTER UPDATE ON "reminders"
    FOR EACH ROW
    BEGIN
      UPDATE "reminders"
      SET "updatedAt" = datetime('subsec');
    END
    ```
  }
}

And further, the pattern of specifically updating a _timestamp_ column is so common that the library
comes with another specialized too just for that kind of trigger,
``TemporaryTrigger/Operation/update(touch:when:)``:


@Row {
  @Column {
    ```swift
    Reminder.createTemporaryTrigger(
      after: .update(touch: \.updatedAt)
    )
    ```
  }
  @Column {
    ```sql
    CREATE TEMPORARY TRIGGER "after_update_on_reminders@…"
    AFTER UPDATE ON "reminders"
    FOR EACH ROW
    BEGIN
      UPDATE "reminders"
      SET "updatedAt" = datetime('subsec');
    END
    ```
  }
}

### More types of triggers

There are 3 kinds of triggers depending on the event being listened for in the database: inserts,
updates, and deletes. For each of these kinds of triggers one can perform 4 kinds of actions: a
select, insert, update, or delete. Each action can be performed either before or after the event
being listened for executes. All 24 combinations of these kinds of triggers are supported by the
library.

> Tip: SQLite generally
> [recommends against](https://sqlite.org/lang_createtrigger.html#cautions_on_the_use_of_before_triggers)
> using `BEFORE` triggers, as it can lead to undefined behavior.

Here are a few examples to show you the possibilities with triggers:

#### Non-empty tables

One can use triggers to enforce that a table is never fully emptied out. For example, suppose you
want to make sure that the `remindersLists` table always has at least one row. Then one can use an
`AFTER DELETE` trigger with an `INSERT` action to insert a stub reminders list when it detects the
last list was deleted:

@Row {
  @Column {
    ```swift
    RemindersList.createTemporaryTrigger(
      after: .delete { _ in
        RemindersList.insert {
          RemindersList.Draft(title: "Personal")
        }
      } when: { _ in
        !RemindersList.exists()
      }
    )
    ```
  }
  @Column {
    ```sql
    CREATE TEMPORARY TRIGGER "after_delete_on_remindersLists@…"
    AFTER DELETE ON "remindersLists"
    FOR EACH ROW WHEN NOT (EXISTS (SELECT * FROM "remindersLists"))
    BEGIN
      INSERT INTO "remindersLists"
      ("id", "color", "title")
      VALUES
      (NULL, 0xffaaff00, 'Personal');
    END
    ```
  }
}

#### Invoke Swift code from triggers

One can use triggers with a `SELECT` action to invoke Swift code when an event occurs in your
database. For example, suppose you want to execute a Swift function a new reminder is inserted
into the database. First you must register the function with SQLite and that depends on what
SQLite driver you are using ([here][sqlite-data-add-function] is how to do it in SQLiteData).

Suppose we registered a function called `didInsertReminder`, and further suppose it takes one
argument of the ID of the newly inserted reminder. Then one can invoke this function whenever a
reminder is inserted into the database with the following trigger:

[sqlite-data-add-function]: https://swiftpackageindex.com/pointfreeco/sqlite-data/main/documentation/sqlitedata/database-52hin/add(function:)-1z12a

@Row {
  @Column {
    ```swift
    @DatabaseFunction
    func didInsertReminder(_ id: Int) {
      // ...
    }

    Reminders.createTemporaryTrigger(
      after: .insert { new in
        Values($didInsertReminder(new.id))
      }
    )
    ```
  }
  @Column {
    ```sql
    CREATE TEMPORARY TRIGGER "after_insert_on_reminders@…"
    AFTER INSERT ON "reminders"
    FOR EACH ROW
    BEGIN
      SELECT "didInsertReminder"("new"."id")
    END
    ```
  }
}


## Topics

### Creating temporary triggers

- ``StructuredQueriesCore/Table/createTemporaryTrigger(_:ifNotExists:after:fileID:line:column:)``
- ``StructuredQueriesCore/Table/createTemporaryTrigger(_:ifNotExists:before:fileID:line:column:)``
- ``StructuredQueriesCore/Table/createTemporaryTrigger(_:ifNotExists:insteadOf:fileID:line:column:)``

### Triggers

- ``TemporaryTrigger``

### Deprecations

- ``StructuredQueriesCore/Table/createTemporaryTrigger(_:ifNotExists:afterInsertTouch:fileID:line:column:)``
- ``StructuredQueriesCore/Table/createTemporaryTrigger(_:ifNotExists:afterUpdateTouch:fileID:line:column:)``
