# ``StructuredQueriesSQLiteCore``

Core SQLite extensions to StructuredQueries.

## Overview

StructuredQueriesSQLite extends StructuredQueries with SQLite functionality, including support for
custom database functions, and more.

## Topics

### SQLite-specific functionality

- <doc:DefiningYourSchema>
- <doc:QueryCookbook>
- <doc:BuiltinFunctions>
- <doc:JSON>
- <doc:CustomFunctions>
- <doc:CustomCollations>
- <doc:Triggers>
- <doc:Views>
- <doc:FullTextSearch>

### Query representations

- ``Foundation/Date/JulianDayRepresentation``
- ``Foundation/Date/UnixTimeRepresentation``
- ``Foundation/UUID/BytesRepresentation``
- ``Foundation/UUID/UppercasedRepresentation``
- ``Swift/Decodable/JSONBRepresentation``

### Custom collations

- ``StructuredQueriesCore/Collation``
- ``StructuredQueriesCore/NamedCollation``
- ``StructuredQueriesCore/CollationOrder``
- ``CustomCollation``

### Casting

- ``StructuredQueriesCore/QueryExpression/cast(as:)``
- ``SQLiteType``
- ``SQLiteTypeAffinity``

### Deprecations

- ``Foundation/Date/ISO8601Representation``
- ``Foundation/UUID/LowercasedRepresentation``

### Statements

- ``StructuredQueriesCore/Delete/returning(_:)``
- ``StructuredQueriesCore/Insert/returning(_:)``
- ``StructuredQueriesCore/Update/returning(_:)``
