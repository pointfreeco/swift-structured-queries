# Compiler performance

Learn how to write complex queries that do not tax the compiler too much.

## Overview

The library makes use of overloaded operators in order to allow you to write SQL queries in a
syntax that mimics what SQL actually looks like, while also being true to how Swift code is written.
This typically works without any problems, but for very complex queries, especially ones involving
joins, the compiler can have trouble figuring out the types involved with the overloaded operators.
The library provides a few tools to help mitigate this problem so that you can continue reaping the
benefits of type-safety and expressivity in your queries, while also helping out Swift in compiling
your queries.

### The #sql macro

The library ships with a tool that allows one to write safe SQL strings _via_ the `#sql` macro (see
<doc:SafeSQLStrings> for more info). Usage of the `#sql` macro does not affect the safety of your
queries from SQL injection attacks, nor does it prevent you making use of your table's schema in
the query. The primary downside to using `#sql` is that it can complicate decoding query results
into custom types, but when used for small fragments of a query one typically avoids such
complications.

And because `#sql` works on a simple string, it is capable of being compiled much faster than the
equivalent version using the builder syntax with operators. Consider the following query that
selects all reminders with no due date, or whose due date is in the past:

```sql
SELECT * FROM "reminders"
WHERE
  coalesce("reminders"."date", date('now')) <= date('now')
```

One can theoretically write the `coalesce` SQL fragment using the query building tools of this
library, but doing so can be overhanded and obscure what the query is trying to do. For this
very specific, complex logic it can be beneficial to use the `#sql` macro to write the fragment
directly as SQL:

```swift
Reminder
  .where {
    #sql("coalesce(\($0.date), date('now')) <= date('now')")
  }
```

This generates the same query but we use the `#sql` tool for just the small fragment of SQL that
we do not want to recreate in the builder. We are still protected from SQL injection attacks
with this tool, and we are even able to use the the statically defined columns of our type via
interpolation, but it should compile immediately compared to trying to piece together the complex
expression with the tools of the builder.
