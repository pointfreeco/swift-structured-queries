import Dependencies
import StructuredQueries
import StructuredQueriesTestSupport
import _StructuredQueriesSQLite

func assertQuery<S: SelectStatement, each J: Table>(
  _ query: S,
  sql: (() -> String)? = nil,
  results: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) where S.QueryValue == (), S.Joins == (repeat each J) {
  @Dependency(\.defaultDatabase) var db
  StructuredQueriesTestSupport.assertQuery(
    query,
    execute: db.execute,
    sql: sql,
    results: results,
    snapshotTrailingClosureOffset: 0,
    fileID: fileID,
    filePath: filePath,
    function: function,
    line: line,
    column: column
  )
}

func assertQuery<V: QueryRepresentable>(
  _ query: some Statement<V>,
  sql: (() -> String)? = nil,
  results: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  @Dependency(\.defaultDatabase) var db
  StructuredQueriesTestSupport.assertQuery(
    query,
    execute: db.execute,
    sql: sql,
    results: results,
    snapshotTrailingClosureOffset: 0,
    fileID: fileID,
    filePath: filePath,
    function: function,
    line: line,
    column: column
  )
}

func assertQuery<each V: QueryRepresentable>(
  _ query: some Statement<(repeat each V)>,
  sql: (() -> String)? = nil,
  results: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  @Dependency(\.defaultDatabase) var db
  StructuredQueriesTestSupport.assertQuery(
    query,
    execute: db.execute,
    sql: sql,
    results: results,
    snapshotTrailingClosureOffset: 0,
    fileID: fileID,
    filePath: filePath,
    function: function,
    line: line,
    column: column
  )
}
