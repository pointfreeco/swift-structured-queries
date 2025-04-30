# Inserts

Learn how to build queries that insert data into a database.

## Overview

### Inserting values

The most general way to insert values into a table is the ``Table/insert(or:_:values:onConflict:)``
function, which takes a trailing closure describing the columns being inserted, as well as a second
trailing closure describing the values being inserted:

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
      $0.name
    } values: {
      for name in ["home", "work", "school"] {
        name
      }
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "tags"
      ("name")
    VALUES
      ('home'),
      ('work'),
      ('school')
    ```
  }
}

### Inserting records

It's also possible to insert entire records, either using result builder syntax:

@Row {
  @Column {
    ```swift
    RemindersTag.insert {
      RemindersTag(reminderID: 1, tagID: 1)
      RemindersTag(reminderID: 1, tagID: 2)
      RemindersTag(reminderID: 2, tagID: 4)
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "remindersTags"
      ("reminderID", "tagID")
    VALUES
      (1, 1),
      (1, 2),
      (2, 4)
    ```
  }
}

Or using helpers like ``Table/insert(or:_:onConflict:)`` that take a single reminder or an array:

@Row {
  @Column {
    ```swift
    let remindersTag = RemindersTag(reminderID: 1, tagID: 1)
    RemindersTag.insert(remindersTag)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "remindersTags"
      ("reminderID", "tagID")
    VALUES
      (1, 1)
    ```
  }
}
@Row {
  @Column {
    ```swift
    let remindersTags = [
      RemindersTag(reminderID: 1, tagID: 2),
      RemindersTag(reminderID: 2, tagID: 4),
    ]
    RemindersTag.insert(remindersTags)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "remindersTags"
      ("reminderID", "tagID")
    VALUES
      (1, 2),
      (2, 4)
    ```
  }
}

### Inserting drafts

If your table has a [primary key](<doc:PrimaryKeyedTables>) that is initialized by the database,
you can insert its associated ``PrimaryKeyedTable/Draft`` type, instead, which omits specifying
this identifier. Using either result builder syntax:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      Reminder.Draft(title: "Get groceries", isFlagged: true, priority: 3, remindersListID: 1)
      Reminder.Draft(title: "Take a walk", priority: 2, remindersListID: 3)
      Reminder.Draft(title: "Get haircut", isFlagged: true, remindersListID: 2)
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
      ("title",  "isFlagged", "priority", "remindersListID")
    VALUES
      ('Get groceries', 1, 3, 1),
      ('Take a walk', 0, 2, 3),
      ('Get haircut', 1, NULL, 2)
    ```
  }
}

Or using helpers like ``PrimaryKeyedTable/insert(or:_:onConflict:)`` that take a single draft or
an array:

@Row {
  @Column {
    ```swift
    let draft = Reminder.Draft(
      title: "Get groceries",
      isFlagged: true,
      priority: 3,
      remindersListID: 1
    )
    Reminder.insert(draft)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title",  "isFlagged", "priority", "remindersListID")
    VALUES
      ('Get groceries', 1, 3, 1)
    ```
  }
}

@Row {
  @Column {
    ```swift
    let drafts = [
      Reminder.Draft(title: "Take a walk", priority: 2, remindersListID: 3),
      Reminder.Draft(title: "Get haircut", isFlagged: true, remindersListID: 2),
    ]
    Reminder.insert(drafts)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title",  "isFlagged", "priority", "remindersListID")
    VALUES
      ('Take a walk', 0, 2, 3),
      ('Get haircut', 1, NULL, 2)
    ```
  }
}

### Upserting drafts

At times your application may want to provide the same business logic for creating a new record and
editing an existing one. Your primary keyed table's `Draft` type can be used for these kinds of
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
``PrimaryKeyedTable/upsert(_:)``, which generates an ``Insert`` with an "upsert" clause:

@Row {
  @Column {
    ```swift
    Reminder.upsert(draft)
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

### Inserting from a select statement

To insert a row into a table with the results of a ``Select`` statement, use
``Table/insert(or:_:select:onConflict:)``:

@Row {
  @Column {
    ```swift
    Tag.insert {
      ($0.name)
    } select: {
      RemindersList.select { $0.title.lower() }
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "tags"
      ("name")
    SELECT lower("remindersLists"."title")
    FROM "remindersLists"
    ```
  }
}

Note that the number and type of inserted columns must match the number and type of the select
statement's columns.

### Inserting default values

To insert a row into a table where all values have database-provided defaults, use
``Table/insert(or:onConflict:)``:

@Row {
  @Column {
    ```swift
    Reminder.insert()
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders" DEFAULT VALUES
    ```
  }
}

### Returning

By default, ``Insert`` statements are fire-and-forget and do not return any results from the
database. To return the data inserted by the database, including default columns that were not
provided to the `INSERT`, you can use ``Insert/returning(_:)``, which adds a `RETURNING` clause to
the statement.

For example, you can return the primary key of an inserted draft:

@Row {
  @Column {
    ```swift
    Reminder
      .insert(draft)
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

### Conflict resolution

Every insert function includes an optional `or` parameter, which can be used to specify the `OR`
clause for conflict resolution:

@Row {
  @Column {
    ```swift
    Tag.insert(or: .ignore) {
      ($0.name)
    } values: {
      "home"
    }
    ```
  }
  @Column {
    ```sql
    INSERT OR IGNORE INTO "tags"
      ("name")
    VALUES
      ('home')
    ```
  }
}

And many include an `onConflict` parameter, which can be used to resolve conflicts _via_ an `UPDATE`
clause:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.isCompleted, $0.title, $0.priority)
    } values: {
      (false, "Get groceries", 3)
    } onConflict: {
      $0.title += " (Copy)"
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("isCompleted", "title", "priority")
    VALUES
      (0, 'Get groceries', 3),
      (0, 'Take a walk', 1),
      (1, 'Get haircut', NULL)
    ON CONFLICT DO UPDATE SET
      "title" = ("reminders"."title" || ' (Copy)')
    ```
  }
}

> Tip: The `onConflict` closure works exactly like the closure parameter of
> ``Table/update(or:set:)``. See <doc:UpdateStatements> for more information on building these
> clauses.

## Topics

### Inserting values

- ``Table/insert(or:_:values:onConflict:)``
- ``Table/insert(or:_:onConflict:)``
- ``Table/insert(or:onConflict:)``
- ``PrimaryKeyedTable/upsert(_:)``

### Inserting drafts

- ``PrimaryKeyedTable/insert(or:_:onConflict:)``

### Inserting from a select

- ``Table/insert(or:_:select:onConflict:)``

### Statement types

- ``Insert``

### Seeding a database

- ``Seeds``
