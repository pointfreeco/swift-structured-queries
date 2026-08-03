import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StructuredQueriesPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    BindMacro.self,
    ColumnCheckFailJSONMacro.self,
    ColumnCheckFailMacro.self,
    ColumnCheckGroupMacro.self,
    ColumnCheckPassMacro.self,
    ColumnCheckFailRawRepresentableMacro.self,
    ColumnMacro.self,
    ColumnsMacro.self,
    EphemeralMacro.self,
    PrimaryKeyDefaultMacro.self,
    SQLMacro.self,
    TableMacro.self,
  ]
}
