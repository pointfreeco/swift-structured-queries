# JSON

Type-safe tools for encoding, decoding, extracting, and updating data stored as JSON.

## Overview

SQLite comes with a rich [library of functions](https://www.sqlite.org/json1.html) for querying and
manipulating JSON stored in the database, and this library provides type-safe tools for many of
them. This includes extracting values from deep inside a JSON document, updating parts of a
document without ever loading it into memory, and aggregating many rows into a single JSON array.

  * [Storing JSON in your tables](#Storing-JSON-in-your-tables)
  * [Extracting values from JSON](#Extracting-values-from-JSON)
  * [Querying over JSON collections](#Querying-over-JSON-collections)
  * [Updating JSON in place](#Updating-JSON-in-place)
  * [Aggregating rows into JSON](#Aggregating-rows-into-JSON)
  * [Using JSONB](#Using-JSONB)

### Storing JSON in your tables

The StructuredQueries core library provides a `JSONRepresentation` for storing a codable value as
JSON text, and this library further provides a ``Swift/Decodable/JSONBRepresentation`` for storing
a codable value in SQLite's more efficient, binary [JSONB](https://www.sqlite.org/jsonb.html)
format. See <doc:DefiningYourSchema#JSONB> for the basics of defining such columns.

For example, a `Profile` table can hold an entire `Author` document in a single column as JSON:

> Tip: For simplicity this article uses JSON over JSONB, but you should strongly consider JSONB
> for your tables (if possible) due to its improved efficiency. Everything discussed below applies
> equally well to JSONB, as described in [Using JSONB](#Using-JSONB).

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
      "author" TEXT NOT NULL
    ) STRICT
    ```
  }
}

Note that the nested `Author` and `Link` types are annotated with the `@Selection` macro. This
generates the column metadata that powers the type-safe, key path-based APIs described below,
allowing you to navigate into the JSON document using the same dot syntax you use for regular
Swift values.

> Warning: When applying `@Selection` to a `Codable` type in order to expose its schema to the
> library's tools, `@Selection` must take over responsibility for how the type is encoded and
> decoded into JSON. For this reason you **must not** provide custom `CodingKeys` for your type,
> and to enforce this we recommend turning on the "ColumnCoding" trait, which will be the default
> behavior fo the library in the future.

### Extracting values from JSON

The ``StructuredQueriesCore/QueryExpression/jsonExtract(_:)`` method invokes SQLite's
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

And the ``StructuredQueriesCore/QueryExpression/jsonArrayLength()`` and
``StructuredQueriesCore/QueryExpression/jsonArrayLength(_:)`` methods invoke SQLite's
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

### Querying over JSON collections

This library supports a few special cases of the [`json_each` table-valued function][json-each], 
such such as arrays and dictionaries. It allows you to turn a JSON array or dictionary into a 
virtual SQLite table which can be queried in its own right. It returns a full select statement 
whose rows have two columns: `key`, the element's index in an array or its key in an object, and
`value`, the element itself.

[json-each]: https://sqlite.org/json1.html#jeach

This select statement can be used as a subquery to filter rows by the contents of a JSON
collection. For example, to find every profile whose author links to a particular homepage:

@Row {
  @Column {
    ```swift
    Profile.where {
      $0.author.jsonEach(\.links)
        .where {
          $0.value.jsonExtract(\.homepage)
            .like("%pointfree.co%")
        }
        .exists()
    }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "profiles"
    WHERE EXISTS (
      SELECT
        "json_each"."key",
        "json_each"."value"
      FROM json_each(
        "profiles"."author", '$."links"'
      )
      WHERE json_extract(
        "json_each"."value", '$."homepage"'
      ) LIKE '%pointfree.co%'
    )
    ```
  }
}

Because it is an ordinary select statement, it supports the full query-building toolkit, including
`where`, `order`, `limit`, and aggregate functions, and it can be selected as a scalar subquery
alongside other columns:

@Row {
  @Column {
    ```swift
    Profile.select {
      (
        $0.id
        $0.favoriteNumbers.jsonEach()
          .select { $0.value.sum() }
      )
    }
    ```
  }
  @Column {
    ```sql
    SELECT
      "profiles"."id",
      (
        SELECT sum("json_each"."value")
        FROM json_each(
          "profiles"."author", '$."favoriteNumbers"'
        )
      )
    FROM "profiles"
    ```
  }
}

You can also join a table to `json_each` to fan each row out into one row per element of its JSON
collection:

@Row {
  @Column {
    ```swift
    Profile
      .join(Profile.columns.author.jsonEach(\.links)) { _, _ in true }
      .select {
        (
          $0.author.jsonExtract(\.name),
          $1.value.jsonExtract(\.homepage)
        )
      }
    ```
  }
  @Column {
    ```sql
    SELECT
      json_extract(
        "profiles"."author", '$."name"'
      ),
      json_extract(
        "json_each"."value", '$."homepage"'
      )
    FROM "profiles"
    JOIN json_each(
      "profiles"."author", '$."links"'
    ) ON 1
    ```
  }
}

This also works when storing JSON arrays and dictionaries of primitive types, such as `[String]` or
`[String: Int]`. In this case scalar elements are fully typed and can be compared directly, without 
any extraction:

@Row {
  @Column {
    ```swift
    @Table
    struct Reminder {
      let id: Int
      @Column(as: [String].JSONRepresentation.self)
      var tags: [String] = []
    }

    Reminder.where {
      $0.tags.jsonEach()
        .where { $0.value.eq("urgent") }
        .exists()
    }
    ```
  }
  @Column {
    ```sql
    SELECT … FROM "reminders"
    WHERE EXISTS (
      SELECT
        "json_each"."key",
        "json_each"."value"
      FROM json_each(
        "reminders"."tags"
      )
      WHERE "json_each"."value" = 'urgent'
    )
    ```
  }
}

A few things to note:

  * When iterating an object (a dictionary column), `key` is the object's key and can be filtered
    just like `value`, _e.g._ `$0.key.eq("JFK")`.
  * Invoking `jsonEach` on an optional column iterates a `NULL` document as an empty collection.
  * The ``StructuredQueriesCore/QueryExpression/jsonbEach()`` and
    ``StructuredQueriesCore/QueryExpression/jsonbEach(_:)`` methods invoke the
    `jsonb_each` function, instead, which can more efficiently iterate object elements by handing
    them to `jsonExtract` in SQLite's binary JSONB format.

### Updating JSON in place

SQLite's JSON functions can also update parts of a JSON document directly in the database, without
ever loading the document into your application, and this library provides type-safe methods for
each of them:

  * ``StructuredQueriesCore/QueryExpression/jsonSet(_:_:)`` sets a value at a path, creating it
    if it does not exist.
  * ``StructuredQueriesCore/QueryExpression/jsonInsert(_:_:)`` inserts a value at a path only if
    it does not already exist.
  * ``StructuredQueriesCore/QueryExpression/jsonReplace(_:_:)`` replaces a value at a path only
    if it already exists.
  * ``StructuredQueriesCore/QueryExpression/jsonAppend(_:_:)`` appends an element to an array at
    a path.
  * ``StructuredQueriesCore/QueryExpression/jsonRemove(_:)`` removes a value at a path.

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

[insert-replace-set]: https://sqlite.org/json1.html#the_json_insert_json_replace_and_json_set_functions

### Aggregating rows into JSON

The ``StructuredQueriesCore/QueryExpression/jsonGroupArray(distinct:order:filter:)`` method invokes
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
``StructuredQueriesCore/TableDefinition/jsonObject()``, which packages an entire table row up as a
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

### Using JSONB

Everything above stores JSON as plain text, but SQLite also supports
[JSONB](https://www.sqlite.org/jsonb.html), a binary encoding of JSON stored as a `BLOB`. This
allows SQLite to traverse the JSON and make modifications without parsing text into structured
data and then rendering structured data back to text, which can be a significant cost. JSONB is 
both slightly smaller than the equivalent text and can be processed in a fraction of the CPU cycles.

To use JSONB instead of JSON, annotate a column with ``Swift/Decodable/JSONBRepresentation`` and 
give it a `BLOB` column in your schema:

@Row {
  @Column {
    ```swift
    @Table
    struct Profile {
      let id: Int
      @Column(as: Author.JSONBRepresentation.self)
      var author: Author
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

You do not need to do any extra work to use JSONB correctly. The library makes sure to use JSONB
where necessary, such as inserting data into a table, and converts to JSON where necessary,
such as selecting from a table so that it can be decoded back into a Swift type:

@Row {
  @Column {
    ```swift
    Profile.insert {
      Profile.Draft(
        author: Author(name: "Blob")
      )
    }

    Profile.select(\.author)
    
    ```
  }
  @Column {
    ```sql
    INSERT INTO "profiles" ("author")
    VALUES (
      jsonb('{"name":"Blob",…}')
    )

      
    SELECT json("profiles"."author")
    FROM "profiles"
    ```
  }
}

Every API discussed in this article works on a JSONB column exactly as it does on a JSON column,
because SQLite's `json_*` functions accept text JSON and JSONB arguments interchangeably. Extract
values, iterate collections, and update documents in place with the same key path syntax, no
matter which representation the column uses.

However, each function has a `jsonb`-prefixed variant (``StructuredQueriesCore/QueryExpression/jsonbExtract(_:)``,
``StructuredQueriesCore/QueryExpression/jsonbSet(_:_:)``, ``StructuredQueriesCore/QueryExpression/jsonbEach()``, _etc._) that produces JSONB
output instead of JSON text. Prefer the `jsonb` variants when the result is stored back into a
column or fed into another JSON function, sparing SQLite a round trip through text:

@Row {
  @Column {
    ```swift
    Profile.update {
      $0.author = $0.author
        .jsonbSet(\.name, "Blob, Esq.")
    }
    ```
  }
  @Column {
    ```sql
    UPDATE "profiles"
    SET "author" = jsonb_set(
      "profiles"."author",
      '$."name"', 'Blob, Esq.'
    )
    ```
  }
}

## Topics

### Representing JSONB

- ``Swift/Decodable/JSONBRepresentation``

### Getting and setting JSON values

- ``StructuredQueriesCore/QueryExpression/jsonExtract(_:)``
- ``StructuredQueriesCore/QueryExpression/jsonbExtract(_:)``
- ``StructuredQueriesCore/QueryExpression/jsonArrayLength()``
- ``StructuredQueriesCore/QueryExpression/jsonArrayLength(_:)``
- ``StructuredQueriesCore/TableDefinition/jsonObject()``
- ``StructuredQueriesCore/TableDefinition/jsonbObject()``
- ``StructuredQueriesCore/QueryExpression/jsonGroupArray(distinct:order:filter:)``
- ``StructuredQueriesCore/QueryExpression/jsonbGroupArray(distinct:order:filter:)``
- ``StructuredQueriesCore/QueryExpression/jsonInsert(_:_:)``
- ``StructuredQueriesCore/QueryExpression/jsonbInsert(_:_:)``
- ``StructuredQueriesCore/QueryExpression/jsonAppend(_:_:)``
- ``StructuredQueriesCore/QueryExpression/jsonbAppend(_:_:)``
- ``StructuredQueriesCore/QueryExpression/jsonRemove(_:)``
- ``StructuredQueriesCore/QueryExpression/jsonbRemove(_:)``
- ``StructuredQueriesCore/QueryExpression/jsonReplace(_:_:)``
- ``StructuredQueriesCore/QueryExpression/jsonbReplace(_:_:)``
- ``StructuredQueriesCore/QueryExpression/jsonSet(_:_:)``
- ``StructuredQueriesCore/QueryExpression/jsonbSet(_:_:)``
- ``JSONPath``

### Iterating over JSON collections 

- ``StructuredQueriesCore/QueryExpression/jsonEach()``
- ``StructuredQueriesCore/QueryExpression/jsonEach(_:)``
- ``StructuredQueriesCore/QueryExpression/jsonbEach()``
- ``StructuredQueriesCore/QueryExpression/jsonbEach(_:)``
- ``JSONEach``
- ``JSONBEach``
