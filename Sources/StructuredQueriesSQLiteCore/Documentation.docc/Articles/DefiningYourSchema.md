# Defining your schema

SQLite-specific tips for defining your schema.

## Overview

### UUID and Date representations

While some relational databases, like MySQL and Postgres, have native types for dates and UUIDs,
SQLite does _not_, and instead can represent them in a variety of ways. In order to lessen the
friction of building queries with dates and UUIDs, the library has decided to provide a default
representation for dates and UUIDs, and if that choice does not fit your schema you can explicitly
specify the representation you want.

#### Dates

Dates in SQLite have 3 different representations:

  * Text column interpreted as ISO-8601-formatted string.
  * Int column interpreted as number of seconds since Unix epoch.
  * Double column interpreted as a Julian day (number of days since November 24, 4713 BC).

By default, StructuredQueries will bind and decode dates as ISO-8601 text. If you want the library
to use a different representation (_i.e._ integer or double), you can provide an explicit query
representation to the `@Column` macro's `as:` argument. ``Foundation/Date/UnixTimeRepresentation``
will store the date as an integer, and ``Foundation/Date/JulianDayRepresentation`` will store the
date as a floating point number.

For example:

```swift
@Table struct Reminder {
  let id: Int
  @Column(as: Date.UnixTimeRepresentation.self)
  var date: Date
}
```

And StructuredQueries will take care of formatting the value for the database:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      Reminder.Draft(date: Date())
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("date")
    VALUES
      (1517184480)
    ```
  }
}

If you use the non-default date representation in your schema, then while querying against a
date column with a Swift Date, you will need to explicitly bundle up the Swift date into the
appropriate representation to use various query helpers. This can be done using the `#bind` macro:

```swift
Reminder.where { $0.created > #bind(startDate) }
```

> Note: When using the default representation for dates (ISO-8601 text) you do not need to use
> the `#bind` macro:
>
> ```swift
> Reminder.where { $0.created > startDate }
> ```

#### UUIDs

SQLite also does not have type-level support for UUIDs. By default, the library will bind and decode
UUIDs as lowercased, hexadecimal text, but it also provides custom representations. This includes
``Foundation/UUID/UppercasedRepresentation`` for uppercased text, as well as
``Foundation/UUID/BytesRepresentation`` for raw bytes.

To use such custom representations, you can provide it to the `@Column` macro's `as:` parameter:

```swift
@Table struct Reminder {
  @Column(as: UUID.BytesRepresentation.self)
  let id: UUID
  var title = ""
}
```

If you use the non-default UUID representation in your schema, then while querying against a UUID
column with a Swift UUID, you will need to explicitly bundle up the Swift UUID into the appropriate
representation to use various query helpers. This can be done using
the `#bind` macro:

```swift
Reminder.where { $0.id != #bind(reminder.id) }
```

> Note: When using the default representation for UUID (lower-cased text) you do not need to use
> the `#bind` macro:
>
> ```swift
> Reminder.where { $0.id != reminder.id }
> ```

### Binary JSON (JSONB)

The core library's `JSONRepresentation` stores a codable value as JSON text. SQLite additionally
supports [JSONB](https://sqlite.org/jsonb.html), a binary representation of JSON that is more
compact and faster for SQLite to process. To store a codable value in this format, use
``Swift/Decodable/JSONBRepresentation``, instead:

```swift
@Table struct Reminder {
  let id: Int
  var title = ""
  @Column(as: [String].JSONBRepresentation.self)
  var notes: [String] = []
}
```

Values are encoded to JSON and passed through SQLite's `jsonb` function when they are bound to a
statement, so SQLite stores its canonical binary representation in a `BLOB` column:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      Reminder.Draft(
        title: "Get groceries",
        notes: ["Milk", "Eggs", "Bananas"]
      )
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title", "notes")
    VALUES
      ('Get groceries',
       jsonb('["Milk","Eggs","Bananas"]'))
    ```
  }
}

Values are decoded directly from the binary representation, with a fallback to JSON text for
columns that contain text. This means an existing column that holds `JSONRepresentation` JSON text
can be migrated to `JSONBRepresentation` in place: existing rows will continue to decode, and rows
are converted to JSONB as they are written. To convert an entire table at once, instead:

```swift
#sql(#"UPDATE "reminders" SET "notes" = jsonb("notes")"#)
```

> Important: `JSONBRepresentation` is available on iOS 26, macOS 26, tvOS 26, visionOS 26, and
> watchOS 26, and requires a Swift 6.2 toolchain. The JSONB format itself requires SQLite 3.45.0
> or higher, which is always satisfied by the SQLite that ships with these OS versions, but may
> be relevant if you bundle your own copy of SQLite.
