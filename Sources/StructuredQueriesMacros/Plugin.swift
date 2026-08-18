import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StructuredQueriesPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] =
    [
      BindMacro.self,
      ColumnCheckFailJSONMacro.self,
      ColumnCheckFailMacro.self,
      ColumnCheckFailRawRepresentableMacro.self,
      ColumnCheckGroupMacro.self,
      ColumnCheckPassMacro.self,
      ColumnDefinitionMacro.self,
      ColumnMacro.self,
      ColumnsMacro.self,
      EphemeralMacro.self,
      PrimaryKeyDefaultMacro.self,
      SQLMacro.self,
      TableMacro.self,
    ]
    + casePathsMacros
}

#if CasePaths
  private let casePathsMacros: [any Macro.Type] = [CaseCheckFailMacro.self]
#else
  private let casePathsMacros: [any Macro.Type] = []
#endif
