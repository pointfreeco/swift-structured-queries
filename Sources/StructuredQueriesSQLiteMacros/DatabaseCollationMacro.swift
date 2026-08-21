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

    let isInstance = `static` == nil && !context.lexicalContext.isEmpty
    var baseType: String?
    var baseIsWeak = false
    if isInstance, let enclosing = context.lexicalContext.first {
      if let decl = enclosing.as(ClassDeclSyntax.self) {
        baseType = decl.typeDescription
        baseIsWeak = true
      } else if let decl = enclosing.as(StructDeclSyntax.self) {
        baseType = decl.typeDescription
      } else if let decl = enclosing.as(EnumDeclSyntax.self) {
        baseType = decl.typeDescription
      }
    }

    let callArguments = parameters.enumerated()
      .map { offset, parameter in
        parameter.firstName.tokenKind == .wildcard
          ? "arg\(offset)"
          : "\(parameter.firstName.text): arg\(offset)"
      }
      .joined(separator: ", ")

    let check = isolationCheck(
      "collation",
      declaration.name.trimmedDescription,
      for: node,
      in: context
    )

    guard isInstance
    else {
      let thunkName = context.makeUniqueName(declarationName)
      return [
        """
        \(attributes)\(access)\(`static`)\(nonisolated)var $\(raw: declarationName): \
        \(collationTypeName) {
        \(raw: check)return \(collationTypeName)()
        }
        """,
        """
        \(attributes)\(access)\(`static`)\(nonisolated)func \(thunkName)(
        _ arg0: String, _ arg1: String
        ) -> \(returnClause.type.trimmed) {
        \(declaration.name.trimmed)(\(raw: callArguments))
        }
        """,
        """
        \(attributes)\(access)\(nonisolated)struct \(collationTypeName): \
        StructuredQueriesSQLiteCore.DatabaseCollation {
        public var name: String {
        \(databaseCollationName)
        }
        public init() {
        }
        public func compare(
        _ lhs: String, _ rhs: String
        ) -> \(returnClause.type.trimmed) {
        \(thunkName)(lhs, rhs)
        }
        }
        """,
      ]
    }

    if let baseType {
      let baseArguments = parameters.enumerated()
        .map { offset, parameter in
          let argument = offset == 0 ? "lhs" : "rhs"
          return parameter.firstName.tokenKind == .wildcard
            ? argument
            : "\(parameter.firstName.text): \(argument)"
        }
        .joined(separator: ", ")
      let compareBody =
        baseIsWeak
        ? """
        guard let base else {
        throw StructuredQueriesSQLiteCore._DatabaseCollationDeallocated()
        }
        return base.\(declaration.name.trimmed)(\(baseArguments))
        """
        : "base.\(declaration.name.trimmed)(\(baseArguments))"
      return [
        """
        \(attributes)\(access)\(nonisolated)var $\(raw: declarationName): \
        \(collationTypeName) {
        \(raw: check)return \(collationTypeName)(self)
        }
        """,
        """
        \(attributes)\(access)\(nonisolated)struct \(collationTypeName): \
        StructuredQueriesSQLiteCore.DatabaseCollation {
        public var name: String {
        \(databaseCollationName)
        }
        private \(raw: baseIsWeak ? "weak var" : "let") base: \
        \(raw: baseType)\(raw: baseIsWeak ? "?" : "")
        public init(_ base: \(raw: baseType)) {
        self.base = base
        }
        public func compare(
        _ lhs: String, _ rhs: String
        )\(raw: baseIsWeak ? " throws" : "") -> \(returnClause.type.trimmed) {
        \(raw: compareBody)
        }
        }
        """,
      ]
    }

    let bodyType = "(String, String) -> \(returnClause.type.trimmed)"

    return [
      """
      \(attributes)\(access)\(`static`)\(nonisolated)var $\(raw: declarationName): \
      \(collationTypeName) {
      \(raw: check)return \(collationTypeName)(\(declaration.name.trimmed))
      }
      """,
      """
      \(attributes)\(access)\(nonisolated)struct \(collationTypeName): \
      StructuredQueriesSQLiteCore.DatabaseCollation {
      public var name: String {
      \(databaseCollationName)
      }
      public let body: \(raw: bodyType)
      public init(_ body: @escaping \(raw: bodyType)) {
      self.body = body
      }
      public func compare(
      _ lhs: String, _ rhs: String
      ) -> \(returnClause.type.trimmed) {
      self.body(lhs, rhs)
      }
      }
      """,
    ]
  }
}

extension NamedDeclSyntax where Self: WithGenericParametersSyntax {
  fileprivate var typeDescription: String {
    var type = name.trimmedDescription
    if let genericParameterClause {
      type += "<\(genericParameterClause.parameters.map(\.name.text).joined(separator: ", "))>"
    }
    return type
  }
}
