# User-defined SQL functions

StructuredQueries comes with lightweight tools for defining Swift functions that can be called to
from SQLite.

## Overview

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

And will be immediately callable in a query by prefixing the function with `$`:

```swift
Reminder.select { $exclaim($0.title) }
// SELECT "exclaim"("reminders"."title") FROM "reminders"
```

For the query to successfully execute, you must also add the function to your SQLite database
connection. This can be done in [SharingGRDB] (0.7.0+) using the `Database.add(function:)` method,
_e.g._ when you first configure things:

[SharingGRDB]: https://github.com/pointfreeco/sharing-grdb

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

### Custom representations

To define a type that works with a custom representation, like JSON, you can use the `as` parameter
of the macro:

```swift
@DatabaseFunction(
  as: (([String].JSONRepresentation) -> [String].JSONRepresentation).self
)
func jsonArrayExclaim(_ strings: [String]) -> [String] {
  strings.map { $0.localizedUppercase + "!" }
}
```

## Topics

### Custom functions

- ``DatabaseFunction``
- ``ScalarDatabaseFunction``
