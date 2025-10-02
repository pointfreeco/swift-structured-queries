# Integrating with database libraries

Learn how to integrate this library into existing database libraries so that you can build queries
in a type-safe manner.

## Overview

Since this library focuses only on the building of type-safe queries, it does not come with a way to
actually execute the query in a particular database. The library is built with the goal of being
able to support any database (SQLite, MySQL, Postgres, _etc._), but currently is primarily tuned to
work with SQLite. And further, it only comes with one official driver for SQLite, which is the
[SQLiteData] library that uses the popular [GRDB] library under the hood for interacting with
SQLite.

If you are interested in building an integration of StructuredQueries with another database
library, please [start a discussion][sq-discussions] and let us know of any challenges you
encounter.

[SQLiteData]: http://github.com/pointfreeco/sqlite-data
[GRDB]: http://github.com/groue/GRDB.swift
[sq-discussions]: http://github.com/pointfreeco/swift-structured-queries/discussions/new/choose

### Case Study: SQLite

One can integrate StructuredQueries with the SQLite C library by taking a few small steps. One
first needs to define a conformance to the ``QueryDecoder`` protocol, which describes how to decode
certain database types into Swift types. And then one must define a few helper methods that can
execute and decode SQL statements. This is done by defining a variety of methods that execute
``SelectStatement``s and ``Statement``s.

For a full implementation, see the [StructuredQueriesSQLite][sq-sqlite] module in the library. You
should be able to adapt this sample code to execute StructuredQueries with a SQLite connection, or
even integrate StructuredQueries into a 3rd party SQLite library.

[sq-sqlite]: https://github.com/pointfreeco/swift-structured-queries/tree/main/Sources/StructuredQueriesSQLite

### Case Study: GRDB

We provide one first-party library that integrates StructuredQueries into SQLite, and that is in
our [SQLiteData] library, which is a lightweight replacement for SwiftData and
the `@Query` macro. It brings a suite of tools allow you to fetch and observe data from a database
in your feature code, and views automatically update when data in the database changes.

The integration of StructuredQueries into SQLiteData works in the manner outlined above, in
<doc:Integration#Case-Study-SQLite>. The code can be found [here][sq-sqlite-data], where you will
find a ``QueryDecoder`` conformance, as well as some helper methods for fetching data using
StructuredQueries and GRDB.

[SQLiteData: http://github.com/pointfreeco/sqlite-data
[sq-sqlite-data]: https://github.com/pointfreeco/sqlite-data/tree/main/Sources/StructuredQueriesGRDBCore
