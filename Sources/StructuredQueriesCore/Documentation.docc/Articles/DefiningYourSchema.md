# Defining your schema

Learn how to replicate your database's schema in first class Swift types
using the `@Table` and `@Column` macros.

## Overview

@Comment {
  Describe table/column macro, column arguments, bind strategies, primary key tables, etc...
}

The library provides tools to model Swift data types that replicate your database's schema so that
you can use the static description of its properties to build type-safe queries. Typically the
schema of your app is defined first and foremost in your database, and then you define Swift types
that represent those database definitions.

### Defining a table

Suppose your database has a table defined with the following create statement:

```sql
CREATE TABLE "reminders" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT",
  "title" TEXT NOT NULL DEFAULT '',
  "isCompleted" INTEGER DEFAULT 0
)
```

To define a Swift data type that represents this table, one can use the `@Table` macro:

```swift
@Table struct Reminder {
  let id: Int
  var title = ""
  var isCompleted = false
}
```

Note that the struct's field names match the column tables of the table exactly. In order to support
property names that differ from the columns names, you can use the `@Column` macro. See the section
below, <doc:DefiningYourSchema#Customizing-a-table>,  for more information on how to customize your
data type.

With this table defined you immediately get access to the suite of tools the library provides to
build queries:

@Row {
  @Column {
    ```swift
    Reminder
      .where { !$0.isCompleted }
    ```
  }
  @Column {
    ```sql
    SELECT
      "reminders"."id",
      "reminders"."title",
      "reminders"."isCompleted"
    FROM "reminders"
    WHERE (NOT "reminders"."isCompleted")
    ```
  }
}

### Customizing a table

Oftentimes we want our Swift data types to use a different naming convention than the tables and
columns in our database. It is common for tables and columns to use "snake case" naming, whereas
Swift is almost always written in "camel case." The library provides tools for you to define your
Swift data types exactly as you want, while still being adaptable to the schema of your database.

#### Table names

By default the `@Table` macro assumes that the name of your database table is the lowercased,
pluralized version of your data type's name. In order to lowercase and pluralize the type name the
library has some light inflection logic to come up with mostly reasonable results:

```swift
@Table struct Reminder {}
@Table struct Category {}
@Table struct Status {}
@Table struct RemindersList {}

Reminder.tableName       // "reminders"
Category.tableName       // "categories"
Status.tableName         // "statuses"
RemindersList.tableName  // "remindersLists"
```

However, many people prefer for their table names to be the _singular_ form of the noun, or they
prefer to use snake case instead of camel case. In such cases you can provide the `@Table` with a
string for the name of the table in the database:

```swift
@Table("reminder") struct Reminder {}
@Table("category") struct Category {}
@Table("status") struct Status {}
@Table("reminders_list") struct RemindersList {}

Reminder.tableName       // "reminder"
Category.tableName       // "category"
Status.tableName         // "status"
RemindersList.tableName  // "reminders_list"
```

#### Column names

Properties of Swift types often differ in formatting from the columns they represent in the
database. Most often this is a different of snake case versus camelcase. In such situations you can
use the `@Column` macro to describe the name of the column as it exists in the database in order
to have your Swift data type represent the most pristine version of itself:

```swift
@Table struct Reminder {
  let id: Int
  var title = ""
  @Column("is_completed")
  var isCompleted = false
}
```

@Row {
  @Column {
    ```swift
    Reminder
      .where { !$0.isCompleted }
    ```
  }
  @Column {
    ```sql
    SELECT
    "reminders"."id",
    "reminders"."title",
    "reminders"."is_completed"
    WHERE (NOT "reminders"."is_completed")
    ```
  }
}

Here we get to continue using camel case `isCompleted` in Swift, as is customary, but the SQL
generated when writing queries will correctly use `"is_completed"`.

### Custom data types

There are many data types that do not have native support in SQLite. For these data types you must
define a conformance to ``QueryBindable`` in order to translate values to a format that SQLite does
understand. The library comes with conformances to aid in representing dates, UUIDs, and JSON, and
you can define your own conformances for your own custom data types.

#### Dates

SQLite does not have a native date type, and instead has 3 different ways to represent dates:

  * Text column interpreted as ISO-8601-formatted string.
  * Int column interpreted as number of seconds since Unix epoch.
  * Double column interpreted as a Julian day (number of days since November 24, 4713 BC).

Because of this ambiguity, the `@Table` macro does not know what you intend when you define a data
type like this:

```swift
@Table struct Reminder {
  let id: Int
  var date: Date  // 🛑 'Date' column requires a query representation
}
```

In order to make it explicit how you expect to turn a `Date` into a type that SQLite understands
(_i.e._ text, integer, or double) you can use the `@Column` macro with the `as:` argument. The
library comes with 3 strategies out the box to help, ``Foundation/Date/ISO8601Representation`` for
storing the date as a string, ``Foundation/Date/UnixTimeRepresentation`` for storing the date as an
integer, and ``Foundation/Date/JulianDayRepresentation`` for storing the date as a floating point
number.

Any of these representations can be used like so:

```swift
@Table struct Reminder {
  let id: Int
  @Column(as: Date.ISO8601Representation.self)
  var date: Date
}
```

And StructuredQueries will take care of formatting the value for the database:

@Row {
  @Column {
    ```swift
    Reminder.insert(
      Reminder.Draft(date: Date())
    )
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("date")
    VALUES
      ('2018-01-29 00:08:00.000')
    ```
  }
}

#### UUID

SQLite also does not have native support for UUIDs. If you try to use a UUID in your tables you
will get an error:

```swift
@Table struct Reminder {
  let id: UUID  // 🛑 'UUID' column requires a query representation
  var title = ""
}
```

To use such identifiers in your table you can store the column as a data blob, and then you can
use the ``Foundation/UUID/BytesRepresentation`` column representation:

```swift
@Table struct Reminder {
  @Column(as: UUID.BytesRepresentation.self)
  let id: UUID
  var title = ""
}
```

Alternatively you can store the column as text and use either
``Foundation/UUID/LowercasedRepresentation`` or ``Foundation/UUID/UppercasedRepresentation`` to
translate the UUID to text:

```swift
@Table struct Reminder {
  @Column(as: UUID.LowercasedRepresentation.self)
  let id: UUID
  var title = ""
}
```

#### RawRepresentable

Simple data types, in particular ones conforming to `RawRepresentable` whose `RawValue` is a string
or integer, can be held in tables by conforming to the ``QueryBindable`` protocol. For example,
a priority enum can be held in the `Reminder` table like so:

```swift
@Table
struct Reminder {
  let id: Int
  var title = ""
  var priority: Priority?
}
enum Priority: Int, QueryBindable {
  case low, medium, high
}
```

The library will automatically encode the priority to an integer when insert into the database,
and will decode data from the database using the `RawRepresentable` conformance of `Priority`.

@Row {
  @Column {
    ```swift
    Reminder.insert(
      Reminder.Draft(
        title: "Get haircut",
        priority: .medium
      )
    )
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("date", "priority")
    VALUES
      ('Get haircut', 2)
    ```
  }
}

#### JSON

To store complex data types in a column of a SQLite table you can serialize values to JSON. For
example, suppose the `Reminder` table had an array of notes:

```swift
@Table struct Reminder {
  let id: Int
  var title = ""
  var notes: [String]  // 🛑
}
```

This does not work because the `@Table` macro does not know how to encode and decode an array
of strings into a value that SQLite understands. If you annotate this field with
``JSONRepresentation``, then the library can encode the array of strings to a JSON string when
storing data in the table, and decode the JSON array into a Swift array when decoding a row:

```swift
@Table struct Reminder {
  let id: Int
  var title = ""
  @Column(as: JSONRepresentation<[String]>.self)
  var notes: [String]
}
```

With that you can insert reminders with notes like so:

@Row {
  @Column {
    ```swift
    Reminder.insert(
      Reminder.Draft(
        title: "Get groceries",
        notes: ["Milk", "Eggs", "Bananas"]
      )
    )
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title", "notes")
    VALUES
      ('Get groceries',
       '["Milk","Eggs","Bananas"]')
    ```
  }
}

### Primary keyed tables

It is possible to tell let the `@Table` macro know which property of your data type is the primary
key for the table in the database, and doing so unlocks new APIs for inserting, updating, and
deleting records. By default the `@Table` macro will assume any property named `id` is the
primary key, or you can explicitly specify it with the `primaryKey:` argument of the `@Column`
macro:

```swift
struct Book {
  @Column(primaryKey: true)
  let isbn: String
  var title = ""
}
```

If the table has no primary key, but has an `id` column, one can explicitly opt out of the
macro's primary key functionality by specifying `primaryKey: false`:

```swift
@Column(primaryKey: false)
var id: String
```

See <doc:PrimaryKeyedTable> for more information on tables with primary keys.

### Ephemeral columns

It is possible to store properties in a Swift data type that has no corresponding column in your SQL
database. Such properties must have a default value, and can be specified using the `@Ephemeral`
macro:

```swift
struct Book {
  @Column(primaryKey: true)
  let isbn: String
  var title: String
  @Ephemeral
  var scratchNotes = ""
}
```

## Topics

### Schema

- ``Table``
- ``PrimaryKeyedTable``

### Bindings

- ``QueryBindable``
- ``QueryBinding``
- ``QueryBindingError``

### Decoding

- ``QueryRepresentable``
- ``QueryDecodable``
- ``QueryDecoder``
- ``QueryDecodingError``
