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
sophisticated you can define collating sequences in Swift using the `@DatabaseCollations` macro,
which annotates an extension of the ``StructuredQueriesCore/Collation`` protocol containing static
functions that compare two strings:

```swift
@DatabaseCollations
extension Collation where Self == CustomCollation {
  static func localized(_ lhs: String, _ rhs: String) -> CollationOrder {
    CollationOrder(lhs.localizedCompare(rhs))
  }
}
```

Each function returns a `CollationOrder`, which describes how the first value is ordered relative to
the second. It can be initialized from any two `Comparable` values, or from a Foundation
`ComparisonResult`, as above.

Once defined, the collating sequence is immediately usable in a query using leading dot syntax:

```swift
Reminder.order { $0.title.collate(.localized) }
// SELECT … FROM "reminders"
// ORDER BY "reminders"."title" COLLATE "localized"
```

By default, the collating sequence's name in SQL is the name of the Swift function that implements
it. To reference it by a different name in SQL, apply the `@DatabaseCollation` attribute to the
function:

```swift
@DatabaseCollations
extension Collation where Self == CustomCollation {
  @DatabaseCollation("localized_compare")
  static func localized(_ lhs: String, _ rhs: String) -> CollationOrder {
    CollationOrder(lhs.localizedCompare(rhs))
  }
}

Reminder.order { $0.title.collate(.localized) }
// SELECT … FROM "reminders"
// ORDER BY "reminders"."title" COLLATE "localized_compare"
```

For the query to successfully execute, you must also add the collating sequence to your SQLite
database connection. This can be done in [SQLiteData] using the `Database.add(collation:)` method,
_e.g._ when you first configure things:

[SQLiteData]: https://github.com/pointfreeco/sqlite-data

```swift
var configuration = Configuration()
configuration.prepareDatabase { db in
  db.add(collation: .localized)
}
```

## Topics

### Custom collations

- ``StructuredQueriesCore/Collation``
- ``StructuredQueriesCore/NamedCollation``
- ``StructuredQueriesCore/CollationOrder``
- ``StructuredQueriesCore/CustomCollation``
- ``StructuredQueriesCore/QueryExpression/collate(_:)``

### Built-in collations

- ``StructuredQueriesCore/Collation/binary``
- ``StructuredQueriesCore/Collation/nocase``
- ``StructuredQueriesCore/Collation/rtrim``
