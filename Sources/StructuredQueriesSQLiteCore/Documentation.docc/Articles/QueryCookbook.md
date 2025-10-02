# Query cookbook

SQLite-specific techniques in writing queries with this library.

## Overview

The library comes with a variety of tools that allow you to define helpers for composing together
large and complex queries.

* [Pre-loading associations with JSON](#Pre-loading-associations-with-JSON)

### Pre-loading associations with JSON

There are times you may want to load rows from a table along with the data from some associated
table. For example, querying for all reminders lists along with an array of the reminders in each
list. We'd like to be able to query for this data and decode it into a collection of values
from the following data type:

```swift
struct Row {
  let remindersList: RemindersList
  let reminders: [Reminder]
}
```

However, typically this requires one to make multiple SQL queries. First a query to selects all
of the reminders lists:

```swift
let remindersLists = try RemindersLists.all.execute(db)
```

Then you execute another query to fetch all of the reminders associated with the lists just
fetched:

```swift
let reminders = try Reminder
  .where { $0.id.in(remindersLists.map(\.id)) }
  .execute(db))
```

And then finally you need to transform the `remindersLists` and `reminders` into a single collection
of `Row` values:

```swift
let rows = remindersLists.map { remindersList in
  Row(
    remindersList: remindersList,
    reminders: reminders.filter { reminder in
      reminder.remindersListID == remindersList.id
    }
  )
}
```

This can work, but it's incredibly inefficient, a lot of boilerplate, and prone to mistakes. And
this is doing work that SQL actually excels at. In fact, the condition inside the `filter` looks
suspiciously like a join constraint, which should give us a hint that what we are doing is not
quite right.

Another way to do this is to use the `@Selection` and `@Column` macros along with a
`JSONRepresentation`` of the collection of reminders you want to load for each list:

```swift
@Selection
struct Row {
  let remindersList: RemindersList
  @Column(as: [Reminder].JSONRepresentation.self)
  let reminders: [Reminder]
}
```

> Note: `Reminder` must conform to `Codable` to be able to use `JSONRepresentation`.

This allows the query to serialize the associated rows into JSON, which are then deserialized into
a `Row` type. To construct such a query you can use the
``StructuredQueriesCore/PrimaryKeyedTableDefinition/jsonGroupArray(distinct:order:filter:)``
property that is defined on the columns of primary-keyed tables:

```swift
RemindersList
  .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
  .select {
    Row.Columns(
      remindersList: $0,
      reminders: $1.jsonGroupArray()
    )
  }
```

> Note: There are 2 important things to note about this query:
>
>   * Since not every reminders list will have a reminder associated with it, we are using a
>     `leftJoin`. That will make sure to select all lists no matter what.
>   * The left join introduces _optional_ reminders, but we are using a special overload of
>     `jsonGroupArray` on optionals that automatically filters out `nil` reminders and unwraps them.

This allows you to fetch all of the data in a single SQLite query and decode the data into a
collection of `Row` values. There is an extra cost associated with decoding the JSON object,
but that cost may be smaller than executing multiple SQLite requests and transforming the data
into `Row` manually, not to mention the additional code you need to write and maintain to process
the data.

It is even possible to load multiple associations at once. For example, suppose that there is a
`Milestone` table that is associated with a `RemindersList`:

```swift
@Table
struct Milestone: Identifiable, Codable {
  let id: Int
  var title = ""
  var remindersListID: RemindersList.ID
}
```

And suppose you would like to fetch all `RemindersList`s along with the collection of all milestones
and reminders associated with the list:

```struct
@Selection
struct Row {
  let remindersList: RemindersList
  @Column(as: [Milestone].JSONRepresentation.self)
  let milestones: [Milestone]
  @Column(as: [Reminder].JSONRepresentation.self)
  let reminders: [Reminder]
}
```

It is possible to do this using two left joins and two `jsonGroupArray`s:

```swift
RemindersList
  .leftJoin(Milestone.all) { $0.id.eq($1.remindersListID) }
  .leftJoin(Reminder.all) { $0.id.eq($2.remindersListID) }
  .select {
    Row.Columns(
      remindersList: $0,
      milestones: $1.jsonGroupArray(distinct: true),
      reminders: $2.jsonGroupArray(distinct: true)
    )
  }
```

> Note: Because we are now joining two independent tables to `RemindersList`, we will get duplicate
> entries for all pairs of reminders with milestones. To remove those duplicates we use the
> `isDistinct` option for `jsonGroupArray`.

This will now load all reminders lists with all of their reminders and milestones in one single
SQL query.
