import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum PrimaryKeyDefaultMacro {}

extension PrimaryKeyDefaultMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard
      let property = declaration.as(VariableDeclSyntax.self),
      let binding = property.bindings.first,
      let initializer = binding.initializer?.value.as(FunctionCallExprSyntax.self),
      let keyPathArgument = initializer.arguments.first(where: { $0.label?.text == "keyPath" }),
      let keyPath = keyPathArgument.expression.as(KeyPathExprSyntax.self),
      let component = keyPath.components.last?.component.as(
        KeyPathPropertyComponentSyntax.self
      )
    else {
      context.diagnose(
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            """
            '@_PrimaryKeyDefault' must be applied to a column property initialized with a \
            'keyPath' argument
            """
          )
        )
      )
      return []
    }
    return ["get { \(component.declName.baseName.trimmed) }"]
  }
}
