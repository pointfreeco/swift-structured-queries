import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StructuredQueriesPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    DatabaseFunctionMacro.self
    IsolationCheckMacro.self,
    MainActorIsolationCheckMacro.self,
  ]
}
