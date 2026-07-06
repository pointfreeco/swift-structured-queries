# Migrating to 0.32

StructuredQueries 0.32 renamed its traits to match community convention.

## Overview

The `StructuredQueriesCasePaths` and `StructuredQueriesTagged` traits have been shortened to simply
`CasePaths` and `Tagged`, respectively. The old traits remain for now as aliases to the new traits,
but will be removed in a future version of StructuredQueries. If you have either of these traits
enabled in a project, make the appropriate changes to your Xcode projects and/or package files.
