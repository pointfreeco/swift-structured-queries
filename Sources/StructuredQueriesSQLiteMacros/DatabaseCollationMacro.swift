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
    var argumentTypes: [ArgumentType] = []
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
      guard let argumentType = ArgumentType(parameter.type)
      else {
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
        continue
      }
      argumentTypes.append(argumentType)
    }
    guard argumentTypes.count == parameters.count else { return [] }
    let argumentType = argumentTypes[0]
    guard argumentType == argumentTypes[1]
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

    func argument(_ name: String) -> String {
      switch argumentType {
      case .string: "String(decoding: \(name), as: UTF8.self)"
      case .unsafeRawBufferPointer: name
      case .utf8Span: "\(name)Span"
      case .byteSpan: "\(name).assumingMemoryBound(to: UInt8.self).span"
      }
    }

    func labeledArguments(_ lhs: String, _ rhs: String) -> String {
      parameters.enumerated()
        .map { offset, parameter in
          let argument = offset == 0 ? lhs : rhs
          return parameter.firstName.tokenKind == .wildcard
            ? argument
            : "\(parameter.firstName.text): \(argument)"
        }
        .joined(separator: ", ")
    }

    func witnessBody(prologue: String = "", _ call: (String, String) -> String) -> String {
      let invocation = "return \(call(argument("lhs"), argument("rhs")))"
      switch argumentType {
      case .string, .unsafeRawBufferPointer, .byteSpan:
        return "\(prologue)\(invocation)"
      case .utf8Span:
        return """
          \(prologue)do {
          let lhsSpan = try UTF8Span(validating: lhs.assumingMemoryBound(to: UInt8.self).span)
          let rhsSpan = try UTF8Span(validating: rhs.assumingMemoryBound(to: UInt8.self).span)
          \(invocation)
          } catch {
          return lhs.elementsEqual(rhs)
          ? .same
          : lhs.lexicographicallyPrecedes(rhs) ? .ascending : .descending
          }
          """
      }
    }

    var decls: [DeclSyntax] = []
    let check: String
    if argumentType.isNonEscapable {
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

    let projectedValue: ExprSyntax
    let storage: String
    let compareBody: String
    var thunk: DeclSyntax?
    if !isInstance {
      let thunkName = context.makeUniqueName(declarationName)
      projectedValue = "\(collationTypeName)()"
      storage = """
        public init() {
        }
        """
      compareBody = witnessBody { "\(thunkName)(\($0), \($1))" }
      thunk = """
        \(attributes)\(access)\(`static`)\(nonisolated)func \(thunkName)(
        _ arg0: \(parameters[0].type.trimmed), _ arg1: \(parameters[1].type.trimmed)
        ) -> \(returnClause.type.trimmed) {
        \(declaration.name.trimmed)(\(raw: labeledArguments("arg0", "arg1")))
        }
        """
    } else if let baseType {
      projectedValue = "\(collationTypeName)(self)"
      storage = """
        private \(baseIsWeak ? "weak var" : "let") base: \(baseType)\(baseIsWeak ? "?" : "")
        public init(_ base: \(baseType)) {
        self.base = base
        }
        """
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
      compareBody = witnessBody(prologue: prologue) {
        "base.\(declaration.name.trimmed)(\(labeledArguments($0, $1)))"
      }
    } else {
      let bodyType =
        "(\(parameters[0].type.trimmed), \(parameters[1].type.trimmed)) "
        + "-> \(returnClause.type.trimmed)"
      projectedValue = "\(collationTypeName)(\(declaration.name.trimmed))"
      storage = """
        public let body: \(bodyType)
        public init(_ body: @escaping \(bodyType)) {
        self.body = body
        }
        """
      compareBody = witnessBody { "self.body(\($0), \($1))" }
    }

    decls.append(
      """
      \(attributes)\(access)\(`static`)\(nonisolated)var $\(raw: declarationName): \
      \(collationTypeName) {
      \(raw: check)return \(projectedValue)
      }
      """
    )
    if let thunk {
      decls.append(thunk)
    }
    decls.append(
      """
      \(attributes)\(access)\(nonisolated)struct \(collationTypeName): \
      StructuredQueriesSQLiteCore.DatabaseCollation {
      public var name: String {
      \(databaseCollationName)
      }
      \(raw: storage)
      public func compare(
      _ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer
      ) -> \(returnClause.type.trimmed) {
      \(raw: compareBody)
      }
      }
      """
    )
    return decls
  }
}

extension DatabaseCollationMacro {
  fileprivate enum ArgumentType {
    case string
    case unsafeRawBufferPointer
    case utf8Span
    case byteSpan

    init?(_ type: TypeSyntax) {
      switch type.trimmedDescription {
      case "String", "Swift.String":
        self = .string
      case "UnsafeRawBufferPointer", "Swift.UnsafeRawBufferPointer":
        self = .unsafeRawBufferPointer
      case "UTF8Span", "Swift.UTF8Span":
        self = .utf8Span
      case "Span<UInt8>", "Span<Swift.UInt8>", "Swift.Span<UInt8>", "Swift.Span<Swift.UInt8>":
        self = .byteSpan
      default:
        return nil
      }
    }

    var isNonEscapable: Bool {
      switch self {
      case .string, .unsafeRawBufferPointer: false
      case .utf8Span, .byteSpan: true
      }
    }
  }
}
