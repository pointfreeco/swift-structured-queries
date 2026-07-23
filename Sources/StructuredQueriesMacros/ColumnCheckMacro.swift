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
    diagnoseUnrepresentableColumn(of: node, on: declaration, suggesting: .none, in: context)
    return []
  }
}

package enum ColumnCheckFailJSONMacro: PeerMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    diagnoseUnrepresentableColumn(of: node, on: declaration, suggesting: .json, in: context)
    return []
  }
}

package enum ColumnCheckFailRawRepresentableMacro: PeerMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    diagnoseUnrepresentableColumn(
      of: node, on: declaration, suggesting: .rawRepresentation, in: context
    )
    return []
  }
}

#if CasePaths
  package enum CaseCheckFailMacro: PeerMacro {
    package static func expansion(
      of node: AttributeSyntax,
      providingPeersOf declaration: some DeclSyntaxProtocol,
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
      var fixIts: [FixIt] = []
      if let optionalType = declaration.as(EnumCaseDeclSyntax.self)?
        .elements.first?
        .parameterClause?.parameters.first?
        .type.as(OptionalTypeSyntax.self)
      {
        let wrappedType = optionalType.wrappedType.trimmed
        fixIts.append(
          .replace(
            message: MacroExpansionFixItMessage(
              "Replace '\(optionalType.trimmed)' with '\(wrappedType)'"
            ),
            oldNode: optionalType,
            newNode: wrappedType
          )
        )
      }
      context.diagnose(
        Diagnostic(
          node: Syntax(declaration),
          message: MacroExpansionErrorMessage("Associated value must not be optional"),
          notes: [
            Note(
              node: Syntax(declaration),
              message: MacroExpansionNoteMessage(
                "A 'nil' value is indistinguishable from an absent case"
              )
            )
          ],
          fixIts: fixIts
        )
      )
      return []
    }
  }
#endif

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

private enum UnrepresentableSuggestion {
  case none
  case json
  case rawRepresentation
}

private func diagnoseUnrepresentableColumn(
  of node: AttributeSyntax,
  on declaration: some DeclSyntaxProtocol,
  suggesting suggestion: UnrepresentableSuggestion,
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
    )
  ]

  if !declaration.is(EnumCaseDeclSyntax.self) {
    fixIts.append(
      .replace(
        message: MacroExpansionFixItMessage("Apply '@Ephemeral' to exclude from table"),
        oldNode: declaration,
        newNode: declaration.applyingColumnFixIt("@Ephemeral")
      )
    )
  }

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
          suggestion == .rawRepresentation
            ? """
            \(defaultValue.map { "'\($0)'" } ?? "Type") is not representable as a column; conform \
            it to 'QueryBindable' to store it as its raw value
            """
            : "\(defaultValue.map { "'\($0)'" } ?? "Type") is not representable as a column"
        ),
        fixIts: fixIts
      )
    )
    return
  }
  let type = base.trimmedDescription

  let message: String
  switch suggestion {
  case .none:
    message = "'\(type)' is not representable as a column"
  case .json:
    message = "'\(type)' is not representable as a column"
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
  case .rawRepresentation:
    message = """
      '\(type)' is not representable as a column; conform it to 'QueryBindable' to store it as its \
      raw value
      """
    fixIts.insert(
      .replace(
        message: MacroExpansionFixItMessage(
          "Apply '@Column(as: \(type).RawRepresentation.self)' to store as its raw value"
        ),
        oldNode: declaration,
        newNode: declaration.applyingColumnFixIt(
          "@Column(as: \(raw: type).RawRepresentation.self)"
        )
      ),
      at: 0
    )
  }

  context.diagnose(
    Diagnostic(
      node: Syntax(declaration),
      message: MacroExpansionErrorMessage(message),
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
        return name != "_ColumnCheck" && name != "_CaseCheck" && name != "Column"
          && name != "Columns"
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
    if let caseDecl = self.as(EnumCaseDeclSyntax.self) {
      let leading = caseDecl.leadingTrivia
      let caseDecl = caseDecl.with(\.leadingTrivia, [])
      return DeclSyntax(
        caseDecl
          .with(\.attributes, rebuilt(caseDecl.attributes))
          .with(\.leadingTrivia, leading)
      )
    }
    return DeclSyntax(self)
  }
}
