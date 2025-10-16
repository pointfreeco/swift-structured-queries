# User-defined SQL functions

StructuredQueries comes with lightweight tools for defining Swift functions that can be called to
from SQLite.

## Overview

### Scalar functions

StructuredQueries defines a macro specifically for defining Swift functions that can be called from
a query. It's called `@DatabaseFunction`, and can annotate any function that works with
query-representable types.

For example, an `exclaim` function can be defined like so:

```swift
@DatabaseFunction
func exclaim(_ string: String) -> String {
  string.localizedUppercase + "!"
}
```

This defines a "scalar" function, which is called on a value for each row in a query, returning its
result.

> Note: If your project is using [default main actor isolation] then you further need to annotate
> your function as `nonisolated`.
[default main actor isolation]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md

Once defined, the function is immediately callable in a query by prefixing the function with `$`:

```swift
Reminder.select { $exclaim($0.title) }
// SELECT "exclaim"("reminders"."title") FROM "reminders"
```

For the query to successfully execute, you must also add the function to your SQLite database
connection. This can be done in [SQLiteData] using the `Database.add(function:)` method, _e.g._ when
you first configure things:

[SQLiteData]: https://github.com/pointfreeco/sqlite-data

```swift
var configuration = Configuration()
configuration.prepareDatabase { db in
  db.add(function: $exclaim)
}
```

> Tip: Use the `isDeterministic` parameter for functions that always return the same value from the
> same arguments. SQLite's query planner can optimize these functions.
>
> ```swift
> @DatabaseFunction(isDeterministic: true)
> func exclaim(_ string: String) -> String {
>   string.localizedUppercase + "!"
> }
> ```

### Aggregate functions

It is also possible to define a Swift function that builds a single result from multiple rows of a
query. The function must simply take a _sequence_ of query-representable types.

For example, suppose you want to compute the most common priority used across all reminders. This
computation is called the "mode" in statistics, and unfortunately SQLite does not supply such
a function. But it is quite easy to write this function in plain Swift:

```swift
@DatabaseFunction
func mode(priority priorities: some Sequence<Priority?>) -> Priority? {
  var occurrences: [Priority: Int] = [:]
  for priority in priorities {
    guard let priority
    else { continue }
    occurrences[priority, default: 0] += 1
  }
  return occurrences.max { $0.value < $1.value }?.key
}
```

This defines an "aggregate" function, and the sequence `priorities` that is passed to it represents
all of the data from the database passed to it while aggregating. It is now straightforward
to compute the mode of priorities across all reminders:

```swift
Reminder
  .select { $mode(priority: $0.priority) }
```

> Tip: Be sure to install the function in the database connection as discussed in 
> <doc:CustomFunctions#Scalar-functions> above.

You can also compute the mode of priorities inside each reminders list:

```swift
RemindersList
  .group(by: \.id)
  .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
  .select { ($0.title, $mode(priority: $1.priority)) }
```

### Custom representations

To define a type that works with a custom representation, _i.e._ anytime you use `@Column(as:)` in
your data type, you can use the `as` parameter of the macro to specify those types. For example,
if your model holds onto a date and you want to store that date as a
[unix timestamp](<doc:Foundation/Date/UnixTimeRepresentation-struct>) (i.e. double),
then you can do so like this:

```swift
@Table
struct Reminder {
  let id: UUID
  var title = ""
  @Column(as: Date.UnixTimeRepresentation.self)
  var dueDate: Date
}
```

And if you wanted to pass this `dueDate` to a Swift database function, you can do so like this:

```swift
@DatabaseFunction(
  as: ((Date.UnixTimeRepresentation.self) -> Bool).self
)
func isPastDue(_ date: Date) -> Bool {
  date < Date()
}
```

As another example, if you wanted to pass an array of strings from SQL to your Swift database
function, then you can shuffle the data through using json:

```swift
@DatabaseFunction(
  as: (([String].JSONRepresentation) -> [String].JSONRepresentation).self
)
func jsonArrayExclaim(_ strings: [String]) -> [String] {
  strings.map { $0.localizedUppercase + "!" }
}
```

It is also possible to do this with aggregate functions, too, but you must describe the sequence as
an `any Sequence` instead of a `some Sequence`:

```swift
@DatabaseFunction(
  as: ((any Sequence<[String].JSONRepresentation>) -> [String].JSONRepresentation).self
)
func jsonJoined(_ arrays: some Sequence<[String]>) -> [String] {
  arrays.flatMap(\.self)
}
```

## Topics

### Custom functions

- ``DatabaseFunction``
- ``ScalarDatabaseFunction``
- ``AggregateDatabaseFunction``
