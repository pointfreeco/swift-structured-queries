# Table drafts

Learn how to stage new records for insertion without specifying database-initialized columns using
a table's `Draft` type.

## Overview

Tables often have columns whose values are best initialized by the database rather than your Swift
code. The most common example is a primary key, which is typically assigned by the database when a
row is inserted, but other examples include created/updated timestamps and foreign keys. For such
tables, the `@Table` macro can generate a special `Draft` type that allows you to omit these columns
when building up a new record to insert.

A `Draft` type is generated for every table that specifies a primary key (see
<doc:PrimaryKeyedTables>), as well as any table that has at least one lazy-initializable column
(see <doc:TableDrafts#Lazy-initialization>, below).

### Drafts for primary-keyed tables

Once a primary key has been specified for a type, the `@Table` macro generates a special `Draft`
type nested inside. This type has all of the same fields as your type, except its primary key field
is made optional and can be omitted from initialization:

```swift
let draft = Reminder.Draft(title: "Get groceries")
```

> Note: While the draft type is generated with all of the same fields as your type, it is _not_
> generated with all the same conformances. If your `@Table` type conforms to `Equatable`,
> `Hashable`, `Codable`, `Sendable`, or any other protocol that you wish for the `Draft` type to
> conform to, you must specify this conformance manually _via_ extension. For example:
>
> ```swift
> extension Reminder.Draft: Equatable {}
> ```

The `id` is not necessary to provide because it is optional. This allows you to insert rows into
your database without specifying the ID. Drafts can be provided to the
``Table/insert(_:values:onConflict:where:doUpdate:where:)`` method to insert a row into the
database:

@Row {
  @Column {
    ```swift
    Reminder.insert {
      Reminder.Draft(title: "Get groceries")
    }
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title")
    VALUES
      ('Get groceries')
    ```
  }
}

Since the `"id"` column is not specified in this query it allows the database to initialize it for
us. This `Draft` type is appropriate to use in any features that needs to build up a value without
specifying an ID.

Further, using the ``Insert/returning(_:)`` method you can get back the ID of the newly inserted
row:

@Row {
  @Column {
    ```swift
    Reminder
      .insert { Reminder.Draft(title: "Get groceries") }
      .returning(\.id)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title")
    VALUES
      ('Get groceries')
    RETURNING
      "id"
    ```
  }
}

Or even get back the entire newly-inserted row:

@Row {
  @Column {
    ```swift
    Reminder
      .insert { Reminder.Draft(title: "Get groceries") }
      .returning(\.self)
    ```
  }
  @Column {
    ```sql
    INSERT INTO "reminders"
      ("title")
    VALUES
      ('Get groceries')
    RETURNING
      "id", "title", "isCompleted"
    ```
  }
}

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

> Tip: Due to a [Swift limitation](https://github.com/swiftlang/swift/issues/90519) it is not
> currently possible to extend drafts with a public initializer that collides with the synthesized
> memberwise initializer:
>
> ```swift
> @Table public struct Todo {
>   let id: UUID
>   var description = ""
>   // ...
> }
>
> extension Todo.Draft {
>   public init(id: UUID? = nil, description: String = "") {  // 🛑
>     self.id = id
>     self.description = description
>   }
> }
> ```
>
> To work around the issue, define a static function, instead:
>
> ```swift
> extension Todo.Draft {
>   public static func create(id: UUID? = nil, description: String = "") -> Self {
>     Self(id: id, description: description)
>   }
> }
> ```

### Lazy initialization

It is possible to mark some fields of a draft as being "lazy-initializable." Such fields will be
optional in the generated `Draft` type, allowing their value to be set at a later time, matching
the lazy initialization of the draft's primary key. A canonical example of this is created/updated
timestamps for a record:

```swift
@Table
struct User {
  let id: UUID
  var name = ""
  let createdAt: Date
  let updatedAt: Date
}
```

It is not appropriate to assign these values when creating or updating the record, and instead it
is best to leave that logic to the database (_via_ default values and triggers). To make it so that
you can omit those fields when creating drafts, use the `@Column` macro with the
`lazyInitializable` option:

```swift
@Table struct User {
  let id: UUID
  var name = ""
  @Column(lazyInitializable: true)
  let createdAt: Date
  @Column(lazyInitializable: true)
  let updatedAt: Date
}

let draft = Draft(name: "Blob")
```

Another use for lazy-initializable properties in drafts comes from foreign keys. You typically want
foreign keys to be lazy-initialized so that you can create the parent record first, and then set the
foreign key on the child:

```swift
@Table struct Reminder {
  let id: UUID
  var name = ""
  @Column(lazyInitializable: true)
  var remindersListID: RemindersList.ID
}
```

This also allows you to work with uninserted parent/child records at the same time, and when ready
to insert, you can apply the parent ID to each child record.

> Note: In a future version of StructuredQueries, `lazyInitializable: true` will be the default
> behavior for all fields without a default value, and if you want to opt out of it you will
> provide `lazyInitializable: false`. To prepare for that future release you can enable the
> `LazyInitializableByDefault` trait in your dependence on StructuredQueries today.

Lazy initialization is not limited to primary-keyed tables. Marking any column of a table as
`lazyInitializable` will cause the `@Table` macro to generate a `Draft` type, even if the table has
no primary key.

## Topics

### Drafts

- ``TableDraft``
