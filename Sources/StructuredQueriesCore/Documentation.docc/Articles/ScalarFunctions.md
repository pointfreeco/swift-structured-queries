# Scalar functions

Apply SQL functions to SQL expressions.

## Overview

Many SQL functions are available as type-safe methods on the expression they will wrap. For example,
the SQL `length` function is available to the builder when a given column or expression is a string:

```swift
Reminder.select { $0.title.length() }
// SELECT length("reminders"."title") FROM "reminders"
```

Explore the full list of available functions below.

## Topics

### Strings

- ``QueryExpression/instr(_:)``
- ``QueryExpression/length()``
- ``QueryExpression/lower()``
- ``QueryExpression/ltrim(_:)``
- ``QueryExpression/octetLength()``
- ``QueryExpression/quote()``
- ``QueryExpression/replace(_:_:)``
- ``QueryExpression/rtrim(_:)``
- ``QueryExpression/trim(_:)``
- ``QueryExpression/unhex(_:)``
- ``QueryExpression/upper()``

### Numeric

- ``QueryExpression/abs()``
- ``QueryExpression/round(_:)``
- ``QueryExpression/sign()``

### Optionality

- ``QueryExpression/??(_:_:)``
- ``QueryExpression/ifnull(_:)``

### Bytes

- ``QueryExpression/hex()``
