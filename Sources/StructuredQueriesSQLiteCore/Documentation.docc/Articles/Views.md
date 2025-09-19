# Views

Learn how to create views that can be queried.

## Overview

[Views](https://www.sqlite.org/lang_createview.html) are pre-packaged select statements that can
be queried like a table. StructuredQueries comes with tools to create _temporary_ views in a
type-safe and schema-safe fashion.

### Creating temporary views

To define a view into your database you must first define a Swift data type

```swift
@Table @Selection
struct ReminderWithList {
  
}
```

## Topics

### Creating temporary views

- ``StructuredQueriesCore/Table/createTemporaryView(ifNotExists:as:)``

### Views

- ``TemporaryView``
