import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum BindMacro: ExpressionMacro {
  public static func expansion<N: FreestandingMacroExpansionSyntax, C: MacroExpansionContext>(
    of node: N,
    in context: C
  ) -> ExprSyntax {
    guard let argument = node.arguments.first?.expression else { fatalError() }
    let `as` = node.arguments.dropFirst().first
    return "\(moduleName).BindQueryExpression(\(argument)\(raw: `as`.map { ", \($0)" } ?? ""))"
  }
}
