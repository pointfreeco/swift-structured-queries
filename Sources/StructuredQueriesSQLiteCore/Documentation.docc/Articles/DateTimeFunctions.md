# Date and time functions

Modify date-time expressions in a type-safe manner.

## Overview

SQLite provides a family of [date and time functions](https://sqlite.org/lang_datefunc.html) for
constructing, modifying, and formatting dates. This library provides type-safe helpers for these
functions that work with any date expression, including the current date:

```swift
Reminder.where { $0.createdAt > .now(.days(-7)) }
// SELECT … FROM "reminders"
// WHERE (("reminders"."createdAt") > (datetime('now', '-7 days', 'subsec')))
```

Dates are modified by calling a date expression as a function with one or more modifiers, which
can be chained together using dot syntax:

```swift
Reminder.select { $0.createdAt(.startOfDay.days(-7)) }
// SELECT datetime("reminders"."createdAt", 'start of day', '-7 days', 'subsec')
// FROM "reminders"
```

These helpers are aware of how each date is represented in the database, and generate SQL that
matches its storage:

```swift
Timestamp.select { $0.startedAt(.months(1)) }
// SELECT unixepoch("timestamps"."startedAt", 'unixepoch', '1 months')
// FROM "timestamps"
```

Individual components of a date can be extracted as integer expressions:

```swift
Reminder.select { $0.createdAt.year }
// SELECT CAST(strftime('%Y', "reminders"."createdAt") AS INTEGER)
// FROM "reminders"
```

And dates can be formatted with `strftime` substitutions:

```swift
Reminder.select { $0.createdAt.strftime("%Y-%m") }
// SELECT strftime('%Y-%m', "reminders"."createdAt")
// FROM "reminders"
```

## Topics

### Modifying dates

- ``StructuredQueriesCore/QueryExpression/callAsFunction(_:)``
- ``DateTimeModifier``

### Accessing date information

- ``StructuredQueriesCore/QueryExpression/year``
- ``StructuredQueriesCore/QueryExpression/month``
- ``StructuredQueriesCore/QueryExpression/day``
- ``StructuredQueriesCore/QueryExpression/hour``
- ``StructuredQueriesCore/QueryExpression/minute``
- ``StructuredQueriesCore/QueryExpression/second``
- ``StructuredQueriesCore/QueryExpression/fractionalSecond``
- ``StructuredQueriesCore/QueryExpression/weekday``
- ``StructuredQueriesCore/QueryExpression/dayOfYear``

### Date formatting

- ``StructuredQueriesCore/QueryExpression/strftime(_:)``
