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

    if let asyncSpecifier = declaration.signature.effectSpecifiers?.asyncSpecifier {
      context.diagnose(
        Diagnostic(
          node: asyncSpecifier,
          message: MacroExpansionErrorMessage(
            "'@DatabaseCollation' functions cannot be asynchronous"
          ),
          fixIts: [
            .replace(
              message: MacroExpansionFixItMessage("Remove 'async'"),
              oldNode: asyncSpecifier,
              newNode: TokenSyntax("")
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
            "'@DatabaseCollation' functions cannot throw"
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

    let argumentTypesMessage =
      "'@DatabaseCollation' functions must take two 'String', two 'UnsafeRawBufferPointer', two"
      + " 'UTF8Span', or two 'Span<UInt8>' arguments"
    let stringTypes = ["String", "Swift.String"]
    let rawTypes = ["UnsafeRawBufferPointer", "Swift.UnsafeRawBufferPointer"]
    let spanTypes = ["UTF8Span", "Swift.UTF8Span"]
    let byteSpanTypes = [
      "Span<UInt8>", "Span<Swift.UInt8>", "Swift.Span<UInt8>", "Swift.Span<Swift.UInt8>",
    ]
    let parameters = Array(declaration.signature.parameterClause.parameters)
    guard parameters.count == 2
    else {
      context.diagnose(
        Diagnostic(
          node: declaration.signature.parameterClause,
          message: MacroExpansionErrorMessage(argumentTypesMessage)
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
      guard
        !(stringTypes + rawTypes + spanTypes + byteSpanTypes)
          .contains(parameter.type.trimmedDescription)
      else { continue }
      context.diagnose(
        Diagnostic(
          node: parameter.type,
          message: MacroExpansionErrorMessage(argumentTypesMessage),
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
    func argumentKind(_ parameter: FunctionParameterSyntax) -> Int {
      let type = parameter.type.trimmedDescription
      return stringTypes.contains(type)
        ? 0
        : rawTypes.contains(type) ? 1 : spanTypes.contains(type) ? 2 : 3
    }
    let isRaw = argumentKind(parameters[0]) == 1
    let isSpan = argumentKind(parameters[0]) == 2
    let isByteSpan = argumentKind(parameters[0]) == 3
    guard argumentKind(parameters[0]) == argumentKind(parameters[1])
    else {
      context.diagnose(
        Diagnostic(
          node: declaration.signature.parameterClause,
          message: MacroExpansionErrorMessage(argumentTypesMessage),
          fixIts: [
            .replace(
              message: MacroExpansionFixItMessage(
                "Replace '\(parameters[1].type.trimmedDescription)' with"
                  + " '\(parameters[0].type.trimmedDescription)'"
              ),
              oldNode: parameters[1].type,
              newNode: parameters[0].type.trimmed
                .with(\.trailingTrivia, parameters[1].type.trailingTrivia)
            )
          ]
        )
      )
      return []
    }

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

    func witnessBody(prologue: String = "", _ call: (String, String) -> String) -> String {
      if isByteSpan {
        return """
          \(prologue)return \(call(
            "lhs.assumingMemoryBound(to: UInt8.self).span",
            "rhs.assumingMemoryBound(to: UInt8.self).span"
          ))
          """
      }
      if isSpan {
        return """
          \(prologue)do {
          let lhsSpan = try UTF8Span(validating: lhs.assumingMemoryBound(to: UInt8.self).span)
          let rhsSpan = try UTF8Span(validating: rhs.assumingMemoryBound(to: UInt8.self).span)
          return \(call("lhsSpan", "rhsSpan"))
          } catch {
          return lhs.elementsEqual(rhs)
          ? .same
          : lhs.lexicographicallyPrecedes(rhs) ? .ascending : .descending
          }
          """
      }
      func argument(_ name: String) -> String {
        isRaw ? name : "String(decoding: \(name), as: UTF8.self)"
      }
      return "\(prologue)return \(call(argument("lhs"), argument("rhs")))"
    }

    var decls: [DeclSyntax] = []
    let check: String
    if isSpan || isByteSpan {
      let probeName = context.makeUniqueName("\(declarationName)IsolationProbe")
      let isolation: TokenSyntax? =
        declaration.modifiers.contains { $0.name.tokenKind == .keyword(.nonisolated) }
        ? .keyword(.nonisolated, trailingTrivia: .space)
        : nil
      decls.append(
        """
        #if DEBUG
        \(isolation)\(`static`)func \(probeName)() {}
        #endif
        """
      )
      check = isolationCheck("collation", probeName.text, for: node, in: context)
    } else {
      check = isolationCheck(
        "collation",
        declaration.name.trimmedDescription,
        for: node,
        in: context
      )
    }

    guard isInstance
    else {
      let thunkName = context.makeUniqueName(declarationName)
      return decls + [
        """
        \(attributes)\(access)\(`static`)\(nonisolated)var $\(raw: declarationName): \
        \(collationTypeName) {
        \(raw: check)return \(collationTypeName)()
        }
        """,
        """
        \(attributes)\(access)\(`static`)\(nonisolated)func \(thunkName)(
        _ arg0: \(parameters[0].type.trimmed), _ arg1: \(parameters[1].type.trimmed)
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
        _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
        ) -> \(returnClause.type.trimmed) {
        \(raw: witnessBody { "\(thunkName)(\($0), \($1))" })
        }
        }
        """,
      ]
    }

    if let baseType {
      func baseCall(_ lhsArgument: String, _ rhsArgument: String) -> String {
        let arguments = parameters.enumerated()
          .map { offset, parameter in
            let argument = offset == 0 ? lhsArgument : rhsArgument
            return parameter.firstName.tokenKind == .wildcard
              ? argument
              : "\(parameter.firstName.text): \(argument)"
          }
          .joined(separator: ", ")
        return "base.\(declaration.name.trimmed)(\(arguments))"
      }
      let prologue =
        baseIsWeak
        ? #"""
        guard let base else {
        reportIssue(
        """
        Failed to invoke '\#(declaration.name.trimmed)'; '\#(baseType)' was deallocated
        """
        )
        return lhs.elementsEqual(rhs)
        ? .same
        : lhs.lexicographicallyPrecedes(rhs) ? .ascending : .descending
        }

        """#
        : ""
      let compareBody = witnessBody(prologue: prologue, baseCall)
      return decls + [
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
        _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
        ) -> \(returnClause.type.trimmed) {
        \(raw: compareBody)
        }
        }
        """,
      ]
    }

    let bodyType =
      "(\(parameters[0].type.trimmed), \(parameters[1].type.trimmed)) "
      + "-> \(returnClause.type.trimmed)"

    return decls + [
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
      _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
      ) -> \(returnClause.type.trimmed) {
      \(raw: witnessBody { "self.body(\($0), \($1))" })
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
