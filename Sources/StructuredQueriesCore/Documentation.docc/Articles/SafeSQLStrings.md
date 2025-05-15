# Safe SQL strings

Learn how to write hand-crafted SQL strings in a safe manner by leveraging the `#sql` macro.

## Overview

While it is possible to write many queries with StructuredQueries' type-safe query building APIs,
the library also provides the `#sql` macro, which invites you to write SQL directly as a string, but
in a manner that is still safe from table and column name typos, SQL injection, and other syntax
errors.

### SQL fragments

The `#sql` macro can be used to introduce SQL strings into a query at the granularity of your
choosing.

For example, you can introduce a string for invoking the SQL `date()` function, but write the rest
of the query using the builder APIs:

@Row {
  @Column {
    ```swift
    Reminder
      .where { $0.dueDate < #sql("date()") }
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."title",
      "reminders"."dueDate",
      "reminders"."isCompleted"
    FROM "reminders"
    WHERE "reminders"."dueDate" < date()
    ```
  }
}

The macro returns a query expression (``SQLQueryExpression``, to be precise) with a type that is
inferred by the context of its use. In the above case, the `dueDate` column is a query expression of
an optional date (`Date?`), and so the `<` operator helps Swift infer that `#sql("date()")` is an
optional date, as well.

It's also possible to write the entire `WHERE` clause using the macro:

@Row {
  @Column {
    ```swift
    Reminder
      .where { #sql("\($0.dueDate) < date()") }
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."title",
      "reminders"."dueDate",
      "reminders"."isCompleted"
    FROM "reminders"
    WHERE "reminders"."dueDate" < date()
    ```
  }
}

In this case `#sql` is inferred to be a query expression of a `Bool` because this is what is
returned from `where`'s trailing closure.

Note that `$0.dueDate` is interpolated directly into the string and rendered as the underlying SQL
string. This shows that you can retain all the static guarantees provided by the `@Table` macro when
writing SQL strings. Also note that this is a completely safe form of interpolation and is not
simply using Swift's default string interpolation: query expressions are safely written into the
underlying SQL, and Swift values are safely bound as statement parameters, preventing SQL injection
attacks.

### SQL statements

It is even possible to write entire SQL statements using `#sql`. For example, the previous query
could be written as a single invocation of the macro:

@Row {
  @Column {
    ```swift
    #sql(
      """
      SELECT \(Reminder.columns)
      FROM \(Reminder.self)
      WHERE \(Reminder.dueDate) < date()
      """,
      as: Reminder.self
    )
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."title",
      "reminders"."dueDate",
      "reminders"."isCompleted"
    FROM "reminders"
    WHERE "reminders"."dueDate" < date()
    ```
  }
}

All of the columns provided to trailing closures in the query builder are available statically on
each table type, so you can freely interpolate this schema information into the SQL string.

> Important: _Always_ interpolate as much static schema information as possible into the SQL string
> to better ensure that queries are correct and will successfully decode.
>
> For example:
>
> ```diff
> -SELECT * FROM reminders
> +SELECT \(Reminder.columns) FROM \(Reminder.self)
> ```
>
>   * Selecting "`*`" requires that the column order in the database matches the field order in the
>     Swift data type. Because StructuredQueries decodes columns in positional order, a query using
>     "`*`" will fail to decode unless the field order matches exactly. Instead of leaving this to
>     chance, prefer interpolating `Table.columns`, which will generate an explicit SQL column
>     selection that matches the order of fields in the Swift data type.
>   * Spelling out table and column names directly inside the query (_e.g._ "`reminders`") can lead
>     to runtime errors due to typos or stale queries that refer to schema columns that have been
>     renamed or removed. Instead, prefer interpolating `Table.columnName` to refer to a particular
>     column (_e.g._, `Reminder.isCompleted`), and `Table.self` to refer to a table (_e.g._,
>     `Reminder.self`).

Note that the query's represented type cannot be inferred here, and so the `as` parameter is used
to let Swift know that we expect to decode the `Reminder` type when we execute the query.

If we omit the `as` parameter, a return type of `Void` is assumed, which is appropriate if we don't
expect any data to be returned from the statement, _e.g._ during a schema migration:

```swift
#sql(
  """
  ALTER TABLE "reminders"
  ADD COLUMN "notes" TEXT NOT NULL DEFAULT ''
  """
)
```

### SQL bindings

Values can be interpolated into `#sql` strings to produce dynamic queries:

@Row {
  @Column {
    ```swift
    let isCompleted = true

    #sql(
      """
      SELECT count(*)
      FROM \(Reminder.self)
      WHERE \(Reminder.isCompleted) = \(isCompleted)
      """,
      as: Reminder.self
    )
    ```
  }
  @Column {
    ```sql
    SELECT count(*)
    FROM "reminders"
    WHERE "reminders"."isCompleted" = ?
    -- [1]
    ```
  }
}

Note that although it seems that `isCompleted` is being interpolated directly into the string, that
is not what is happening. The interpolated value is captured as a separate statement binding in
order to protect against SQL injection.

String bindings are handled in a special fashion to make it clear what the intended usage is. If you
interpolate a string into a `#sql` string, you will get a deprecation warning:

```swift
let searchText = "%get%"
#sql(
  """
  SELECT \(Reminder.columns)
  FROM \(Reminder.self)
  WHERE \(Reminder.title) COLLATE NOCASE LIKE \(searchText)
  """,
  as: Reminder.self
)
// ⚠️ 'appendInterpolation' is deprecated: String interpolation produces a bind for a string value;
//     did you mean to make this explicit? To append raw SQL, use "\(raw: sqlString)".
```

If you mean to bind the string as a value, you can update the interpolation to use
``QueryFragment/StringInterpolation/appendInterpolation(bind:)``:

@Row {
  @Column {
    ```swift
    let searchText = "%get%"
    #sql(
      """
      SELECT \(Reminder.columns)
      FROM \(Reminder.self)
      WHERE \(Reminder.title) COLLATE NOCASE LIKE \(bind: searchText)
      """,
      as: Reminder.self
    )
    ```
  }
  @Column {
    ```sql
    SELECT …
    FROM "reminders"
    WHERE "title" COLLATE NOCASE LIKE ?
    -- ["get"]
    ```
  }
}

If you mean to interpolate the string directly into the SQL you can use
``QueryFragment/StringInterpolation/appendInterpolation(raw:)``:

@Row {
  @Column {
    ```swift
    let searchText = "%get%"
    #sql(
      """
      SELECT \(Reminder.columns)
      FROM \(Reminder.self)
      WHERE \(Reminder.title) COLLATE NOCASE LIKE '\(raw: searchText)'
      """,
      as: Reminder.self
    )
    ```
  }
  @Column {
    ```sql
    SELECT …
    FROM "reminders"
    WHERE "title" COLLATE NOCASE LIKE '%get%'
    ```
  }
}

> Warning: It is dangerous to use raw SQL interpolation as it makes your queries susceptible to SQL
> injection attacks:
>
> ```swift
> let searchText = "' OR 1=1 OR '"
> #sql(
>   """
>   SELECT \(Reminder.columns)
>   FROM \(Reminder.self)
>   WHERE \(Reminder.title) COLLATE NOCASE LIKE '%\(raw: searchText)%'
>   """,
>   as: Reminder.self
> )
> // SELECT …
> // FROM "reminders"
> // WHERE "title" COLLATE NOCASE LIKE '%' OR 1=1 OR '%'
> ```
>
> This has caused _all_ reminders to be returned, which may be a security risk. Avoid raw SQL
> interpolation at all costs.

### SQL linting

The `#sql` macro introduces additional compile-time safety to ensure your SQL is syntactically
valid. For example, the following fragment contains a syntax error that might be hard to spot among
the many parentheses involved in the function calls and interpolation:

```swift
Reminder.where {
  #sql("NOT (length(\($0.notes) > length(\($1.title)))")
  // ⚠️ Cannot find ')' to match opening '(' in SQL string
}
```

The macro catches such issues at _compile_ time.

It also ensures that parameters are bound at appropriate parts of the SQL string, _e.g._ outside of
identifiers and text literals:

```swift
Reminder.select {
  #sql("'\($0.id.count()) rows'", as: String.self)
  // 🛑 Bind after opening "'" in SQL string
}
```

This lets us know that we've made a mistake, and should be doing the string concatenation ourselves:

```swift
Reminder.select {
  #sql("\($0.id.count()) || ' rows'", as: String.self)
}
```

## Topics

### Supporting types

- ``QueryFragment``
- ``SQLQueryExpression``
