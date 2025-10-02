# Inserts

Learn how to build queries that insert data into a database.

## Overview

### Inserting records

The simplest way to insert table records into the database is the
 [`Table.insert`](<doc:Table/insert(_:values:onConflict:where:doUpdate:where:)>), which takes a
trailing closure and the record(s) to be inserted:

@Row {
  @Column {
    ```swift
    let tag = Tag(title: "car")
    Tag.insert { tag }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "tags"
      ("title")
    VALUES
      ('car')
    ```
  }
}

@Row {
  @Column {
    ```swift
    let tags = [
      Tag(title: "car"),
      Tag(title: "kids"),
      Tag(title: "someday"),
      Tag(title: "optional")
    ]
    Tag.insert { tags }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "tags"
      ("title")
    VALUES
      ('car'),
      ('kids'),
      ('someday'),
      ('optional')
    ```
  }
}

The `values` trailing closure is a result builder that can insert any number of expressions and
supports basic control flow statements:

@Row {
  @Column {
    ```swift
    Tag.insert {
      if vehicleOwner {
        Tag(title: "car")
      }
      Tag(title: "kids"),
      Tag(title: "someday"),
      Tag(title: "optional")
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "tags"
      ("title")
    VALUES
      ('car'),
      ('kids'),
      ('someday'),
      ('optional')
    ```
  }
}

### Inserting drafts

If your table has a [primary key](<doc:PrimaryKeyedTables>) that is initialized by the database,
you can insert its associated ``PrimaryKeyedTable/Draft`` type, instead, which allows you to omit
specifying this identifier. Using result builder syntax:

@Row {
  @Column {
    ```swift
    let draft = Reminder.Draft(
      title: "Get groceries",
      isFlagged: true,
      priority: 3,
      remindersListID: 1
    )
    Reminder.insert { draft }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("id", "title",  "isFlagged", "priority", "remindersListID")
    VALUES
      (NULL, 'Get groceries', 1, 3, 1),
    ```
  }
}

### Inserting values

It is also possible to build insert statements for an explicit subset of columns by specifying them
in the first trailing closure, and then using the second trailing closure to describe the values
being inserted:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.remindersListID, $0.title, $0.priority, $0.isFlagged)
    } values: {
      (1, "Get groceries", 3, true)
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("remindersListID", "title", "priority", "isFlagged")
    VALUES
      (1, 'Get groceries', 3, 1)
    ```
  }
}

The `values` trailing closures is a result builder that can insert one or more rows in a single
statement:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.remindersListID, $0.title, $0.priority, $0.isFlagged)
    } values: {
      (1, "Get groceries", 3, true)
      (3, "Take a walk", 2, false)
      (2, "Get haircut", nil, true)
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("remindersListID", "title", "priority", "isFlagged")
    VALUES
      (1, 'Get groceries', 3, 1),
      (3, 'Take a walk', 2, 0),
      (2, 'Get haircut', NULL, 1)
    ```
  }
}

As well as introduce conditional or looping logic:

@Row {
  @Column {
    ```swift
    Tag.insert {
      $0.title
    } values: {
      for title in ["home", "work", "school"] {
        title
      }
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "tags"
      ("title")
    VALUES
      ('home'),
      ('work'),
      ('school')
    ```
  }
}

### Inserting from a select statement

To insert a row into a table with the results of a ``Select`` statement, use
``Table/insert(_:select:onConflict:)``:

@Row {
  @Column {
    ```swift
    Tag.insert {
      $0.title
    } select: {
      RemindersList.select { $0.title.lower() }
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "tags"
      ("title")
    SELECT lower("remindersLists"."title")
    FROM "remindersLists"
    ```
  }
}

Note that the number and type of inserted columns must match the number and type of the select
statement's columns.

### Inserting default values

To insert a row into a table where all values have database-provided defaults, use
``Table/insert()``:

@Row {
  @Column {
    ```swift
    Timestamp.insert()
    ```
  }
  @Column {
    ```sql
    INSERT INTO "timestamps" DEFAULT VALUES
    ```
  }
}

### Returning results

By default, ``Insert`` statements are fire-and-forget and do not return any results from the
database. To return the data inserted by the database, including default columns that were not
provided to the `INSERT`, you can use ``Insert/returning(_:)``, which adds a `RETURNING` clause to
the statement.

For example, you can return the primary key of an inserted draft:

@Row {
  @Column {
    ```swift
    Reminder
      .insert { draft }
      .returning(\.id)
    // => Int
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title",  "isFlagged", "priority", "remindersListID")
    VALUES
      ('Get groceries', 1, 3, 1)
    RETURNING "id"
    ```
  }
}

Or you can populate an entire record from the freshly-inserted database:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.remindersListID, $0.title)
    } values: {
      (1, "Get groceries")
    }
    .returning(\.self)
    // => Reminder
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("remindersListID", "title", "priority", "isFlagged")
    VALUES
      (1, 'Get groceries', 3, 1)
    RETURNING "id", "isCompleted", "priority", "remindersListID", "title"
    ```
  }
}

> Tip: The ``Update`` and ``Delete`` statements support `RETURNING` clauses, as well.

### Upserting drafts

At times your application may want to provide the same business logic for creating a new record and
editing an existing one. Your primary-keyed table's `Draft` type can be used for these kinds of
flows, and it is possible to create a draft from an existing value using ``TableDraft/init(_:)``:

```swift
// Render a form for a new record
ReminderForm(
  draft: Reminder.Draft(remindersListID: remindersList.id)
)

// Render a form for an existing record by converting it to a draft
ReminderForm(
  draft: Reminder.Draft(reminder)
)
```

When the draft is ready to be committed back to the database, you can use
``PrimaryKeyedTable/upsert(values:)``, which generates an ``Insert`` with an "upsert" clause:

@Row {
  @Column {
    ```swift
    Reminder.upsert { draft }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("id", "isCompleted", "remindersListID", "title")
    VALUES
      (1, 0, 1, 'Cash check')
    ON CONFLICT DO UPDATE SET
      "isCompleted" = "excluded"."isCompleted",
      "remindersListID" = "excluded"."remindersListID",
      "title" = "excluded"."title"
    ```
  }
}

### Conflict resolution and upserts

Most insert functions include an optional upsert clause. You can unconditionally upsert using the
`onConflictDoUpdate` trailing closure:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.isCompleted, $0.priority, $0.title)
    } values: {
      (false, .high, "Get groceries")
    } onConflictDoUpdate: {
      $0.title += " (Copy)"
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("isCompleted", "title", "priority")
    VALUES
      (0, 3, 'Get groceries'),
    ON CONFLICT DO UPDATE SET
      "title" = ("reminders"."title" || ' (Copy)')
    ```
  }
}

Or you can conditionally upsert from given indexed columns using `onConflict:doUpdate:`:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.isCompleted, $0.priority, $0.title)
    } values: {
      (false, .high, "Get groceries")
    } onConflict: {
      $0.title
    } doUpdate: {
      $0.title += " (Copy)"
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("isCompleted", "priority", "title")
    VALUES
      (0, 3, 'Get groceries'),
    ON CONFLICT ("title") DO UPDATE SET
      "title" = ("reminders"."title" || ' (Copy)')
    ```
  }
}

Upsert clauses have an additional, special argument for referring to a row that failed to insert.

```swift
@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.isCompleted, $0.priority, $0.title)
    } values: {
      (false, .high, "Get groceries")
    } onConflict: {
      $0.title
    } doUpdate: {
      $0.isCompleted = $1.isCompleted
      $0.priority = $1.priority
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("isCompleted", "priority", "title")
    VALUES
      (0, 3, 'Get groceries'),
    ON CONFLICT ("title") DO UPDATE SET
      "isCompleted" = "excluded"."isCompleted",
      "priority" = "excluded"."priority"
    ```
  }
}
```

`WHERE` conditions are also supported, on both the conflict and update clauses.

> Tip: The `onConflictDoUpdate` and `doUpdate` closures work similarly to the closure parameter of
> ``Table/update(set:)``. See <doc:UpdateStatements> for more information on building these
> clauses.

## Topics

### Inserting values

- ``Table/insert(_:values:onConflict:where:doUpdate:where:)``
- ``Table/insert(_:values:onConflictDoUpdate:where:)``
- ``Table/insert()``

### Inserting drafts

- ``PrimaryKeyedTable/upsert(values:)``

### Inserting from a select

- ``Table/insert(_:select:onConflict:where:doUpdate:where:)``

### Upserts

- ``Table/Excluded``

### Statement types

- ``Insert``

### Seeding a database

- ``Seeds``
