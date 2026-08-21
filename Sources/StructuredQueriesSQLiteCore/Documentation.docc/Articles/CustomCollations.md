# User-defined collating sequences

StructuredQueries comes with lightweight tools for defining collating sequences in Swift that SQLite
can use to compare and sort text.

## Overview

A collating sequence describes how SQLite compares two text values, and it is used any time values
are compared with `=`, `<`, `ORDER BY`, `GROUP BY`, `DISTINCT`, and more. SQLite comes with a few
built-in collating sequences, such as `.nocase`, and they can be applied to any string expression
using `collate`:

```swift
Reminder.order { $0.title.collate(.nocase) }
// SELECT … FROM "reminders"
// ORDER BY "reminders"."title" COLLATE "NOCASE"
```

### Defining a collating sequence

SQLite's built-in collating sequences are quite limited. `NOCASE`, for example, only folds the 26
uppercase ASCII characters, which means that "É" and "é" are not considered equal. For anything more
sophisticated you can define a collating sequence in Swift using the `@DatabaseCollation` macro,
which can annotate any function that compares two strings:

```swift
@DatabaseCollation
func localized(_ lhs: String, _ rhs: String) -> CollationOrder {
  CollationOrder(lhs.localizedCompare(rhs))
}
```

The function returns a `CollationOrder`, which describes how the first value is ordered relative to
the second. It can be initialized from any two `Comparable` values, or from a Foundation
`ComparisonResult`, as above.

Once defined, the collating sequence is immediately usable in a query by prefixing the function with
`$`:

```swift
Reminder.order { $0.title.collate($localized) }
// SELECT … FROM "reminders"
// ORDER BY "reminders"."title" COLLATE "localized"
```

For the query to successfully execute, you must also add the collating sequence to your SQLite
database connection. This can be done in [SQLiteData] using the `Database.add(collation:)` method,
_e.g._ when you first configure things:

[SQLiteData]: https://github.com/pointfreeco/sqlite-data

```swift
var configuration = Configuration()
configuration.prepareDatabase { db in
  db.add(collation: $localized)
}
```

### Leading-dot syntax

Built-in collating sequences are referenced with leading-dot syntax, like `.nocase`, and you can
give a collating sequence defined with `@DatabaseCollation` the same spelling by aliasing it as a
``StructuredQueriesCore/NamedCollation``:

```swift
extension Collation where Self == NamedCollation {
  static var localized: Self { NamedCollation($localized) }
}

Reminder.order { $0.title.collate(.localized) }
// SELECT … FROM "reminders"
// ORDER BY "reminders"."title" COLLATE "localized"
```

The alias refers to the collating sequence by name alone, so installing it in a database connection
still uses `$localized`.

## Topics

### Custom collations

- ``StructuredQueriesCore/Collation``
- ``StructuredQueriesCore/NamedCollation``
- ``StructuredQueriesCore/CollationOrder``
- ``DatabaseCollation``
- ``StructuredQueriesCore/QueryExpression/collate(_:)``

### Built-in collations

- ``StructuredQueriesCore/Collation/binary``
- ``StructuredQueriesCore/Collation/nocase``
- ``StructuredQueriesCore/Collation/rtrim``
