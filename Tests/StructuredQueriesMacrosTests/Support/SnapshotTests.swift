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
      "Columns": ColumnsMacro.self,
      "DatabaseFunction": DatabaseFunctionMacro.self,
      "Ephemeral": EphemeralMacro.self,
      "Selection": TableMacro.self,
      "sql": SQLMacro.self,
      "Table": TableMacro.self,
    ],
    record: .failed
  )
) struct SnapshotTests {}
