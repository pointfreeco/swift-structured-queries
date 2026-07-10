# Primary-keyed tables

Learn how tables with a primary key get extra tools when it comes to inserting, updating, and
deleting records.

## Overview

A primary-keyed table is one that has a column whose value is unique for the entire table. The most
common example is an "id" column that holds an integer, UUID, or some other kind of identifier.
Typically such columns are also initialized by the database so that when inserting rows into the
table you do not need to specify the primary key. The library provides extra tools that make it
easier to insert, update, and delete records that have a primary key.

### Specifying a primary key

When declaring your Swift type that represents a SQL table, you can use the `@Column` macro to
specify which field is the primary key of your table:

```swift
@Table
struct Book {
  @Column(primaryKey: true)
  let isbn: String
  var title: String
}
```

> Note: Using `primaryKey: true` does not create any kind of constraints on your table
> automatically. It is up to you to actually create this table and designate the column as the
> primary key.

The `@Table` macro will also automatically infer a field named `id` as a primary key, and so it is
not necessary to use the `@Column` macro in that case:

```swift
@Table
struct Reminder {
  // Automatically inferred '@Column(primaryKey: true)'
  let id: Int
  var title: String
}
```

> Note: At most one column can be designated as a primary key.

### Drafts

Once a primary key has been specified for a type, the `@Table` macro generates a special `Draft`
type nested inside your type. This type has all of the same fields as your type, except its primary
key field is made optional, allowing you to insert new rows without specifying the primary key so
that the database can initialize it for you:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      Reminder.Draft(title: "Get groceries")
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title")
    VALUES
      ('Get groceries')
    ```
  }
}

See <doc:TableDrafts> for more information on drafts, including how to lazily initialize columns
beyond the primary key, and how to generate drafts for tables without primary keys.

### Selects, updates, upserts, and deletions

Primary-keyed tables are also given special APIs for selecting, updating and deleting existing rows
in the table based on their primary key. For example, every primary-keyed table is given a special
``PrimaryKeyedTable/find(_:)`` static method for fetching a record by its primary key:

@Row {
  @Column {
    ```swift
    Reminder.find(42)
    // => Reminder
    ```
  }
  @Column {
    ```sql
    SELECT "reminders".…
    FROM "reminders"
    WHERE "reminders"."id" = 42
    ```
  }
}

The ``PrimaryKeyedTable/find(_:)`` method can be used for updates and deletions too:

@Row {
  @Column {
    ```swift
    Reminder.find(42).update {
      $0.isCompleted.toggle()
    }

    Reminder.find(42).delete()
    ```
  }
  @Column {
    ```sql
    UPDATE "reminders"
    SET "isCompleted" = NOT "isCompleted"
    WHERE "id" = 42

    DELETE FROM "reminders"
    WHERE "id" = 42
    ```
  }
}


A special ``PrimaryKeyedTable/update(_:)`` method is also provided to update all the fields of a row
with the corresponding primary key:

@Row {
  @Column {
    ```swift
    let reminder = Reminder(
      id: 1,
      title: "Get groceries",
      isCompleted: false
    )
    Reminder.update(reminder)
    ```
  }
  @Column {
    ```sql
    UPDATE "reminders" SET
      "title" = 'Get groceries',
      "isCompleted" = 0
    WHERE "id" = 1
    ```
  }
}

And there is an ``PrimaryKeyedTable/upsert(_:)`` method that allows updating the row if the
draft has an ID or inserting a new row if the ID is `nil`:

@Row {
  @Column {
    ```swift
    let reminder = Reminder.Draft(
      id: 1,
      title: "Get groceries",
      isCompleted: false
    )
    Reminder.upsert(reminder)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
    ("id", "isCompleted", "title")
    VALUES
    (1, 0, 'Get groceries')
    ON CONFLICT ("id") DO UPDATE SET
      "isCompleted" =
        "excluded"."isCompleted",
      "title" = "excluded"."title"
    ```
  }
}

Similarly, the ``PrimaryKeyedTable/delete(_:)`` method allows one to delete a row by its primary
key:

@Row {
  @Column {
    ```swift
    let reminder = Reminder(
      id: 1,
      title: "Get groceries",
      isCompleted: false
    )
    Reminder.delete(reminder)
    ```
  }
  @Column {
    ```sql
    DELETE "reminders"
    WHERE "id" = 1
    ```
  }
}

## Topics

### Primary keys

- ``PrimaryKeyedTable``
- ``PrimaryKeyedTableDefinition``

### Drafts

- <doc:TableDrafts>
