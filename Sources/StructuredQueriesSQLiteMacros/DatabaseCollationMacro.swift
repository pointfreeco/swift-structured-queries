import SwiftDiagnostics
internal import SwiftParser
public import SwiftSyntax
public import SwiftSyntaxMacros

public enum DatabaseCollationMacro {}

extension DatabaseCollationMacro: PeerMacro {
  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingPeersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    guard declaration.is(FunctionDeclSyntax.self)
    else {
      context.diagnose(
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            "'@DatabaseCollation' can only be applied to functions"
          )
        )
      )
      return []
    }

    guard
      context.lexicalContext.contains(where: {
        $0.as(ExtensionDeclSyntax.self)?.attributes.contains(where: {
          $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text
            == "DatabaseCollations"
        }) == true
      })
    else {
      context.diagnose(
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            "'@DatabaseCollation' has no effect outside of a '@DatabaseCollations' extension"
          )
        )
      )
      return []
    }

    if case .argumentList(let arguments) = node.arguments,
      let expression = arguments.first?.expression,
      !expression.isNonEmptyStringLiteral
    {
      context.diagnose(
        Diagnostic(
          node: expression,
          message: MacroExpansionErrorMessage("Argument must be a non-empty string literal")
        )
      )
    }
    return []
  }
}

extension ExprSyntax {
  fileprivate var isNonEmptyStringLiteral: Bool {
    guard let literal = self.as(StringLiteralExprSyntax.self)?.representedLiteralValue
    else { return false }
    return !literal.isEmpty
  }
}
