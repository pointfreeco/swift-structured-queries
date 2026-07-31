# Full-text search

## Overview

StructuredQueries comes with built-in support for SQLite's FTS5 module.

## Topics

### Virtual tables

- ``FTS5``

### Performing searches

- ``TableDefinition/match(_:)``
- ``TableColumnExpression/match(_:)``

### Ranking searches

- ``TableDefinition/rank``
- ``TableDefinition/bm25(_:)``

### Highlighting results

- ``TableColumnExpression/highlight(_:_:)``
- ``TableColumnExpression/snippet(_:_:_:_:)``
