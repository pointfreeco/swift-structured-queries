# Migrating to 0.18

StructuredQueries 0.18 migrates existing functionality to a new StructuredQueriesSQLite module.

## Overview

StructuredQueries recently introduced a new module, StructuredQueriesSQLite, to house its
SQLite-specific helpers, and in 0.18 it has migrated many of its existing SQLite helpers into this
module.

If you are using SharingGRDB this migration should be transparent, but if you are using
StructuredQueries directly and need access to these helpers, you must now explicitly import this
helper module:

```diff
 import StructuredQueries
+import StructuredQueriesSQLite
```
