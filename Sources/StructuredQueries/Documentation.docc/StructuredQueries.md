# ``StructuredQueries``

A library for building SQL in a type-safe, expressive, and composable manner.

## Overview

The core functionality of this library is defined in
[`StructuredQueriesCore`](structuredqueriescore), which this module automatically exports.

This module also contains all of the macros that support the core functionality of the library.

See [`StructuredQueriesCore`](structuredqueriescore) for general library usage.

StructuredQueries also ships SQLite-specific helpers:

  - [`StructuredQueriesSQLiteCore`](structuredqueriessqlitecore): Core, SQLite-specific
    functionality, including full-text search, type-safe temporary triggers, full-text search, and
    more.

  - [`StructuredQueriesSQLite`](structuredqueriessqlitecore): Everything from
    `StructuredQueriesSQLiteCore` and macros that support it, like `@DatabaseFunction.`

## Topics

### Macros

- ``Table(_:)``
- ``Column(_:as:primaryKey:)``
- ``Columns(primaryKey:)``
- ``Ephemeral()``
- ``Selection()``
- ``sql(_:as:)``
- ``bind(_:as:)``
