# Full-text search

## Overview

StructuredQueries comes with built-in support for SQLite's FTS5 module.

## Topics

### Virtual tables

- ``FTS5``

### Performing searches

- ``StructuredQueriesCore/TableDefinition/match(_:)``
- ``StructuredQueriesCore/TableColumnExpression/match(_:)``

### Ranking searches

- ``StructuredQueriesCore/TableDefinition/rank``
- ``StructuredQueriesCore/TableDefinition/bm25(_:)``

### Highlighting results

- ``StructuredQueriesCore/TableColumnExpression/highlight(_:_:)``
- ``StructuredQueriesCore/TableColumnExpression/snippet(_:_:_:_:)``
