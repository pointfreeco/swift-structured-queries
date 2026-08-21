import CustomDump
import Foundation
import InlineSnapshotTesting
public import StructuredQueriesCore

/// An end-to-end snapshot testing helper for statements.
///
/// This helper can be used to generate snapshots of both the given query and the results of the
/// query decoded back into Swift.
///
/// ```swift
/// assertQuery(
///   Reminder.select(\.title).order(by: \.title)
/// ) {
///   try db.execute($0)
/// } sql: {
///   """
///   SELECT "reminders"."title" FROM "reminders"
///   ORDER BY "reminders"."title"
///   """
/// } results: {
///   """
///   ┌────────────────────────────┐
///   │ "Buy concert tickets"      │
///   │ "Call accountant"          │
///   │ "Doctor appointment"       │
///   │ "Get laundry"              │
///   │ "Groceries"                │
///   │ "Haircut"                  │
///   │ "Pick up kids from school" │
///   │ "Send weekly emails"       │
///   │ "Take a walk"              │
///   │ "Take out trash"           │
///   └────────────────────────────┘
///   """
/// }
/// ```
///
/// - Parameters:
///   - query: A statement.
///   - execute: A closure responsible for executing the query and returning the results.
///   - sql: A snapshot of the SQL produced by the statement.
///   - results: A snapshot of the results.
///   - snapshotTrailingClosureOffset: The trailing closure offset of the `sql` snapshot. Defaults
///     to `1` for invoking this helper directly, but if you write a wrapper function that automates
///     the `execute` trailing closure, you should pass `0` instead.
///   - fileID: The source `#fileID` associated with the assertion.
///   - filePath: The source `#filePath` associated with the assertion.
///   - function: The source `#function` associated with the assertion
///   - line: The source `#line` associated with the assertion.
///   - column: The source `#column` associated with the assertion.
@_disfavoredOverload
public func assertQuery<each V: QueryRepresentable, S: Statement<(repeat each V)>>(
  _ query: S,
  execute: (S) throws -> [(repeat (each V).QueryOutput)],
  sql: (() -> String)? = nil,
  results: (() -> String)? = nil,
  snapshotTrailingClosureOffset: Int = 1,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  _assertQuery(
    query,
    table: {
      let rows = try execute(query)
      var table = ""
      printTable(rows, to: &table)
      return table
    },
    sql: sql,
    results: results,
    snapshotTrailingClosureOffset: snapshotTrailingClosureOffset,
    fileID: fileID,
    filePath: filePath,
    function: function,
    line: line,
    column: column
  )
}

/// An end-to-end snapshot testing helper for statements.
///
/// This helper can be used to generate snapshots of both the given query and the results of the
/// query decoded back into Swift.
///
/// ```swift
/// assertQuery(
///   Reminder.select(\.title).order(by: \.title)
/// ) {
///   try db.execute($0)
/// } sql: {
///   """
///   SELECT "reminders"."title" FROM "reminders"
///   ORDER BY "reminders"."title"
///   """
/// } results: {
///   """
///   ┌────────────────────────────┐
///   │ "Buy concert tickets"      │
///   │ "Call accountant"          │
///   │ "Doctor appointment"       │
///   │ "Get laundry"              │
///   │ "Groceries"                │
///   │ "Haircut"                  │
///   │ "Pick up kids from school" │
///   │ "Send weekly emails"       │
///   │ "Take a walk"              │
///   │ "Take out trash"           │
///   └────────────────────────────┘
///   """
/// }
/// ```
///
/// - Parameters:
///   - query: A statement.
///   - execute: A closure responsible for executing the query and returning the results.
///   - sql: A snapshot of the SQL produced by the statement.
///   - results: A snapshot of the results.
///   - snapshotTrailingClosureOffset: The trailing closure offset of the `sql` snapshot. Defaults
///     to `1` for invoking this helper directly, but if you write a wrapper function that automates
///     the `execute` trailing closure, you should pass `0` instead.
///   - fileID: The source `#fileID` associated with the assertion.
///   - filePath: The source `#filePath` associated with the assertion.
///   - function: The source `#function` associated with the assertion
///   - line: The source `#line` associated with the assertion.
///   - column: The source `#column` associated with the assertion.
@_disfavoredOverload
public func assertQuery<S: PartialSelectStatement>(
  _ query: S,
  execute: (S) throws -> [S.QueryValue],
  sql: (() -> String)? = nil,
  results: (() -> String)? = nil,
  snapshotTrailingClosureOffset: Int = 1,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  _assertQuery(
    query,
    table: {
      let rows = try execute(query)
      var table = ""
      printTable(values: rows, to: &table)
      return table
    },
    sql: sql,
    results: results,
    snapshotTrailingClosureOffset: snapshotTrailingClosureOffset,
    fileID: fileID,
    filePath: filePath,
    function: function,
    line: line,
    column: column
  )
}

public func assertQuery<S: SelectStatement, each J: Table>(
  _ query: S,
  execute: (Select<(S.From, repeat each J), S.From, (repeat each J)>) throws -> [(
    S.From.QueryOutput, repeat (each J).QueryOutput
  )],
  sql: (() -> String)? = nil,
  results: (() -> String)? = nil,
  snapshotTrailingClosureOffset: Int = 1,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) where S.QueryValue == (), S.Joins == (repeat each J) {
  assertQuery(
    query.selectStar(),
    execute: execute,
    sql: sql,
    results: results,
    snapshotTrailingClosureOffset: snapshotTrailingClosureOffset,
    fileID: fileID,
    filePath: filePath,
    function: function,
    line: line,
    column: column
  )
}

private func printTable<each C>(_ rows: [(repeat each C)], to output: inout some TextOutputStream) {
  var cellRows: [[String]] = []
  for row in rows {
    var cells: [String] = []
    for column in repeat each row {
      var cell = ""
      customDump(column, to: &cell)
      cells.append(cell)
    }
    cellRows.append(cells)
  }
  printTable(cellRows: cellRows, to: &output)
}

private func printTable<Row>(values rows: [Row], to output: inout some TextOutputStream) {
  var cellRows: [[String]] = []
  for row in rows {
    let mirror = Mirror(reflecting: row)
    var cells: [String] = []
    if mirror.displayStyle == .tuple {
      for child in mirror.children {
        var cell = ""
        customDump(child.value, to: &cell)
        cells.append(cell)
      }
    } else {
      var cell = ""
      customDump(row, to: &cell)
      cells.append(cell)
    }
    cellRows.append(cells)
  }
  printTable(cellRows: cellRows, to: &output)
}

private func printTable(cellRows: [[String]], to output: inout some TextOutputStream) {
  var maxColumnSpan = [Int](repeating: 0, count: cellRows.map(\.count).max() ?? 0)
  var hasMultiLineRows = false
  var table: [([[Substring]], maxRowSpan: Int)] = []
  for row in cellRows {
    var columns: [[Substring]] = []
    var maxRowSpan = 0
    for (index, cell) in row.enumerated() {
      let lines = cell.split(separator: "\n")
      hasMultiLineRows = hasMultiLineRows || lines.count > 1
      maxRowSpan = max(maxRowSpan, lines.count)
      maxColumnSpan[index] = max(maxColumnSpan[index], lines.map(\.count).max() ?? 0)
      columns.append(lines)
    }
    table.append((columns, maxRowSpan))
  }
  guard !table.isEmpty else { return }
  output.write("┌─")
  output.write(
    maxColumnSpan
      .map { String(repeating: "─", count: $0) }
      .joined(separator: "─┬─")
  )
  output.write("─┐\n")
  for (offset, rowAndMaxRowSpan) in table.enumerated() {
    let (row, maxRowSpan) = rowAndMaxRowSpan
    for rowOffset in 0..<maxRowSpan {
      output.write("│ ")
      var line: [String] = []
      for (columns, maxColumnSpan) in zip(row, maxColumnSpan) {
        if columns.count <= rowOffset {
          line.append(String(repeating: " ", count: maxColumnSpan))
        } else {
          line.append(
            columns[rowOffset]
              + String(repeating: " ", count: maxColumnSpan - columns[rowOffset].count)
          )
        }
      }
      output.write(line.joined(separator: " │ "))
      output.write(" │\n")
    }
    if hasMultiLineRows, offset != table.count - 1 {
      output.write("├─")
      output.write(
        maxColumnSpan
          .map { String(repeating: "─", count: $0) }
          .joined(separator: "─┼─")
      )
      output.write("─┤\n")
    }
  }
  output.write("└─")
  output.write(
    maxColumnSpan
      .map { String(repeating: "─", count: $0) }
      .joined(separator: "─┴─")
  )
  output.write("─┘")
}

private func _assertQuery(
  _ query: some Statement,
  table renderTable: () throws -> String,
  sql: (() -> String)?,
  results: (() -> String)?,
  snapshotTrailingClosureOffset: Int,
  fileID: StaticString,
  filePath: StaticString,
  function: StaticString,
  line: UInt,
  column: UInt
) {
  assertInlineSnapshot(
    of: query,
    as: .sql,
    message: "Query did not match",
    syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
      trailingClosureLabel: "sql",
      trailingClosureOffset: snapshotTrailingClosureOffset
    ),
    matches: sql,
    fileID: fileID,
    file: filePath,
    function: function,
    line: line,
    column: column
  )
  do {
    let table = try renderTable()
    if !table.isEmpty {
      assertInlineSnapshot(
        of: table,
        as: .lines,
        message: "Results did not match",
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "results",
          trailingClosureOffset: snapshotTrailingClosureOffset + 1
        ),
        matches: results,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
    } else if results != nil {
      assertInlineSnapshot(
        of: table,
        as: .lines,
        message: "Results expected to be empty",
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "results",
          trailingClosureOffset: snapshotTrailingClosureOffset + 1
        ),
        matches: results,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
    }
  } catch {
    assertInlineSnapshot(
      of: error.localizedDescription,
      as: .lines,
      message: "Results did not match",
      syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
        trailingClosureLabel: "results",
        trailingClosureOffset: snapshotTrailingClosureOffset + 1
      ),
      matches: results,
      fileID: fileID,
      file: filePath,
      function: function,
      line: line,
      column: column
    )
  }
}
