# Migrating to 0.18

StructuredQueries 0.18 migrates existing functionality to a new StructuredQueriesSQLite module.

## Overview

StructuredQueries recently introduced a new module, StructuredQueriesSQLite, to house its
SQLite-specific helpers, and in 0.18 it has migrated many of its existing SQLite helpers into this
module.

If you are using SQLiteData this migration should be mostly transparent, but if you are using
StructuredQueries directly and need access to these helpers, you must now explicitly import this
helper module:

```diff
 import StructuredQueries
+import StructuredQueriesSQLite
```

If you are qualifying a SQLite-specific API, like the `FTS5` protocol, you must also update the
qualification:

```diff
 @Table
-struct ReminderText: StructuredQueries.FTS5 {
+struct ReminderText: StructuredQueriesSQLite.FTS5 {
```
