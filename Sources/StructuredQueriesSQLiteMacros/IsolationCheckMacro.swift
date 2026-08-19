import SwiftDiagnostics
public import SwiftSyntax
public import SwiftSyntaxMacros

public enum IsolationCheckMacro {}

extension IsolationCheckMacro: DeclarationMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}

public enum MainActorIsolationCheckMacro {}

extension MainActorIsolationCheckMacro: DeclarationMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let subject: String
    let decl: String
    switch node.arguments.first?.label?.text {
    case "collation":
      subject = "'@DatabaseCollations'"
      decl = "func"
    case "property":
      subject = "'@DatabaseFunction'"
      decl = "var"
    default:
      subject = "'@DatabaseFunction'"
      decl = "func"
    }
    context.diagnose(
      Diagnostic(
        node: node,
        message: MacroExpansionErrorMessage(
          "\(subject) must be 'nonisolated \(decl)' when default isolation is '@MainActor'"
        )
      )
    )
    return []
  }
}

func isolationCheck(
  _ label: String,
  _ reference: String,
  for node: AttributeSyntax,
  in context: some MacroExpansionContext
) -> String {
  let check = "#StructuredQueriesIsolationCheck(\(label): \(reference))"
  guard
    let location = context.location(of: node, at: .afterLeadingTrivia, filePathMode: .filePath)
  else {
    return """
      #if DEBUG
      \(check)
      #endif

      """
  }
  return """
    #if DEBUG
    #sourceLocation(file: \(location.file), line: \(location.line))
    \(check)
    #sourceLocation()
    #endif

    """
}
