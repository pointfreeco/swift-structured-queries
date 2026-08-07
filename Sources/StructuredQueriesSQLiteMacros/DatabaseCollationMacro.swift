import SwiftDiagnostics
internal import SwiftParser
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public enum DatabaseCollationMacro {}

extension DatabaseCollationMacro: PeerMacro {
  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingPeersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    guard let declaration = declaration.as(FunctionDeclSyntax.self)
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

    let collationOrder: TypeSyntax = "CollationOrder"
    guard let returnClause = declaration.signature.returnClause
    else {
      var signature = declaration.signature
      signature.parameterClause.trailingTrivia = ""
      signature.returnClause = ReturnClauseSyntax(
        arrow: .arrowToken(leadingTrivia: .space, trailingTrivia: .space),
        type: collationOrder,
        trailingTrivia: .space
      )
      context.diagnose(
        Diagnostic(
          node: declaration.signature,
          message: MacroExpansionErrorMessage(
            "'@DatabaseCollation' functions must return 'CollationOrder'"
          ),
          fixIts: [
            .replace(
              message: MacroExpansionFixItMessage("Return 'CollationOrder'"),
              oldNode: declaration.signature,
              newNode: signature
            )
          ]
        )
      )
      return []
    }
    guard
      ["CollationOrder", "StructuredQueriesCore.CollationOrder"]
        .contains(returnClause.type.trimmedDescription)
    else {
      context.diagnose(
        Diagnostic(
          node: returnClause.type,
          message: MacroExpansionErrorMessage(
            "'@DatabaseCollation' functions must return 'CollationOrder'"
          ),
          fixIts: [
            .replace(
              message: MacroExpansionFixItMessage(
                "Replace '\(returnClause.type.trimmedDescription)' with 'CollationOrder'"
              ),
              oldNode: returnClause.type,
              newNode: collationOrder.with(\.trailingTrivia, returnClause.type.trailingTrivia)
            )
          ]
        )
      )
      return []
    }

    if let throwsClause = declaration.signature.effectSpecifiers?.throwsClause {
      context.diagnose(
        Diagnostic(
          node: throwsClause,
          message: MacroExpansionErrorMessage(
            """
            '@DatabaseCollation' functions cannot throw

            SQLite requires a collating sequence to define a total ordering, and it offers no way \
            of surfacing an error from one.
            """
          ),
          fixIts: [
            .replace(
              message: MacroExpansionFixItMessage("Remove 'throws'"),
              oldNode: throwsClause,
              newNode: TokenSyntax("")
            )
          ]
        )
      )
      return []
    }

    let parameters = Array(declaration.signature.parameterClause.parameters)
    guard parameters.count == 2
    else {
      context.diagnose(
        Diagnostic(
          node: declaration.signature.parameterClause,
          message: MacroExpansionErrorMessage(
            "'@DatabaseCollation' functions must take two 'String' arguments"
          )
        )
      )
      return []
    }
    var hasInvalidParameter = false
    for parameter in parameters {
      if let ellipsis = parameter.ellipsis {
        context.diagnose(
          Diagnostic(
            node: ellipsis,
            message: MacroExpansionErrorMessage("Variadic arguments are not supported")
          )
        )
        return []
      }
      guard !["String", "Swift.String"].contains(parameter.type.trimmedDescription)
      else { continue }
      context.diagnose(
        Diagnostic(
          node: parameter.type,
          message: MacroExpansionErrorMessage(
            """
            '@DatabaseCollation' functions must take two 'String' arguments

            SQLite only invokes a collating sequence with the text being compared.
            """
          ),
          fixIts: [
            .replace(
              message: MacroExpansionFixItMessage(
                "Replace '\(parameter.type.trimmedDescription)' with 'String'"
              ),
              oldNode: parameter.type,
              newNode: TypeSyntax("String").with(\.trailingTrivia, parameter.type.trailingTrivia)
            )
          ]
        )
      )
      hasInvalidParameter = true
    }
    guard !hasInvalidParameter else { return [] }

    let declarationName = declaration.name.trimmedDescription.trimmingBackticks()
    var collationName = declarationName

    if case .argumentList(let arguments) = node.arguments {
      for argument in arguments {
        switch argument.label {
        case nil:
          guard
            let string = argument.expression.as(StringLiteralExprSyntax.self)?
              .representedLiteralValue
          else {
            context.diagnose(
              Diagnostic(
                node: argument.expression,
                message: MacroExpansionErrorMessage("Argument must be a non-empty string literal")
              )
            )
            return []
          }
          collationName = string

        case let argument?:
          fatalError("Unexpected argument: \(argument)")
        }
      }
    }

    let collationTypeName = context.makeUniqueName(declarationName)
    let databaseCollationName = StringLiteralExprSyntax(content: collationName)

    var attributes = declaration.attributes
    attributes.remove("DatabaseCollation")

    let (access, `static`) = declaration.modifiers.metadata

    let needsWeakSelf =
      `static` == nil
      && context.lexicalContext.contains { $0.as(ClassDeclSyntax.self) != nil }
    let canThrow = needsWeakSelf

    let bodyType = "(String, String)\(canThrow ? " throws" : "") -> \(returnClause.type.trimmed)"

    let projectedCallSyntax: ExprSyntax
    if needsWeakSelf {
      let callArguments = parameters.enumerated()
        .map { offset, parameter in
          parameter.firstName.tokenKind == .wildcard
            ? "arg\(offset)"
            : "\(parameter.firstName.text): arg\(offset)"
        }
        .joined(separator: ", ")
      projectedCallSyntax = """
        \(collationTypeName)({ [weak self] arg0, arg1 in
        guard let self else { throw StructuredQueriesSQLiteCore._DatabaseCollationDeallocated() }
        return self.\(declaration.name.trimmed)(\(raw: callArguments))
        })
        """
    } else {
      projectedCallSyntax = "\(collationTypeName)(\(declaration.name.trimmed))"
    }

    let check = isolationCheck(
      "collation",
      declaration.name.trimmedDescription,
      for: node,
      in: context
    )

    return [
      """
      \(attributes)\(access)\(`static`)\(nonisolated)var $\(raw: declarationName): \
      \(collationTypeName) {
      \(raw: check)return \(projectedCallSyntax)
      }
      """,
      """
      \(attributes)\(access)\(nonisolated)struct \(collationTypeName): \
      StructuredQueriesSQLiteCore.DatabaseCollation {
      public let name = \(databaseCollationName)
      public let body: \(raw: bodyType)
      public init(_ body: @escaping \(raw: bodyType)) {
      self.body = body
      }
      public func compare(
      _ lhs: String, _ rhs: String
      )\(raw: canThrow ? " throws" : "") -> \(returnClause.type.trimmed) {
      \(raw: canThrow ? "try " : "")self.body(lhs, rhs)
      }
      }
      """,
    ]
  }
}
