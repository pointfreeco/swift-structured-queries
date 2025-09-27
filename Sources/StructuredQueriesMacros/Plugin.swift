import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StructuredQueriesPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    BindMacro.self,
    ColumnMacro.self,
    ColumnsMacro.self,
    EphemeralMacro.self,
    SelectionMacro.self,
    SQLMacro.self,
    TableMacro.self,
  ]
}
