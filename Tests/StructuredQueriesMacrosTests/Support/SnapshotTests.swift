import MacroTesting
import SnapshotTesting
import StructuredQueries
import StructuredQueriesMacros
import Testing

@MainActor
@Suite(
  .serialized,
  .macros(
    [
      "_Draft": TableMacro.self,
      "bind": BindMacro.self,
      "Column": ColumnMacro.self,
      "Ephemeral": EphemeralMacro.self,
      "Selection": SelectionMacro.self,
      "sql": SQLMacro.self,
      "Table": TableMacro.self,
    ],
    record: .failed
  )
) struct SnapshotTests {}

extension Snapshotting where Value: QueryExpression {
  static var sql: Snapshotting<Value, String> {
    SimplySnapshotting.lines.pullback(\.queryFragment.debugDescription)
  }
}
