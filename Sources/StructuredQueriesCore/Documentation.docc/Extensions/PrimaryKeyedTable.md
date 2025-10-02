# ``StructuredQueriesCore/PrimaryKeyedTable``

A primary-keyed table is one that has a column whose value is unique for the entire table. The most
common example is an "id" column that holds an integer, UUID, or some other kind of identifier.
Typically such columns are also initialized by the database so that when inserting rows into the
table you do not need to specify the primary key. The library provides extra tools that make it
easier to insert, update, and delete records that have a primary key.

> Note: Don't conform to this protocol directly. Instead, use the `@Table` and `@Column` macros to
> generate a conformance.

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
> primary key in its table definition.

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

To define a composite primary key, group them together into a `@Selection` type and annotate the
field with the `@Columns` macro:

```swift
@Table
struct Enrollment {
  @Selection
  struct ID {
    var courseID: CourseID
    var studentID: StudentID
  }

  // Automatically inferred as '@Columns(primaryKey: True)
  let id: ID
  // ...
}
```

### Drafts

Once a primary key has been specified for a type, the `@Table` macro generates a special `Draft`
type nested inside your type. This type has all of the same fields as your type, except its primary
key field is made optional:

```swift
let draft = Reminder.Draft(title: "Get groceries")
```

The `id` is not necessary to provide because it is optional. This allows you to insert rows into
your database without specifying the id. The library comes with a special
``PrimaryKeyedTable/insert(_:onConflict:)`` method that allows you to insert a row into the database
by providing only a draft:

```swift
Reminder.insert {
  Reminder.Draft(title: "Get groceries")
}
// INSERT INTO "reminders"
//   ("title")
// VALUES
//   ('Get groceries')
```

Since the "id" column is not specified in this query it allows the database to initialize it for us.
This `Draft` type is appropriate to use in any features that needs to build up a value without
specifying an ID.

Further, using the ``Insert/returning(_:)`` method you can get back the ID of the newly inserted
row:

```swift
Reminder
  .insert { Reminder.Draft(title: "Get groceries") }
  .returning(\.id)
// INSERT INTO "reminders"
//   ("title")
// VALUES
//   ('Get groceries')
// RETURNING
//   "id"
```

Or even get back the entire newly inserted row:

```swift
Reminder
  .insert { Reminder.Draft(title: "Get groceries") }
  .returning(\.self)
// INSERT INTO "reminders"
//   ("title")
// VALUES
//   ('Get groceries')
// RETURNING
//   "id", "title", "isCompleted"
```

### Updates and deletions

Primary-keyed tables are also given special APIs for updating and deleting existing rows in the
table based on their primary key. For example, the ``PrimaryKeyedTable/update(_:)`` method
allows one to update all the fields of a row with the corresponding primary key:

```swift
let reminder = Reminder(id: 1, title: "Get groceries", isCompleted: false)
Reminder.update(reminder)
// UPDATE "reminders"
// SET "title" = 'Get groceries', "isCompleted" = 0
// WHERE "id" = 1
```

Similarly, the ``PrimaryKeyedTable/delete(_:)`` method allows one to delete a row by its primary
key:

```swift
let reminder = Reminder(id: 1, title: "Get groceries", isCompleted: false)
Reminder.delete(reminder)
// DELETE "reminders"
// WHERE "id" = 1
```

## Topics

### Primary keys

- ``PrimaryKey``
- ``primaryKey-swift.property``

### Drafts

- ``Draft``
- ``find(_:)``
- ``update(_:)``
- ``upsert(values:)``
- ``delete(_:)``

### Schema definition

- ``PrimaryKeyedTableDefinition``

### Deprecations

- ``insert(_:onConflict:)``
- ``upsert(_:)``
