# Migrating to 0.16

StructuredQueries 0.16 introduces powerful tools for user-defined SQLite functions, with some
breaking changes for those defining custom query representations.

## Overview

StructuredQueries recently introduced a new module, StructuredQueriesSQLite, and with it a new macro
for defining Swift functions that can be called from a query. It's called `@DatabaseFunction`, and
can annotate any function that works with query-representable types.

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
> same arguments. SQLite can optimize these functions.
>
> ```swift
> @DatabaseFunction(isDeterministic: true)
> func exclaim(_ x: String) -> String {
>   x.localizedUppercase + "!"
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

### Breaking change: user-defined representations

To power things, a new initializer, ``QueryBindable/init(queryBinding:)``, was added to the
``QueryBindable`` protocol. While most code should continue to compile, if you define your own
query representations that conform to ``QueryRepresentable``, you will need to define this
initializer upon upgrading.

For example, `JSONRepresentation` added the following initializer:

```swift
public init?(queryBinding: QueryBinding) {
  guard case .text(let json) = queryBinding else { return nil }
  guard let queryOutput = try? jsonDecoder.decode(
    QueryOutput.self, from: Data(json.utf8)
  )
  else { return nil }
  self.init(queryOutput: queryOutput)
}
```
