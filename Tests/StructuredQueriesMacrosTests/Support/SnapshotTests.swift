import MacroTesting
import SnapshotTesting
import StructuredQueriesMacros
import StructuredQueriesSQLiteMacros
import Testing

@MainActor
@Suite(
  .serialized,
  .macros(
    [
      "_Draft": TableMacro.self,
      "bind": BindMacro.self,
      "Column": ColumnMacro.self,
      "DatabaseFunction": DatabaseFunctionMacro.self,
      "Ephemeral": EphemeralMacro.self,
      "Selection": SelectionMacro.self,
      "sql": SQLMacro.self,
      "Table": TableMacro.self,
    ],
    record: .failed
  )
) struct SnapshotTests {}
