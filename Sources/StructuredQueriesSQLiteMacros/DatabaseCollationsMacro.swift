import SwiftDiagnostics
internal import SwiftParser
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public enum DatabaseCollationsMacro {}

extension DatabaseCollationsMacro: MemberMacro {
  public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingMembersOf declaration: D,
    conformingTo protocols: [TypeSyntax],
    in context: C
  ) throws -> [DeclSyntax] {
    let errorMessage = MacroExpansionErrorMessage(
      """
      '@DatabaseCollations' can only be applied to an \
      'extension Collation where Self == CustomCollation'
      """
    )
    guard let declaration = declaration.as(ExtensionDeclSyntax.self)
    else {
      context.diagnose(Diagnostic(node: node, message: errorMessage))
      return []
    }

    let extendsCollation =
      ["Collation", "StructuredQueriesCore.Collation", "StructuredQueries.Collation"]
      .contains(declaration.extendedType.trimmedDescription)
    let isConstrainedToCustomCollation =
      declaration.genericWhereClause?.requirements.contains(where: {
        [
          "Self==CustomCollation",
          "Self==StructuredQueriesCore.CustomCollation",
          "Self==StructuredQueries.CustomCollation",
        ]
        .contains($0.requirement.trimmedDescription.filter { !$0.isWhitespace })
      }) == true
    guard extendsCollation, isConstrainedToCustomCollation
    else {
      var newDeclaration = declaration
      if !extendsCollation {
        newDeclaration.extendedType = TypeSyntax("Collation")
          .with(\.trailingTrivia, declaration.extendedType.trailingTrivia)
      }
      newDeclaration.extendedType.trailingTrivia = .space
      newDeclaration.genericWhereClause = GenericWhereClauseSyntax(
        whereKeyword: .keyword(.where, trailingTrivia: .space),
        requirements: [
          GenericRequirementSyntax(
            requirement: .sameTypeRequirement(
              SameTypeRequirementSyntax(
                leftType: .type(TypeSyntax("Self")),
                equal: .binaryOperator("==", leadingTrivia: .space, trailingTrivia: .space),
                rightType: .type(TypeSyntax("CustomCollation"))
              )
            )
          )
        ],
        trailingTrivia: .space
      )
      let fixItMessage =
        if !extendsCollation {
          "Replace with 'extension Collation where Self == CustomCollation'"
        } else if declaration.genericWhereClause == nil {
          "Insert 'where Self == CustomCollation'"
        } else {
          "Replace constraint with 'Self == CustomCollation'"
        }
      context.diagnose(
        Diagnostic(
          node: node,
          message: errorMessage,
          fixIts: [
            .replace(
              message: MacroExpansionFixItMessage(fixItMessage),
              oldNode: declaration,
              newNode: newDeclaration
            )
          ]
        )
      )
      return []
    }

    var declarations: [DeclSyntax] = []
    for member in declaration.memberBlock.members {
      guard let function = member.decl.as(FunctionDeclSyntax.self)
      else { continue }

      guard
        let returnClause = function.signature.returnClause,
        ["CollationOrder", "StructuredQueriesCore.CollationOrder"]
          .contains(returnClause.type.trimmedDescription)
      else {
        context.diagnose(
          Diagnostic(
            node: function.signature,
            message: MacroExpansionErrorMessage(
              "'@DatabaseCollations' functions must return 'CollationOrder'"
            )
          )
        )
        return []
      }

      if let throwsClause = function.signature.effectSpecifiers?.throwsClause {
        context.diagnose(
          Diagnostic(
            node: throwsClause,
            message: MacroExpansionErrorMessage(
              """
              '@DatabaseCollations' functions cannot throw

              SQLite requires a collating sequence to define a total ordering, and it offers no \
              way of surfacing an error from one.
              """
            )
          )
        )
        return []
      }

      let parameters = Array(function.signature.parameterClause.parameters)
      guard
        parameters.count == 2,
        parameters.allSatisfy({
          $0.ellipsis == nil && ["String", "Swift.String"].contains($0.type.trimmedDescription)
        })
      else {
        context.diagnose(
          Diagnostic(
            node: function.signature.parameterClause,
            message: MacroExpansionErrorMessage(
              "'@DatabaseCollations' functions must take two 'String' arguments"
            )
          )
        )
        return []
      }

      let (access, `static`) = function.modifiers.metadata
      guard let `static`
      else {
        var newFunction = function
        newFunction.modifiers.append(
          DeclModifierSyntax(
            name: .keyword(
              .static,
              leadingTrivia: function.funcKeyword.leadingTrivia,
              trailingTrivia: .space
            )
          )
        )
        newFunction.funcKeyword.leadingTrivia = []
        context.diagnose(
          Diagnostic(
            node: function.name,
            message: MacroExpansionErrorMessage(
              "'@DatabaseCollations' functions must be 'static'"
            ),
            fixIts: [
              .replace(
                message: MacroExpansionFixItMessage("Insert 'static'"),
                oldNode: function,
                newNode: newFunction
              )
            ]
          )
        )
        return []
      }

      let declarationName = function.name.trimmedDescription.trimmingBackticks()
      var collationName = declarationName
      for attribute in function.attributes {
        guard
          let attribute = attribute.as(AttributeSyntax.self),
          attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DatabaseCollation",
          case .argumentList(let arguments) = attribute.arguments,
          let string = arguments.first?.expression.as(StringLiteralExprSyntax.self)?
            .representedLiteralValue
        else { continue }
        collationName = string
      }
      var attributes = function.attributes
      attributes.remove("DatabaseCollation")
      let databaseCollationName = StringLiteralExprSyntax(content: collationName)

      let check = isolationCheck(
        "collation",
        function.name.trimmedDescription,
        for: node,
        in: context
      )

      declarations.append(
        """
        \(attributes)\(access)\(`static`)\(nonisolated)var \(function.name.trimmed): \
        Self {
        \(raw: check)return StructuredQueriesCore.CustomCollation(\
        \(databaseCollationName), \(function.name.trimmed))
        }
        """
      )
    }
    return declarations
  }
}
