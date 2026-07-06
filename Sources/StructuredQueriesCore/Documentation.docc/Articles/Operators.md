# Operators

Manipulate query data using Swift-friendly operators and methods that translate to underlying SQL
operators.

## Overview

StructuredQueries provides many Swift operators and methods for expressing SQL operators.

When a SQL operator deviates from Swift, the Swift-appropriate version is used in its place. For
example, `!=` is used to test if two expressions are not equal rather than SQL's `<>`, and `+` is
used for string concatenation, not `||`:

| Swift                       | SQL equivalent   |
| --------------------------- | ---------------- |
| `&&`                        | `AND`            |
| `\|\|`                      | `OR`             |
| `!`                         | `NOT`            |
| `+` (string concatenation)  | `\|\|`           |
| `??`                        | `coalesce(_, _)` |

> `==` and `!=` are _not_ overloaded in Swift for a couple reasons:
>
>  1. Equality in SQL involves "three-valued logic": true, false, and null. Because of this there
>     is more than one equality operation: `=` and `IS`, along with their negations, `<>` and
>     `IS NOT`. To best preserve the intent of the generated SQL, StructuredQueries provides `eq`
>     and `is`, along with their negations, `neq` and `isNot`.
>
>  2. These operators are the most heavily overloaded in Swift and can strain the compiler in
>     complex queries.

Other SQL operators are translated to method equivalents in Swift:

```swift
Reminder.where { $0.title.like("Get%") }
// SELECT … FROM "reminders"
// WHERE ("reminders"."title" LIKE 'Get%')

Reminder.where { $0.id.in([1, 2, 3]) }
// SELECT … FROM "reminders"
// WHERE ("reminders"."id" IN (1, 2, 3))
```

While the library strives to provide APIs that match the generated SQL as closely as possible, it
also provides a few helpers that read like more idiomatic Swift:

```swift
Reminder.where { $0.title.hasPrefix("Get") }
// SELECT … FROM "reminders"
// WHERE ("reminders"."title" LIKE 'Get%')

Reminder.where { (10...20).contains($0.title.length()) }
// SELECT … FROM "reminders"
// WHERE (length("reminders"."title") BETWEEN (10 AND 20))
```

Explore the full list of operators below.

## Topics

### Equality

- ``QueryExpression/eq(_:)``
- ``QueryExpression/neq(_:)``
- ``QueryExpression/is(_:)``
- ``QueryExpression/isNot(_:)``

### Logical operations

- ``QueryExpression/&&(_:_:)``
- ``QueryExpression/||(_:_:)``
- ``QueryExpression/!(_:)``
- ``QueryExpression/and(_:)``
- ``QueryExpression/or(_:)``
- ``QueryExpression/not()``
- ``SQLQueryExpression/toggle()``

### Comparison operations

- ``QueryExpression/<(_:_:)``
- ``QueryExpression/>(_:_:)``
- ``QueryExpression/<=(_:_:)``
- ``QueryExpression/>=(_:_:)``
- ``QueryExpression/lt(_:)``
- ``QueryExpression/gt(_:)``
- ``QueryExpression/lte(_:)``
- ``QueryExpression/gte(_:)``

### Mathematical operations

- ``QueryExpression/+(_:_:)``
- ``QueryExpression/-(_:_:)``
- ``QueryExpression/*(_:_:)``
- ``QueryExpression//(_:_:)``
- ``QueryExpression/+(_:)``
- ``QueryExpression/-(_:)``
- ``SQLQueryExpression/+=(_:_:)``
- ``SQLQueryExpression/-=(_:_:)``
- ``SQLQueryExpression/*=(_:_:)``
- ``SQLQueryExpression//=(_:_:)``
- ``SQLQueryExpression/negate()``

### Bitwise operations

- ``QueryExpression/%(_:_:)``
- ``QueryExpression/&(_:_:)``
- ``QueryExpression/|(_:_:)``
- ``QueryExpression/<<(_:_:)``
- ``QueryExpression/>>(_:_:)``
- ``QueryExpression/~(_:)``
- ``SQLQueryExpression/&=(_:_:)``
- ``SQLQueryExpression/|=(_:_:)``
- ``SQLQueryExpression/<<=(_:_:)``
- ``SQLQueryExpression/>>=(_:_:)``

### String operations

- ``Collation``
- ``QueryExpression/collate(_:)``
- ``QueryExpression/+(_:_:)``
- ``QueryExpression/like(_:escape:)``
- ``QueryExpression/glob(_:)``
- ``QueryExpression/hasPrefix(_:)``
- ``QueryExpression/hasSuffix(_:)``
- ``QueryExpression/contains(_:)``
- ``SQLQueryExpression/+=(_:_:)``
- ``SQLQueryExpression/append(_:)``
- ``SQLQueryExpression/append(contentsOf:)``

### Collection and subquery operations

- ``QueryExpression/in(_:)``
- ``Statement/contains(_:)``
- ``PartialSelectStatement/exists()``
- ``Swift/Array``
- ``Swift/ClosedRange``
