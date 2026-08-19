import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StructuredQueriesPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    DatabaseCollationsMacro.self,
    DatabaseFunctionMacro.self,
    IsolationCheckMacro.self,
    MainActorIsolationCheckMacro.self,
  ]
}
