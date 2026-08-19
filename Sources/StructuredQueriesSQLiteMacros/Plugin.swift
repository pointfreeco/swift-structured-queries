import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StructuredQueriesPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    DatabaseCollationMacro.self,
    DatabaseCollationsMacro.self,
    DatabaseFunctionMacro.self,
    IsolationCheckMacro.self,
    MainActorIsolationCheckMacro.self,
  ]
}
