# JSON

Type-safe tools for encoding, decoding, extracting, and updating data stored as JSON.

## Overview

SQLite comes with a rich [library of functions](https://www.sqlite.org/json1.html) for querying and
manipulating JSON stored in the database, and this library provides type-safe tools for many of
them. This includes extracting values from deep inside a JSON document, updating parts of a
document without ever loading it into memory, and aggregating many rows into a single JSON array.

  * [Storing JSON in your tables](#Storing-JSON-in-your-tables)
  * [Extracting values from JSON](#Extracting-values-from-JSON)
  * [Updating JSON in place](#Updating-JSON-in-place)
  * [Aggregating rows into JSON](#Aggregating-rows-into-JSON)

### Storing JSON in your tables

The StructuredQueries core library provides a `JSONRepresentation` for storing a codable value as
JSON text, and this library further provides a ``Swift/Decodable/JSONBRepresentation`` for storing
a codable value in SQLite's more efficient, binary [JSONB](https://www.sqlite.org/jsonb.html)
format. See <doc:DefiningYourSchema#JSONB> for the basics of defining such columns.

For example, a `Profile` table can hold an entire `Author` document in a single column using JSONB:

> Tip: For simplicity this article uses JSON over JSONB, but you should strongly consider JSONB
> for your tables (if possible) due to its improved efficiency. Everything discussed below applies
> equally well to JSONB.

@Row {
  @Column {
    ```swift
    @Table
    struct Profile {
      let id: Int
      @Column(as: Author.JSONRepresentation.self)
      var author: Author
    }

    @Selection
    struct Author: Codable {
      var name = ""
      var isVerified = false
      var links: [Link] = []
      var pastLinks: [Link] = []
    }

    @Selection
    struct Link: Codable {
      var homepage = ""
    }
    ```
  }
  @Column {
    ```sql
    CREATE TABLE "profiles" (
      "id" INTEGER PRIMARY KEY,
      "author" BLOB NOT NULL
    ) STRICT
    ```
  }
}

Note that the nested `Author` and `Link` types are annotated with the `@Selection` macro. This
generates the column metadata that powers the type-safe, key path-based APIs described below,
allowing you to navigate into the JSON document using the same dot syntax you use for regular
Swift values.

### Extracting values from JSON

The ``QueryExpression/jsonExtract(_:)`` method invokes SQLite's
`json_extract` function to pluck a value out of a JSON document using a key path:

@Row {
  @Column {
    ```swift
    Profile.select {
      $0.author.jsonExtract(\.name)
    }
    ```
  }
  @Column {
    ```sql
    SELECT json_extract(
      "profiles"."author", '$."name"'
    )
    FROM "profiles"
    ```
  }
}

The key path can dig arbitrarily deep into the document, including subscripting into arrays:

@Row {
  @Column {
    ```swift
    Profile.select {
      $0.author.jsonExtract(
        \.links[0].homepage
      )
    }
    ```
  }
  @Column {
    ```sql
    SELECT json_extract(
      "profiles"."author",
      '$."links"[0]."homepage"'
    )
    FROM "profiles"
    ```
  }
}

The resulting expression is fully typed, and so it can be used anywhere a value of that type is
expected, such as a `WHERE` clause:

@Row {
  @Column {
    ```swift
    Profile.where {
      $0.author.jsonExtract(\.name)
        .eq("Blob")
    }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "profiles"
    WHERE json_extract(
      "profiles"."author", '$."name"'
    ) = 'Blob'
    ```
  }
}

And the ``QueryExpression/jsonArrayLength()`` and
``QueryExpression/jsonArrayLength(_:)`` methods invoke SQLite's
`json_array_length` function to count the elements of a JSON array:

@Row {
  @Column {
    ```swift
    Profile.select {
      $0.author.jsonArrayLength(\.links)
    }
    ```
  }
  @Column {
    ```sql
    SELECT json_array_length(
      "profiles"."author", '$."links"'
    )
    FROM "profiles"
    ```
  }
}

### Updating JSON in place

SQLite's JSON functions can also update parts of a JSON document directly in the database, without
ever loading the document into your application, and this library provides type-safe methods for
each of them:

  * ``QueryExpression/jsonSet(_:_:)`` sets a value at a path, creating it
    if it does not exist.
  * ``QueryExpression/jsonInsert(_:_:)`` inserts a value at a path only if
    it does not already exist.
  * ``QueryExpression/jsonReplace(_:_:)`` replaces a value at a path only
    if it already exists.
  * ``QueryExpression/jsonAppend(_:_:)`` appends an element to an array at
    a path.
  * ``QueryExpression/jsonRemove(_:)`` removes a value at a path.

For example, to rename an author without touching the rest of the document:

@Row {
  @Column {
    ```swift
    Profile.update {
      $0.author = $0.author
        .jsonSet(\.name, "Blob, Esq.")
    }
    ```
  }
  @Column {
    ```sql
    UPDATE "profiles"
    SET "author" = json_set(
      "profiles"."author",
      '$."name"', 'Blob, Esq.'
    )
    ```
  }
}

These methods can be chained together, and consecutive invocations of the same function are fused
into a single call:

@Row {
  @Column {
    ```swift
    Profile.update {
      $0.author = $0.author
        .jsonSet(\.name, "Blob, Esq.")
        .jsonSet(\.isVerified, true)
    }
    ```
  }
  @Column {
    ```sql
    UPDATE "profiles"
    SET "author" = json_set(
      "profiles"."author",
      '$."name"', 'Blob, Esq.',
      '$."isVerified"', json('true')
    )
    ```
  }
}

Each method also has a `jsonb`-prefixed variant (``QueryExpression/jsonbSet(_:_:)``,
``QueryExpression/jsonbAppend(_:_:)``, _etc._) that produces JSONB instead
of JSON text. Prefer the `jsonb` variants when the result is being stored back into a column, as
above, and the `json` variants when the result is being selected.

To move a value from one part of a document to another, combine an update with
``QueryExpression/jsonExtract(_:)``:

@Row {
  @Column {
    ```swift
    Profile.update {
      $0.author = $0.author.jsonSet(
        \.links,
        $0.author.jsonExtract(\.pastLinks)
      )
    }
    ```
  }
  @Column {
    ```sql
    UPDATE "profiles"
    SET "author" = json_set(
      "profiles"."author",
      '$."links"',
      json_extract(
        "profiles"."author", '$."pastLinks"'
      )
    )
    ```
  }
}

### Aggregating rows into JSON

The ``QueryExpression/jsonGroupArray(distinct:order:filter:)`` method invokes
SQLite's `json_group_array` aggregate function to concatenate every value in a group into a single
JSON array, which the library automatically decodes into a Swift array:

@Row {
  @Column {
    ```swift
    Reminder.select {
      $0.title.jsonGroupArray()
    }
    // => [String]
    ```
  }
  @Column {
    ```sql
    SELECT json_group_array(
      "reminders"."title"
    )
    FROM "reminders"
    ```
  }
}

This becomes especially powerful when combined with
``TableDefinition/jsonObject()``, which packages an entire table row up as a
JSON object. Invoking `jsonGroupArray` on a joined table aggregates whole associated rows, letting
you load a one-to-many association in a single query:

```swift
@Selection
struct Row {
  let remindersList: RemindersList
  @Column(as: [Reminder].JSONRepresentation.self)
  let reminders: [Reminder]
}

RemindersList
  .group(by: \.id)
  .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
  .select {
    Row.Columns(
      remindersList: $0,
      reminders: $1.jsonGroupArray()
    )
  }
```

This query selects every reminders list along with an array of all of its associated reminders,
decoded directly into the `Row` type.

## Topics

### Representing JSONB

- ``Swift/Decodable/JSONBRepresentation``

### Getting and setting JSON values

- ``QueryExpression/jsonExtract(_:)``
- ``QueryExpression/jsonbExtract(_:)``
- ``QueryExpression/jsonArrayLength()``
- ``QueryExpression/jsonArrayLength(_:)``
- ``TableDefinition/jsonObject()``
- ``TableDefinition/jsonbObject()``
- ``QueryExpression/jsonGroupArray(distinct:order:filter:)``
- ``QueryExpression/jsonbGroupArray(distinct:order:filter:)``
- ``QueryExpression/jsonInsert(_:_:)``
- ``QueryExpression/jsonbInsert(_:_:)``
- ``QueryExpression/jsonAppend(_:_:)``
- ``QueryExpression/jsonbAppend(_:_:)``
- ``QueryExpression/jsonAppend(_:)``
- ``QueryExpression/jsonbAppend(_:)``
- ``QueryExpression/jsonRemove(_:)``
- ``QueryExpression/jsonbRemove(_:)``
- ``QueryExpression/jsonReplace(_:_:)``
- ``QueryExpression/jsonbReplace(_:_:)``
- ``QueryExpression/jsonSet(_:_:)``
- ``QueryExpression/jsonbSet(_:_:)``
- ``JSONPath``
