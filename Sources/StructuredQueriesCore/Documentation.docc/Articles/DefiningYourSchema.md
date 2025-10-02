# Defining your schema

Learn how to replicate your database's schema in first class Swift types using the `@Table` and
`@Column` macros.

## Overview

@Comment {
  Describe table/column macro, column arguments, bind strategies, primary key tables, etc...
}

The library provides tools to model Swift data types that replicate your database's schema so that
you can use the static description of its properties to build type-safe queries. Typically the
schema of your app is defined first and foremost in your database, and then you define Swift types
that represent those database definitions.

* [Defining a table](#Defining-a-table)
* [Customizing a table](#Customizing-a-table)
  * [Table names](#Table-names)
  * [Column names](#Column-names)
  * [Custom data types](#Custom-data-types)
    * [RawRepresentable](#RawRepresentable)
    * [JSON](#JSON)
    * [Tagged identifiers](#Tagged-identifiers)
* [Primary-keyed tables](#Primary-keyed-tables)
* [Grouped columns](#Grouped-columns)
* [Ephemeral columns](#Ephemeral-columns)
* [Generated columns](#Generated-columns)
* [Enum tables](#Enum-tables)
* [Table definition tools](#Table-definition-tools)

### Defining a table

Suppose your database has a table defined with the following create statement:

```sql
CREATE TABLE "reminders" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
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
database. Most often this is a difference of snake case versus camelcase. In such situations you can
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

StructuredQueries provides support for many basic Swift data types out of the box, like strings,
integers, doubles, bytes, and booleans, but you may want to represent custom, domain specific types
with your table's columns, instead. For these data types you must either define a conformance to
``QueryBindable`` to translate values to a format that the library does understand, or provide a
``QueryRepresentable`` type that wraps your domain type.

The library comes with several `QueryRepresentable` conformances to aid in representing dates,
UUIDs, and JSON, and you can define your own conformances for your own custom data types.

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

The library will automatically encode the priority to an integer when inserting into the database,
and will decode data from the database using the `RawRepresentable` conformance of `Priority`.

@Row {
  @Column {
    ```swift
    Reminder.insert {
      Reminder.Draft(
        title: "Get haircut",
        priority: .medium
      )
    }
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
``Swift/Decodable/JSONRepresentation``, then the library can encode the array of strings to a JSON
string when storing data in the table, and decode the JSON array into a Swift array when decoding a
row:

```swift
@Table struct Reminder {
  let id: Int
  var title = ""
  @Column(as: [String].JSONRepresentation.self)
  var notes: [String]
}
```

With that you can insert reminders with notes like so:

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
       '["Milk","Eggs","Bananas"]')
    ```
  }
}

#### Tagged identifiers

The [Tagged](https://github.com/pointfreeco/swift-tagged) library provides lightweight syntax for
introducing type-safe identifiers (and more) to your models. StructuredQueries ships support for
Tagged with a `StructuredQueriesTagged` package trait, which is available starting from Swift 6.1.

To enable the trait, specify it in the Package.swift file that depends on StructuredQueries:

```diff
 .package(
   url: "https://github.com/pointfreeco/swift-structured-queries",
   from: "0.22.0",
+  traits: ["StructuredQueriesTagged"]
 ),
```

This will allow you to introduce distinct `Tagged` identifiers throughout your schema:

```diff
 @Table
 struct RemindersList: Identifiable {
-  let id: Int
+  typealias ID = Tagged<Self, Int>
+  let id: ID
   // ...
 }
 @Table
 struct Reminder: Identifiable {
-  let id: Int
+  typealias ID = Tagged<Self, Int>
+  let id: ID
   // ...
   var remindersList: Reminder.ID
 }
```

This adds a new layer of type-safety when constructing queries. Previously comparing a
`RemindersList.ID` to a `Reminder.ID` would compile just fine, even though it is a nonsensical thing
to do. But now, such a comparison is a compile time error:

```swift
RemindersList.leftJoin(Reminder.all) {
  $0.id == $1.id  // 🛑 Requires the types 'Reminder.ID' and 'RemindersList.ID' be equivalent
}
```

Tagged works with any query-representable value. For example, if you want a Tagged UUID to use the
`UUID.BytesRepresentation` from StructuredQueriesSQLite:

```swift
@Table
struct RemindersList: Identifiable {
  typealias ID = Tagged<Self, UUID>

  @Column(as: Tagged<Self, UUID.BytesRepresentation>.self)
  let id: ID
  // ...
}
```

### Primary-keyed tables

It is possible to let the `@Table` macro know which field of your data type is the primary
key for the table in the database, and doing so unlocks new APIs for inserting, updating, and
deleting records. By default the `@Table` macro will assume any property named `id` is the
primary key, or you can explicitly specify it with the `primaryKey:` argument of the `@Column`
macro:

```swift
@Table
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

### Grouped columns

It is possible to group many related columns into a single data type, which helps with organization
and reusing little bits of schema amongst many tables. For example, suppose many tables in your
database schema have `createdAt: Date` and `updatedAt: Date?` timestamps. You can choose to group
those columns into a dedicate data type, annotated with the `@Selection` macro:

```swift
@Selection
struct Timestamps {
  let createdAt: Date
  let updatedAt: Date?
}
```

And then you can use `Timestamps` in tables as if it was just a single column:

```swift
@Table
struct RemindersList {
  let id: Int
  var name = ""
  let timestamps: Timestamps
}

@Table
struct Reminder {
  let id: Int
  var name = ""
  var isCompleted = false
  let timestamps: Timestamps
}
```

> Important: Since SQLite has no concept of grouped columns you must remember to flatten all
> groupings into a single list when defining your table's schema. For example, the "CREATE TABLE"
> statement for the `RemindersList` above would look like this:
>
> ```sql
> CREATE TABLE "remindersLists" (
>   "id" INTEGER PRIMARY KEY,
>   "name" TEXT NOT NULL,
>   "isCompleted" INTEGER NOT NULL,
>   "createdAt" TEXT NOT NULL,
>   "updatedAt" TEXT
> ) STRICT
> ```

You can construct queries that access fields inside column groups using regular dot-syntax:

@Row {
  @Column {
    ```swift
    RemindersList
      .where { $0.timestamps.createdAt <= date }
    ```
  }
  @Column {
    ```sql
    SELECT "id", "title", "createdAt", "updatedAt"
    FROM "remindersLists"
    WHERE "createdAt" <= ?
    ```
  }
}

You can even compare the `timestamps` field directly and its columns will be flattened into a
tuple in SQL:

@Row {
  @Column {
    ```swift
    RemindersList
      .where {
        $0.timestamps <= Timestamps(createdAt: date1, updatedAt: date2)
      }
    ```
  }
  @Column {
    ```sql
    SELECT "id", "title", "createdAt", "updatedAt"
    FROM "remindersLists"
    WHERE ("createdAt", "updatedAt") <= (?, ?)
    ```
  }
}

That allows you to query against all columns of a grouping at once.

### Ephemeral columns

It is possible to store properties in a Swift data type that has no corresponding column in your SQL
database. Such properties must have a default value, and can be specified using the `@Ephemeral`
macro:

```swift
@Table
struct Book {
  @Column(primaryKey: true)
  let isbn: String
  var title: String
  @Ephemeral
  var scratchNotes = ""
}
```

### Generated columns

Some databases, including SQLite, support [generated columns](https://www.sqlite.org/gencol.html),
which are columns whose values are computed from other columns in the same row. Since these columns
are read-only from an application's perspective, they should be included in `SELECT` statements but
excluded from `INSERT` or `UPDATE` statements.

You can mark a property as a generated column by using the `generated` parameter of the `@Column`
macro with a value of `.stored` or `.virtual`. This ensures the property is decoded when
fetching data but is not included in the `Draft` type used for creating or updating records.

For example, if your database computes a stored `endAt` timestamp, you can model it like this:

```swift
@Table
struct Event {
  let id: UUID
  var startAt: Date
  var duration: TimeInterval

  @Column(generated: .stored)
  var endAt: Date
}
```

### Enum tables

It is possible to use enums as a domain modeling tool for your table schema, which can help you
emulate "inheritance" for your tables without having the burden of using reference types.

As an example, suppose you have a table that represents attachments that can be associated with
other tables, and an attachment can either be a link, a note or an image. One way to model this
is a struct to represent the attachment that holds onto an enum for the different kinds of
attachments supported, annotated with the `@Selection` macro:

```swift
@Table struct Attachment {
  let id: Int
  let kind: Kind

  @CasePathable @Selection
  enum Kind {
    case link(URL)
    case note(String)
    case image(URL)
  }
}
```

> Important: It is required to apply the `@CasePathable` macro in order to define columns from an
> enum. This macro comes from our [Case Paths] library and is automatically included with the
> library when the `StructuredQueriesCasePaths` trait is enabled.

[Case Paths]: http://github.com/pointfreeco/swift-case-paths

To create a SQL table that represents this data type you simply flatten all of the fields into
a single list of columns where each column is nullable:

```sql
CREATE TABLE "attachments" (
  "id" INTEGER PRIMARY KEY,
  "link" TEXT,
  "note" TEXT,
  "image" TEXT
) STRICT
```

With that defined you can query the table much like a regular table. For example, a simple
`Attachment.all` selects all columns, and when decoding the data from the database it will
be decided which case of the `Kind` enum is chosen:

@Row {
  @Column {
    ```swift
    Attachment.all
    ```
  }
  @Column {
    ```sql
    SELECT
      "attachments"."id",
      "attachments"."link",
      "attachments"."note",
      "attachments"."image"
    FROM "attachments"
    ```
  }
}

You can also use `where` clauses to filter attachments by their kind, such as selecting images
only:

@Row {
  @Column {
    ```swift
    Attachment.where { $0.kind.image.isNot(nil) }
    ```
  }
  @Column {
    ```sql
    SELECT
      "attachments"."id",
      "attachments"."link",
      "attachments"."note",
      "attachments"."image"
    FROM "attachments"
    WHERE "attachments"."image" IS NOT NULL
    ```
  }
}

You can insert attachments into the database in the usual way:

@Row {
  @Column {
    ```swift
    Attachment.insert {
      Attachment.Draft(kind: .note("Hello world!"))
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "attachments"
    ("id", "link", "note", "image")
    VALUES
    (NULL, NULL, 'Hello world!', NULL)
    ```
  }
}

Notice that `NULL` is inserted for `link` and `image` since we are inserting an attachment
with the `note` case.

And further, you can update attachments in the database in the usual way:

@Row {
  @Column {
    ```swift
    Attachment.update {
      $0.kind = .note("Goodbye world!")
    }
    ```
  }
  @Column {
    ```sql
    UPDATE "attachments"
    SET
      "link" = NULL,
      "note" = 'Goodbye world!',
      "image" = NULL
    ```
  }
}

Note that `link` and `image` are explicitly set to `NULL` since we are setting the kind of
the attachment to `note`.

It is also possible to group many columns together for a case of an enum. For example, suppose
the image not only had a URL but also had a caption. Then a dedicated `@Selection` type
can be defined for that data and used in the `image` case:

```swift
@Table struct Attachment {
  let id: Int
  let kind: Kind

  @CasePathable @Selection
  enum Kind {
    case link(URL)
    case note(String)
    case image(Attachment.Image)
  }
  @Selection
  struct Image {
    var caption = ""
    var url: URL
  }
}
```

> Note: Due to how macros expand it is necessary to fully qualify nested types, e.g.
> `case image(Attachment.Image)`.

To create a SQL table that represents this data type you again must flatten all columns into a
single list of nullable columns:

```sql
CREATE TABLE "attachments" (
  "id" INTEGER PRIMARY KEY,
  "link" TEXT,
  "note" TEXT,
  "caption" TEXT,
  "url" TEXT
) STRICT
```
These tools allow you to emulate what is known as "single table inheritance", where you model
a class inheritance heirarchy of models as a single wide table that has columns for each
model. This allows you to share bits of data and logic amongst many models in a way that still
plays nicely with SQLite.

SwiftData supports this kind of data modeling, but they force you to use reference
types instead of value types, you lose exhaustivity for the types of models supported, and
it's a lot more verbose:

```swift
@available(iOS 26, *)
@Model class Attachment {
  var isActive: Bool
  init(isActive: Bool = false) { self.isActive = isActive }
}

@available(iOS 26, *)
@Model class Link: Attachment {
  var url: URL
  init(url: URL, isActive: Bool = false) {
    self.url = url
    super.init(isActive: isActive)
  }
}

@available(iOS 26, *)
@Model class Note: Attachment {
  var note: String
  init(note: String, isActive: Bool = false) {
    self.note = note
    super.init(isActive: isActive)
  }
}

@available(iOS 26, *)
@Model class Image: Attachment {
  var url: URL
  init(url: URL, isActive: Bool = false) {
    self.url = url
    super.init(isActive: isActive)
  }
}
```

> Note: The `@available(iOS 26, *)` attributes are required even if targeting iOS 26+, and
> the explicit initializers are required and must accept all arguments from all parent
> classes and pass that to `super.init`.

Enums provide an alternative to this approach that embraces value types, is more concise, and
more powerful.

### Table definition tools

This library does not come with any tools for actually constructing table definition queries,
such as `CREATE TABLE`, `ALTER TABLE`, and so on. That is, there are no APIs for performing the
following kinds of queries:

@Row {
  @Column {
    ```swift
    Reminder.createTable()
    // ⚠️ Theoretical API that does
    //    not actually exist.
    ```
  }
  @Column {
    ```sql
    CREATE TABLE "reminders" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "title" TEXT NOT NULL,
      "isCompleted" INTEGER NOT NULL DEFAULT 0
    )
    ```
  }
}

In fact, we recommend all changes to the schema of your database be executed as SQL strings using
the [`#sql` macro](<doc:SafeSQLStrings>):

```swift
#sql(
  """
  CREATE TABLE "reminders" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "title" TEXT NOT NULL,
    "isCompleted" INTEGER NOT NULL DEFAULT 0
  )
  """
)
```

It may seem strange for us to recommend using SQL strings when the library provides such an
expansive assortment of tools that make SQL more expressive, type-safe, and schema-safe. But there
is a very good reason for this.

Through the lifetime of an application you will perform many migrations on your schema. You will
add/remove tables, add/remove columns, add/remove indices, add/remove constraints, and more.
Each of these alterations to the schema make a snapshot of your entire database's schema that
is frozen in that moment of time. Once a migration has been shipped and run on a user's device
it should never be edited again. Therefore it is not appropriate to use the statically known
symbols exposed by `@Table` to alter your database.

As a concrete example, suppose we _did_ have table definition tools. This would mean creating a
table could be as simple as this:

```swift
@Table struct Reminder {
  let id: Int
  var name = ""
}

migrator.migrate("Create 'reminders' table") { db in
  // ⚠️ Theoretical 'createTable' API. Does not actually exist.
  try Reminder.createTable().execute(db)
}
```

When your app is launched for the first time it will run this migration and make a record of it
being run so that it is not ever run again.

But then a few days later you decide that you prefer `title` to `name` for the `Reminder` type,
and so you hope that you can just rename the project, fix any compilation errors, and add a new
migration:

```diff
 @Table struct Reminder {
   let id: Int
-  var name = ""
+  var title = ""
 }

 migrator.migrate("Create 'reminders' table") { db in
   // ⚠️ Theoretical 'createTable' API. Does not actually exist.
   try Reminder.createTable().execute(db)
 }
+migrator.migrate("Rename 'name' to 'title'") { db in
+  // ⚠️ Theoretical 'rename(from:)' API. Does not actually exist.
+  try Reminder.title.rename(from: "name").execute(db)
+}
```

Now when the app launches it rename the column in the database, and make a record that the migration
has been run so that it is not ever run again.

This will work just fine for all users that have previously run the first migration. But any new
users that run the whole suite of migrations at once will have the following SQL statements
executed:

```sql
CREATE TABLE "reminders" (
  "id" INTEGER,
  "title" TEXT
);
ALTER TABLE "reminders" RENAME COLUMN "name" TO "title";
```

The second SQL statement fails because there is no "name" column. And the reason this is happening
is because `Reminder.createTable()` must use the most current version of the schema where the field
is "title", not "name." This violates the principle that migrations should be snapshots of your
database's schema frozen in time and should never be edited after shipping to your users. A side
effect of violating this principle is that we now generate invalid SQL and run the risk of breaking
our users' app.

If it worries you to write SQL strings by hand, then fear not! For a few reasons:

  * Although this library aims to provide type-safe and schema-safe tools for writing SQL, it is
    not a goal to make it so that you _never_ write SQL strings. SQL is an amazing language that has
    stood the test of time, and you will be a better engineer for being able to write it from
    scratch. And sometimes, such as the case with table definitions, it is necessary to write SQL
    strings.

  * It may seem dangerous to write SQL strings. After all, aren't they susceptible to SQL injection
    attacks and typos? The `#sql` macro protects you against any SQL injection attacks, and provides
    some basic linting to make sure your SQL is roughly correct. And typos are not common in table
    definition statements since an unexpected database schema is a very visible bug in your
    application, as opposed to a small part of a `SELECT` statement that is only run every once in
    awhile in your app.

So, we hope that you will consider it a _benefit_ that your application's schema will be defined and
maintained as simple SQL strings. It's a simple format that everyone familiar with SQLite will
understand, and it makes your application most resilient to the ever growing changes and demands on
your application.

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
