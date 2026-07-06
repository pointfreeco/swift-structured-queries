import SwiftDiagnostics
package import SwiftSyntax
import SwiftSyntaxBuilder
package import SwiftSyntaxMacros

package enum ColumnCheckPassMacro: PeerMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}

package enum ColumnCheckFailMacro: PeerMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    diagnoseUnrepresentableColumn(of: node, on: declaration, suggestingJSON: false, in: context)
    return []
  }
}

package enum ColumnCheckFailJSONMacro: PeerMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    diagnoseUnrepresentableColumn(of: node, on: declaration, suggestingJSON: true, in: context)
    return []
  }
}

private func diagnoseUnrepresentableColumn(
  of node: AttributeSyntax,
  on declaration: some DeclSyntaxProtocol,
  suggestingJSON: Bool,
  in context: some MacroExpansionContext
) {
  guard case .argumentList(let arguments) = node.arguments,
    let argument = arguments.first?.expression
  else { return }

  var fixIts: [FixIt] = [
    .replace(
      message: MacroExpansionFixItMessage("Apply '@Column(as:)' to specify a representation"),
      oldNode: declaration,
      newNode: declaration.applyingColumnFixIt("@Column(as: <#QueryRepresentable.Type#>)")
    ),
    .replace(
      message: MacroExpansionFixItMessage("Apply '@Ephemeral' to exclude from table"),
      oldNode: declaration,
      newNode: declaration.applyingColumnFixIt("@Ephemeral")
    ),
  ]

  guard
    let memberAccess = argument.as(MemberAccessExprSyntax.self),
    memberAccess.declName.baseName.tokenKind == .keyword(.self),
    let base = memberAccess.base
  else {
    let defaultValue = declaration.as(VariableDeclSyntax.self)?
      .bindings.first?.initializer?.value.trimmedDescription
    context.diagnose(
      Diagnostic(
        node: Syntax(declaration),
        message: MacroExpansionErrorMessage(
          "\(defaultValue.map { "'\($0)'" } ?? "Type") is not representable as a column"
        ),
        fixIts: fixIts
      )
    )
    return
  }
  let type = base.trimmedDescription

  if suggestingJSON {
    fixIts.insert(
      .replace(
        message: MacroExpansionFixItMessage(
          "Apply '@Column(as: \(type).JSONRepresentation.self)' to store as JSON"
        ),
        oldNode: declaration,
        newNode: declaration.applyingColumnFixIt(
          "@Column(as: \(raw: type).JSONRepresentation.self)"
        )
      ),
      at: 0
    )
  }

  context.diagnose(
    Diagnostic(
      node: Syntax(declaration),
      message: MacroExpansionErrorMessage("'\(type)' is not representable as a column"),
      fixIts: fixIts
    )
  )
}

extension DeclSyntaxProtocol {
  fileprivate func applyingColumnFixIt(_ attribute: AttributeSyntax) -> DeclSyntax {
    let attribute = attribute.with(\.trailingTrivia, .space)
    func rebuilt(_ attributes: AttributeListSyntax) -> AttributeListSyntax {
      var filtered = Array(attributes).filter { element in
        guard case .attribute(let attribute) = element else { return true }
        let name = attribute.attributeName.trimmedDescription
        return name != "_ColumnCheck" && name != "Column"
      }
      filtered.insert(.attribute(attribute), at: filtered.startIndex)
      return AttributeListSyntax(filtered)
    }
    if let variable = self.as(VariableDeclSyntax.self) {
      let leading = variable.leadingTrivia
      let variable = variable.with(\.leadingTrivia, [])
      return DeclSyntax(
        variable
          .with(\.attributes, rebuilt(variable.attributes))
          .with(\.leadingTrivia, leading)
      )
    }
    return DeclSyntax(self)
  }
}
