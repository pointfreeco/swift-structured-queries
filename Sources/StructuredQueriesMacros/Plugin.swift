import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StructuredQueriesPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    BindMacro.self,
    ColumnMacro.self,
    ColumnsMacro.self,
    EphemeralMacro.self,
    SQLMacro.self,
    TableMacro.self,
  ]
}
