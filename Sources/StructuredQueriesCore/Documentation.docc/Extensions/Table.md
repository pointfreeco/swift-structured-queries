# ``StructuredQueriesCore/Table``

## Topics

### Query building

- ``all``
- ``distinct(_:)``
- ``select(_:)``
- ``join(_:on:)``
- ``leftJoin(_:on:)``
- ``rightJoin(_:on:)``
- ``fullJoin(_:on:)``
- ``where(_:)``
- ``group(by:)``
- ``having(_:)``
- ``order(by:)``
- ``limit(_:offset:)``
- ``count(filter:)``
- ``insert(_:values:onConflict:where:doUpdate:where:)``
- ``insert(_:select:onConflict:where:doUpdate:where:)``
- ``insert()``
- ``update(set:)``
- ``delete()``

### Schema definition

- ``tableName``
- ``schemaName``
- ``columns-swift.type.property``
- ``TableColumns``
- ``TableColumn``
- ``TableColumnExpression``
- ``ColumnGroup``
- ``TableDefinition``
- ``TableExpression``

### Scoping

- ``DefaultScope``
- ``unscoped``

### Column shorthand syntax

- ``subscript(dynamicMember:)``

### Table aliasing

- ``tableAlias``
- ``as(_:)``

### Deprecations

- ``insert(_:onConflict:)``
- ``insert(_:select:onConflict:)``
- ``insert(_:select:onConflictDoUpdate:where:)``
- ``insert(_:values:onConflict:)``
- ``insert(_:values:onConflictDoUpdate:where:)``
