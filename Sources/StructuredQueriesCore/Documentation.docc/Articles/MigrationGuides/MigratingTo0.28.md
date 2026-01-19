# Migrating to 0.28

StructuredQueries 0.28 introduces a small breaking change to some conflict-resolving insert APIs.

## Overview

StructuredQueries has several `insert` APIs that resolve conflicts using `onConflictDoUpdate` or
`doUpdate` blocks and introduce an `excluded` parameter:

```swift
onConflictDoUpdate: { row, excluded in
  row.title = excluded.title += " Copy"
}
```

There is an optional `where` filter that comes after this clause that previously only had access to
the inserted row. StructuredQueries 0.28 now binds an `excluded` parameter, as well, for full
flexibility.

To migrate, you may need to explicitly bind to the row:

```diff
 onConflictDoUpdate {
   $0.title = $1.title += " Copy"
-} where: {
-  $0.isPublished
+} where: { row, _
   row.isPublished
 }
```
