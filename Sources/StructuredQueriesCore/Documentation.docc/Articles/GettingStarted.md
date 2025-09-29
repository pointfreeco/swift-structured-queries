# Getting started

Learn how to quickly become familiar with the basic tools of the library.

## Overview

This library provides a suite of tools that empower you to write type-safe, expressive, and
composable SQL statements using Swift. It can help you catch simple mistakes when writing your
queries, such as typos in your columns names, or comparing two different data types. Learn the
basics of writing your first `SELECT`, `INSERT`, `UPDATE`, and `DELETE` queries, as well as writing
safe SQL strings directly.

> Important: This library does not come with any database drivers for making actual database
> requests, _e.g._, to SQLite, Postgres, MySQL. This library focuses only on building SQL statements
> and providing the tools that would allow you to integrate with another library that makes the
> actual database requests. See <doc:Integration> for information on how to integrate this library
> with a database library.

  * [Writing your first query](#Writing-your-first-query)
  * [Insert statements](#Insert-statements)
  * [Update statements](#Update-statements)
  * [Delete statements](#Delete-statements)
  * [Safe SQL strings](#Safe-SQL-strings)

### Writing your first query

Before you can write a query you must have a Swift data type that represents the table in your
database. For example a table of reminders may have the following Swift struct to represent its
values in an app:

```swift
struct Reminder {
  let id: Int
  var isCompleted = false
  var title = ""
  var priority: Int?
}
```

In order to generate the code that gives the library access to the schema of this table, one can
simply apply the `@Table` macro:

```swift
import StructuredQueries

@Table
struct Reminder {
  // ...
}
```

That generates all the code necessary to give you access to a type-safe set of APIs for querying the
"reminders" table.

For example, to query for all reminders one can simply use the ``Table/all`` static property
available to every table:

@Row {
  @Column {
    ```swift
    Reminder.all
    // => [Reminder]
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."isCompleted",
      "reminders"."title",
      "reminders"."priority"
    FROM "reminders"
    ```
  }
}

To filter out certain rows from the selection, like say the completed reminders, one can use the
``Table/where(_:)`` method available on all tables:

@Row {
  @Column {
    ```swift
    Reminder
      .where { !$0.isCompleted }
    // => [Reminder]
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."isCompleted",
      "reminders"."title",
      "reminders"."priority"
    FROM "reminders"
    WHERE (NOT "reminders"."isCompleted")
    ```
  }
}

The trailing closure of ``Table/where(_:)`` is handed a value that represents the definition of
your table, including the names and types of its columns. Referencing a column on this value that
does not exist is a compiler error:

```swift
Reminder.where { !$0.completed }  🛑
```

Further, logical operations performed with this value are automatically translated into the
equivalent SQL predicate logic. For example, if you want to select only incomplete reminders that
are high priority (_i.e._ the `priority` field is 3), then you can do the following:

@Row {
  @Column {
    ```swift
    Reminder
      .where {
        !$0.isCompleted
          && $0.priority == 3
      }
    // => [Reminder]
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."isCompleted",
      "reminders"."title",
      "reminders"."priority"
    FROM "reminders"
    WHERE
      (NOT "reminders"."isCompleted")
      AND ("reminders"."priority" = 3)
    ```
  }
}

Notice how the Swift `&&` operator is translated to SQL's `AND`, and Swift's `==` operator
translates to `=`. Further, the value "3" is not literally interpolated into the final query
string. Instead, the SQL generated separates the raw SQL string from the bound parameters.
See ``QueryFragment`` for more information.

> Tip: Using heavily overloaded operators such as `==` can tax the compiler, and so for those times
> we provide an equivalent method for each operator. If you use [`eq`](<doc:QueryExpression/eq(_:)>)
> instead of [`==`](<doc:QueryExpression/==(_:_:)>) the compiler can type check your expressions
> much faster. See <doc:CompilerPerformance> for more info.

Further, because the library knows about the type information of each column it can prevent you from
making nonsensical comparisons, such as selecting reminders whose priority is equal to the string
"dog":

```swift
Reminder.where { $0.priority == "dog" }  🛑
```

The library also supports many of the standard SQL operations. For example, to select all reminders
that have the substring "Get" somewhere in its title one can use the
``QueryExpression/like(_:escape:)`` method:

@Row {
  @Column {
    ```swift
    Reminder
      .where { $0.title.like("%Get%") }
    // => [Reminder]
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."isCompleted",
      "reminders"."title",
      "reminders"."priority"
    FROM "reminders"
    WHERE
      ("reminders"."title" LIKE '%Get%')
    ```
  }
}

And to make this a case-insensitive match one can use the ``QueryExpression/collate(_:)`` method:

@Row {
  @Column {
    ```swift
    Reminder
      .where {
        $0.title
          .collate(.nocase)
          .like("%get%")
      }
    // => [Reminder]
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."isCompleted",
      "reminders"."title",
      "reminders"."priority"
    FROM "reminders"
    WHERE (
      "reminders"."title"
        COLLATE NOCASE
        LIKE '%get%'
    )
    ```
  }
}

The library also supports all of the clauses of a standard SQL "SELECT" statement, including orders,
limits, offsets, and more. For example, we can chain onto the above query using the
``Table/order(by:)`` method:

@Row {
  @Column {
    ```swift
    Reminder
      .select { $0.title }
      .where {
        $0.title
          .collate(.nocase)
          .like("%get%")
      }
      .order {
        ($0.isCompleted.desc(),
         $0.priority.desc(),
         $0.title)
      }
    // => [String]
    ```
  }
  @Column {
    ```sql
    SELECT "reminders"."title"
    FROM "reminders"
    WHERE (
      "reminders"."title"
        COLLATE NOCASE
        LIKE '%get%'
    )
    ORDER BY
      "reminders"."isCompleted" DESC,
      "reminders"."priority" DESC,
      "reminders"."title"
    ```
  }
}

Notice that you can return any number of orders for the query as a tuple, and you can customize
which orders are in a descending versus ascending fashion.

And finally, suppose we wanted to further customize the above query by limiting the results to 10
rows and selecting the 2nd page of results. This can be done using the ``Table/limit(_:offset:)``
method:

@Row {
  @Column {
    ```swift
    Reminder
      .select { $0.title }
      .where {
        $0.title
          .collate(.nocase)
          .like("%get%")
      }
      .order {
        ($0.isCompleted.desc(),
         $0.priority.desc(),
         $0.title)
      }
      .limit(10, offset: 10)
    // => [String]
    ```
  }
  @Column {
    ```sql
    SELECT "reminders"."title"
    FROM "reminders"
    WHERE (
      "reminders"."title"
      COLLATE NOCASE
      LIKE '%get%'
    )
    ORDER BY
      "reminders"."isCompleted" DESC,
      "reminders"."priority" DESC,
      "reminders"."title"
    LIMIT 10 OFFSET 10
    ```
  }
}

This shows how to build a complex query in a matter of seconds, and you can be sure that you do not
make a silly mistake, such as refer to a non-existent column or perform an operation on a column
that does not have the correct type. And this is only scratching the surface of what the library is
capable of. See <doc:SelectStatements> for more examples of select statements, as well as
<doc:QueryCookbook> for more advanced topics in writing queries.

### Insert statements

The library provides the tools necessary to construct type-safe insert statements in SQL, including
inserting an entire value into a table, inserting only a subset of rows, as well as what to do on
conflicts. Using the `Reminder` data type from above, we can insert data for all of its rows using
the  ``Table/insert(_:values:onConflict:where:doUpdate:where:)`` method:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.title, $0.priority)
    } values: {
      ("Get groceries", 3)
      ("Take a walk", 1)
      ("Get haircut", nil)
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title", "priority")
    VALUES
      ('Get groceries', 3),
      ('Take a walk', 1),
      ('Get haircut', NULL)
    ```
  }
}

The first trailing closure of `insert` is handed the table definition of `Reminder` and you return a
tuple of the columns that you want to insert data for. Notice that we left off `$0.id` because that
column can be initialized by the database (using an auto-incrementing primary key or some other
mechanism). The second trailing closure is a list of values that you want to insert into the table,
and the number of columns and data type of each column must match what is specified in the first
trailing closure.

You can provide a 3rd trailing closure to
``Table/insert(_:values:onConflict:where:doUpdate:where:)`` to describe what to do in case there
is a conflict while inserting data. For example, suppose we had a unique index on the "title" column
of the reminders table. Then when inserting a value with a repeated title we could resolve the
conflict by appending the string `" (Copy)"` to the title:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.title, $0.priority)
    } values: {
      ("Get groceries", 3)
      ("Take a walk", 1)
      ("Get haircut", nil)
    } onConflict: {
      $0.title += " (Copy)"
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title", "priority")
    VALUES
      ('Get groceries', 3),
      ('Take a walk', 1),
      ('Get haircut', NULL)
    ON CONFLICT DO UPDATE SET
      "title" = (
        "reminders"."title"
          || ' (Copy)'
      )
    ```
  }
}

The `onConflict` trailing closure is handed a definition of the reminders table, but in this closure
you are allowed to make a certain set of simple mutations to it that will be translated to the
equivalent SQL code. In this case the `+=` operator on Swift strings is translated to the `||`
operator in SQL for concatenating text.

The library also supports the `RETURNING` clause of insert statements by using the
``Insert/returning(_:)`` method. If you wanted to fetch the ID of each new reminder inserted, you
can do the following:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.title, $0.priority)
    } values: {
      ("Get groceries", 3)
      ("Take a walk", 1)
      ("Get haircut", nil)
    }
    .returning(\.id)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title", "priority")
    VALUES
      ('Get groceries', 3),
      ('Take a walk', 1),
      ('Get haircut', NULL)
    RETURNING "id"
    ```
  }
}

Or if you want to fetch all columns of the rows just inserted you can do the following:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      ($0.title, $0.priority)
    } values: {
      ("Get groceries", 3)
      ("Take a walk", 1)
      ("Get haircut", nil)
    }
    .returning(\.self)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title", "priority")
    VALUES
      ('Get groceries', 3),
      ('Take a walk', 1),
      ('Get haircut', NULL)
    RETURNING
      "id",
      "isCompleted",
      "title",
      "priority"
    ```
  }
}

This shows how one can build complex insert statements in a type-safe manner. And this is only
scratching the surface of what the library is capable of. See <doc:InsertStatements> for more
examples of insert statements, as well as <doc:QueryCookbook> for more advanced topics in writing
queries.

### Update statements

The library provides tools for constructing type-safe update statements in SQL, including updating
all rows in a table, a filtered set of rows, or rows with specific primary keys.
``Table/update(set:)`` returns an update statement given a closure that describes the changes you
want to make to the table by mutating an `inout` representation of the table's columns. You can
assign new values or even call a selection of mutating methods and in-place operators.

@Row {
  @Column {
    ```swift
    Reminder.update {
      $0.title = "Get more groceries"
      $0.isCompleted.toggle()
      $0.notes += """

        * Milk
        * Eggs
        """
    }
    ```
  }
  @Column {
    ```sql
    UPDATE "reminders" SET
      "title" = 'Get more groceries',
      "isCompleted = (
        NOT "reminders"."isCompleted"
      ),
      "notes" = (
        "reminders"."notes"
          || '\n* Milk\n* Eggs'
      )
    ```
  }
}

The above query will set every single reminder in the table to "Get more groceries", which is
probably not what you want. To filter updates to a particular row, you can use ``Update/where(_:)``:

@Row {
  @Column {
    ```swift
    Reminder
      .update {
        $0.title = "Get more groceries"
        $0.isCompleted.toggle()
        $0.notes += """

          * Milk
          * Eggs
          """
      }
      .where {
        $0.id == 42
      }
    ```
  }
  @Column {
    ```sql
    UPDATE "reminders" SET
      "title" = 'Get more groceries',
      "isCompleted = (
        NOT "reminders"."isCompleted"
      ),
      "notes" = (
        "reminders"."notes"
          || '\n* Milk\n* Eggs'
      )
    WHERE "reminders"."id" = 42
    ```
  }
}

Notice that certain simple Swift operations are translated into their SQL equivalent. For example,
the `+=` operator on strings turns `notes = notes || '…'`, and the `toggle()` method is
translated to `isCompleted = NOT isCompleted`.

You can also chain from a filtered ``Where`` clause into an update:

```swift
Reminder
  .where { $0.id == 42 }
  .update { $0.title = "Get more groceries }
```

Update statements, like inserts, have a `RETURNING` clause, which you can use to specify data to
fetch from rows updated by the query. Simply use the ``Update/returning(_:)`` method:

@Row {
  @Column {
    ```swift
    Reminder
      .where { $0.id == 42 }
      .update { $0.isCompleted.toggle() }
      .returning(\.isCompleted)
    // => Bool
    ```
  }
  @Column {
    ```sql
    UPDATE "reminders" SET
      "title" = 'Get more groceries',
      "isCompleted" = (
        NOT "reminders"."isCompleted"
      )
    WHERE "reminders"."id" = 42
    RETURNING "isCompleted"
    ```
  }
}

See <doc:UpdateStatements> for more examples of update statements, as well as <doc:QueryCookbook>
for more advanced topics in writing queries.

### Delete statements

The library provides tools for constructing type-safe delete statements, as well. Use
``Table/delete()`` to create a delete statement:

@Row {
  @Column {
    ```swift
    Reminder.delete()
    ```
  }
  @Column {
    ```sql
    DELETE FROM "reminders"
    ```
  }
}

**Be careful!** This will delete _every_ row in the table if executed, which is rarely what you want.
Instead, delete rows with a filter using ``Delete/where(_:)``:

@Row {
  @Column {
    ```swift
    Reminder
      .delete()
      .where { $0.id == 42 }
    ```
  }
  @Column {
    ```sql
    DELETE FROM "reminders"
    WHERE "reminders"."id" = 42
    ```
  }
}

You can also chain from a filtered ``Where`` clause into a delete:

```swift
Reminder
  .where { $0.id == 42 }
  .delete()
```

Delete statements, like inserts and updates, have a `RETURNING` clause, which you can use to specify
data to fetch from rows deleted by the query. Simply use the ``Update/returning(_:)`` method:

@Row {
  @Column {
    ```swift
    Reminder
      .where { $0.id == 42 }
      .delete()
      .returning(\.self)
    // => Reminder
    ```
  }
  @Column {
    ```sql
    DELETE FROM "reminders"
    WHERE "reminders"."id" = 42
    RETURNING
      "id",
      "isCompleted",
      "title",
      "priority"
    ```
  }
}

See <doc:DeleteStatements> for more examples of delete statements, as well as <doc:QueryCookbook>
for more advanced topics in writing queries.

### Safe SQL strings

The library comes with a `#sql` macro that allows you to write SQL strings directly, but in a safe
manner. This can be useful for writing complex queries that may not be possible or easy to write
with the query builder of this library.

> Important: Although `#sql` gives you the ability to write hand-crafted SQL strings, it still
> protects you from SQL injection, and you can still make use of the table definition data available
> from your data type.

As a simple example, one can select the titles from all reminders like so:

```swift
#sql("SELECT title FROM reminders", as: String.self)
```

It is important to note that if the underlying ``QueryExpression/QueryValue`` for the expression
cannot be inferred from context you must provide it explicitly using the `as` argument. If you were
to select multiple fields you would need to specify a tuple of types:

```swift
#sql("SELECT title, isCompleted FROM reminders", as: (String, Bool).self)
```

It is also possible to retain some schema-safety while writing SQL as a string. You can use string
interpolation along with the static column properties that are defined on your table as well as the
type of the table itself:

```swift
#sql(
  """
  SELECT \(Reminder.title), \(Reminder.isCompleted)
  FROM \(Reminder.self)
  """,
  as: (String, Bool).self
)
```

This generates the same query as before, but now you have more static safety in referring to the
column names and table names of your types.

You can even select all columns from the reminders table by using the ``Table/columns`` static
property:

@Row {
  @Column {
    ```swift
    #sql(
      """
      SELECT \(Reminder.columns)
      FROM \(Reminder.self)
      """,
      as: Reminder.self
    )
    // => [Reminder]
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."title",
      "reminders"."isCompleted",
      "reminders"."priority"
    FROM "reminders"
    ```
  }
}

Notice that this allows you to now decode the result into the full `Reminder` type instead of a
tuple of values.

Even though it seems that `#sql` allows you to construct any kind of SQL statement from a string,
there are still protections in place to make sure you do not accidentally allow for SQL injection.
If you interpolate a value into `#sql` it will treat it as a binding rather than inserting its
contents directly into the query:

@Row {
  @Column {
    ```swift
    let minimumPriority = 2

    #sql(
      """
      SELECT \(Reminder.columns)
      FROM \(Reminder.self)
      WHERE
        \(Reminder.priority)
          >= \(minimumPriority)
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
      "reminders"."isCompleted",
      "reminders"."priority"
    FROM "reminders"
    WHERE
      "reminders"."priority"
        >= ?
    [2]
    ```
  }
}

It is also possible to select a subset of columns from your table and decode the row data into a
custom data type. To do so you need to conform your custom data type to the ``QueryRepresentable``
protocol, which requires implementing ``QueryRepresentable/init(queryOutput:)``, but once that is
done you can provide the type to the `as` argument:

```swift
struct ReminderResult: QueryRepresentable {
  let title: String
  let isCompleted: Bool
  init(decoder: inout some QueryDecoder) throws { /* ... */ }
}
#sql(
  """
  SELECT \(Reminder.title), \(Reminder.isCompleted)
  FROM \(Reminder.self)
  """,
  as: ReminderResult.self
)
```

There is also a way to streamline providing the ``QueryRepresentable`` conformance. You can use
`@Selection` to describe the datatype you want to decode:

```swift
@Selection
struct ReminderResult {
  let title: String
  let isCompleted: Bool
}
#sql(
  """
  SELECT \(Reminder.title), \(Reminder.isCompleted)
  FROM \(Reminder.self)
  """,
  as: ReminderResult.self
)
```

See <doc:SafeSQLStrings> for more information about the `#sql` macro.
