# StructuredQueries

[![CI](https://github.com/pointfreeco/swift-structured-queries/actions/workflows/ci.yml/badge.svg)](https://github.com/pointfreeco/swift-structured-queries/actions/workflows/ci.yml)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](https://www.pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-structured-queries%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-structured-queries)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-structured-queries%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-structured-queries)

A library for building SQL in a safe, expressive, and composable manner.

## Learn more

This library was motivated and designed over the course of many episodes on
[Point-Free](https://www.pointfree.co), a video series exploring advanced programming topics in the
Swift language, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and
[Stephen Celis](https://twitter.com/stephencelis). To support the continued development of this
library, [subscribe today](https://www.pointfree.co/pricing).

<a href="https://www.pointfree.co/collections/sqlite/sql-building">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0315.jpeg" width="600">
</a>

## Overview

StructuredQueries provides a suite of tools that empower you to write safe, expressive, composable
SQL with Swift. By simply attaching macros to types that represent your database schema:

```swift
@Table
struct Reminder {
  let id: Int
  var title = ""
  var isCompleted = false
  var priority: Int?
  var dueDate: Date?
}
```

You get instant access to a rich set of query building APIs, from simple:

<table>
<tr>
<th>Swift</th>
<th>SQL</th>
</tr>
<tr valign=top>
<td width=415>

```swift
Reminder.all
// => [Reminder]
```

</td>
<td width=415>

```sql
SELECT
  "reminders"."id",
  "reminders"."title",
  "reminders"."isCompleted",
  "reminders"."priority",
  "reminders"."dueDate"
FROM "reminders"
```

</td>
</tr>
</table>

To complex:

<table>
<tr>
<th>Swift</th>
<th>SQL</th>
</tr>
<tr valign=top>
<td width=415>

```swift
Reminder
  .select {
     ($0.priority,
      $0.title.groupConcat())
  }
  .where { !$0.isCompleted }
  .group(by: \.priority)
  .order { $0.priority.desc() }
// => [(Int?, String)]
```

</td>
<td width=415>

```sql
SELECT
  "reminders"."priority",
  group_concat("reminders"."title")
FROM "reminders"
WHERE (NOT "reminders"."isCompleted")
GROUP BY "reminders"."priority"
ORDER BY "reminders"."priority" DESC
```

</td>
</tr>
</table>

These APIs help you avoid runtime issues caused by typos and type errors, but they still embrace SQL
for what it is. StructuredQueries is not an ORM or a new query language you have to learn: its APIs
are designed to read closely to the SQL it generates, though they are often more succinct, and
always safer.

You are also never constrained by the query builder. You are free to introduce _safe_ SQL strings at
the granularity of your choice using the `#sql` macro. From small expressions:

```swift
Reminder.where {
  !$0.isCompleted && #sql("\($0.dueDate) < date()")
}
```

To entire statements:

```swift
#sql(
  """
  SELECT \(Reminder.columns) FROM \(Reminder.self)
  WHERE \(Reminder.priority) >= \(selectedPriority)
  """,
  as: Reminder.self
)
```

The library supports building everything from `SELECT`, `INSERT`, `UPDATE`, and `DELETE` statements,
to type-safe outer joins and recursive common table expressions. To learn more about building SQL
with StructuredQueries, check out the
[documentation](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/).

> [!IMPORTANT]
> This library does not come with any database drivers for making actual database requests, _e.g._,
> to SQLite, Postgres, MySQL. This library focuses only on building SQL statements and providing the
> tools to integrate with another library that makes the actual database requests. See
> [Database drivers](#database-drivers) for more information.

## Documentation

The documentation for the latest unstable and stable releases are available here:

  * [`main`](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/main/documentation/structuredqueriescore/)
  * [0.x.x](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/)

There are a number of articles in the documentation that you may find helpful as you become more
comfortable with the library:

  * [Getting started](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/gettingstarted)
  * [Defining your schema](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/definingyourschema)
  * [Primary keyed tables](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/primarykeyedtables)
  * [Safe SQL strings](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/safesqlstrings)
  * [Query cookbook](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/querycookbook)

As well as more comprehensive example usage:

  * [Selects](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/selectstatements)
  * [Inserts](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/insertstatements)
  * [Updates](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/updatestatements)
  * [Deletes](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/deletestatements)
  * ["Where" clauses](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/whereclauses)
  * [Common table expressions](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/commontableexpressions)
  * [Aggregate functions](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/aggregatefunctions)
  * [Operators](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/operators)
  * [Scalar functions](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/~/documentation/structuredqueriescore/scalarfunctions)

## Demos

There are a number of sample applications that demonstrate how to use StructuredQueries in the
[SharingGRDB](https://github.com/pointfreeco/sharing-grdb) repo. Check out
[this](https://github.com/pointfreeco/sharing-grdb/tree/main/Examples) directory to see them all,
including:

  * [Case Studies](https://github.com/pointfreeco/sharing-grdb/tree/main/Examples/CaseStudies):
    A number of case studies demonstrating the built-in features of the library.

  * [Reminders](https://github.com/pointfreeco/sharing-grdb/tree/main/Examples/Reminders): A rebuild
    of Apple's [Reminders][reminders-app-store] app that uses a SQLite database to model the
    reminders, lists and tags. It features many advanced queries, such as searching, and stats
    aggregation.

  * [SyncUps](https://github.com/pointfreeco/sharing-grdb/tree/main/Examples/SyncUps): We also
    rebuilt Apple's [Scrumdinger][scrumdinger] demo application using modern, best practices for
    SwiftUI development, including using this library to query and persist state using SQLite.

[reminders-app-store]: https://apps.apple.com/us/app/reminders/id1108187841
[scrumdinger]: https://developer.apple.com/tutorials/app-dev-training/getting-started-with-scrumdinger

## Database drivers

StructuredQueries is built with the goal of supporting any SQL database (SQLite, MySQL, Postgres,
_etc._), but is currently tuned to work with SQLite. It currently has one official driver:

  * [SharingGRDB](https://github.com/pointfreeco/sharing-grdb): A lightweight replacement for
    SwiftData and the `@Query` macro. SharingGRDB includes `StructuredQueriesGRDB`, a library that
    integrates this one with the popular [GRDB](https://github.com/groue/GRDB.swift) SQLite library.

If you are interested in building a StructuredQueries integration for another database library,
please see [Integrating with database libraries][sq-docs-integration], and
[start a discussion](http://github.com/pointfreeco/swift-structured-queries/discussions/new/choose)
to let us know of any challenges you encounter.

[sq-docs-integration]: https://swiftpackageindex.com/pointfreeco/swift-structured-queries/main/documentation/structuredqueriescore/integration

## Installation

You can add StructuredQueries to an Xcode project by adding it to your project as a package.

> https://github.com/pointfreeco/swift-structured-queries

If you want to use StructuredQueries in a [SwiftPM](https://swift.org/package-manager/) project,
it's as simple as adding it to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.4.0"),
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "StructuredQueries", package: "swift-structured-queries"),
```

If you are on Swift 6.1 or greater, you can enable package traits that extend the library with
support for other libraries. For example, you can introduce type-safe identifiers to your tables
_via_ [Tagged](https://github.com/pointfreeco/swift-tagged) by enabling the
`StructuredQueriesTagged` trait:

```diff
 dependencies: [
   .package(
     url: "https://github.com/pointfreeco/swift-structured-queries",
     from: "0.1.0",
+    traits: [
+      "StructuredQueriesTagged",
+    ]
   ),
 ]
```

## Community

If you want to discuss this library or have a question about how to use it to solve a particular
problem, there are a number of places you can discuss with fellow
[Point-Free](http://www.pointfree.co) enthusiasts:

  * For long-form discussions, we recommend the
    [discussions](http://github.com/pointfreeco/swift-structured-queries/discussions) tab of this
    repo.

  * For casual chat, we recommend the
    [Point-Free Community Slack](http://www.pointfree.co/slack-invite).

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
