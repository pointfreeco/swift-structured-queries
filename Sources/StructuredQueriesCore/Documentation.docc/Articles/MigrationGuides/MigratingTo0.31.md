# Migrating to 0.31

StructuredQueries 0.31 introduces two breaking changes to support Xcode 26.4 and Swift 6.3.

## Overview

There are two breaking changes in 0.31 that you may need to account for when you upgrade:

### Operators == and != are now unavailable

Since its initial release, StructuredQueries has urged folks to prefer `eq`/`is` and `neq`/`isNot`
over the `==` and `!=` operators for performance concerns, as well as correctness around
triple-valued logic.

With this release we are making them completely unavailable. So you will need to update call sites
to use `eq` (or `is`) and `neq` (or `isNot`) instead:

```diff
 RemindersList.leftJoin(Reminder.all) {
-  $0.id == $1.remindersListID  🛑 '==' is unavailable: Use 'eq' (or 'is') instead.
+  $0.id.eq($1.remindersListID)
 }
 
 RemindersList.where {
-  $0.dueDate == nil            🛑 '==' is unavailable: Use 'is' instead.
+  $0.dueDate.is(nil)
 }
```

### Require #bind macro in updates

Due to changes in Swift 6.3, the compiler can no longer automatically promote some values into
query expressions, particularly when it comes to `UPDATE` queries. To mitigate this, we have added
an unavailable diagnostic to help you migrate your queries:

```diff
 Reminder.update {
   🛑 Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
-  $0.dueDate = Date()
+  $0.dueDate = #bind(Date())
 }
```
