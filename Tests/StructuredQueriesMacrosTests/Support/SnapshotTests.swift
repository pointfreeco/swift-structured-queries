import MacroTesting
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SnapshotTesting
import StructuredQueriesMacros
import StructuredQueriesSQLiteMacros
import Testing

@MainActor
@Suite(
  .serialized,
  .macros(
    [
      "_Draft": MacroSpec(
        type: TableMacro.self,
        conformances: ["TableDraft", "PartialSelectStatement"]
      ),
      "bind": MacroSpec(type: BindMacro.self),
      "Column": MacroSpec(type: ColumnMacro.self),
      "Columns": MacroSpec(type: ColumnsMacro.self),
      "DatabaseFunction": MacroSpec(type: DatabaseFunctionMacro.self),
      "Ephemeral": MacroSpec(type: EphemeralMacro.self),
      "Selection": MacroSpec(
        type: TableMacro.self,
        conformances: [
          "_Selection", "Table", "PartialSelectStatement", "PrimaryKeyedTable", "CasePathable",
          "CasePathIterable",
        ]
      ),
      "sql": MacroSpec(type: SQLMacro.self),
      "Table": MacroSpec(
        type: TableMacro.self,
        conformances: [
          "Table", "PartialSelectStatement", "PrimaryKeyedTable", "CasePathable",
          "CasePathIterable",
        ]
      ),
    ],
    record: .failed
  )
) struct SnapshotTests {}
