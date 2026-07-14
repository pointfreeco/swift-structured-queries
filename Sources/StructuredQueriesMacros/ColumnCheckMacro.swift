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

package enum ColumnCheckGroupMacro: PeerMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let property = declaration.as(VariableDeclSyntax.self) else { return [] }
    for attribute in property.attributes {
      guard
        let attribute = attribute.as(AttributeSyntax.self),
        let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
        attributeName == "Column" || attributeName == "Columns",
        case .argumentList(let arguments) = attribute.arguments
      else { continue }

      for argumentIndex in arguments.indices {
        let argument = arguments[argumentIndex]
        let message: String
        switch argument.label?.text {
        case nil:
          message = "Column name cannot be applied to a column group"
        case "generated":
          message = "Argument 'generated' cannot be applied to a column group"
        default:
          continue
        }
        var newAttribute = attribute
        var newArguments = arguments
        newArguments.remove(at: argumentIndex)
        if newArguments.isEmpty {
          newAttribute.leftParen = nil
          newAttribute.arguments = nil
          newAttribute.rightParen = nil
        } else {
          newArguments[newArguments.index(before: newArguments.endIndex)].trailingComma = nil
          newAttribute.arguments = .argumentList(newArguments)
        }
        context.diagnose(
          Diagnostic(
            node: argument,
            message: MacroExpansionErrorMessage(message),
            fixIt: .replace(
              message: MacroExpansionFixItMessage(
                "Remove '\(argument.trimmed.with(\.trailingComma, nil))'"
              ),
              oldNode: attribute,
              newNode: newAttribute
            )
          )
        )
      }
    }
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
        return name != "_ColumnCheck" && name != "Column" && name != "Columns"
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
