import SwiftBasicFormat
import SwiftDiagnostics
internal import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DatabaseFunctionMacro {}

extension DatabaseFunctionMacro: PeerMacro {
  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingPeersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    guard let declaration = declaration.as(FunctionDeclSyntax.self) else {
      context.diagnose(
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            "'@DatabaseFunction' must be applied to functions"
          )
        )
      )
      return []
    }

    let returnClause =
      declaration.signature.returnClause
      ?? ReturnClauseSyntax(
        type: "Swift.Void" as TypeSyntax
      )
    let declarationName = declaration.name.trimmedDescription.trimmingBackticks()
    var functionName = declarationName
    var functionRepresentation: FunctionTypeSyntax?
    var isDeterministic = false
    if case .argumentList(let arguments) = node.arguments {
      for argumentIndex in arguments.indices {
        let argument = arguments[argumentIndex]
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
          functionName = string

        case .some(let label) where label.text == "as":
          guard
            let functionType =
              (argument
              .expression.as(MemberAccessExprSyntax.self)?
              .base?.as(TupleExprSyntax.self)?
              .elements.only?
              .trimmedDescription)
              .flatMap({
                TypeSyntax(stringLiteral: $0).as(FunctionTypeSyntax.self)
              }),
            functionType.parameters.count == declaration.signature.parameterClause.parameters.count
          else {
            context.diagnose(
              Diagnostic(
                node: argument.expression,
                message: MacroExpansionErrorMessage(
                  """
                  Argument must be a function type literal mapping to this function
                  """
                )
              )
            )
            return []
          }
          functionRepresentation = functionType

        case .some(let label) where label.text == "isDeterministic":
          guard
            let bool = argument.expression.as(BooleanLiteralExprSyntax.self)
          else {
            context.diagnose(
              Diagnostic(
                node: argument.expression,
                message: MacroExpansionErrorMessage("Argument must be a boolean literal")
              )
            )
            return []
          }
          isDeterministic = bool.literal.tokenKind == .keyword(.true)

        case let argument?:
          fatalError("Unexpected argument: \(argument)")
        }
      }
    }

    let functionTypeName = context.makeUniqueName(declarationName)
    let databaseFunctionName = StringLiteralExprSyntax(content: functionName)
    var argumentCounts: [ExprSyntax] = []

    var bodyArguments: [String] = []
    var representableInputTypes: [String] = []
    var signature = declaration.signature
    var invocationArgumentTypes: [TypeSyntax] = []
    var parameters: [String] = []
    var argumentBindings: [String] = []
    var offset = 0
    var functionRepresentationIterator = functionRepresentation?.parameters.makeIterator()

    var decodings: [String] = []
    var decodingUnwrappings: [String] = []

    for index in signature.parameterClause.parameters.indices {
      defer { offset += 1 }
      var parameter = signature.parameterClause.parameters[index]
      if let ellipsis = parameter.ellipsis {
        context.diagnose(
          Diagnostic(
            node: ellipsis,
            message: MacroExpansionErrorMessage("Variadic arguments are not supported")
          )
        )
        return []
      }
      bodyArguments.append("\(parameter.type.trimmed)")
      var type = (functionRepresentationIterator?.next()?.type ?? parameter.type)
      parameter.type = type.asQueryExpression()
      type = type.trimmed
      representableInputTypes.append(type.description)
      if let defaultValue = parameter.defaultValue,
        defaultValue.value.is(NilLiteralExprSyntax.self)
      {
        parameter.defaultValue?.value = "\(type).none"
      }
      signature.parameterClause.parameters[index] = parameter
      invocationArgumentTypes.append(type)
      let parameterName = (parameter.secondName ?? parameter.firstName).trimmedDescription
      parameters.append(parameterName)
      argumentBindings.append(parameterName)

      argumentCounts.append("\(type)")
      decodings.append("let \(parameterName) = try decoder.decode(\(type).self)")
      decodingUnwrappings.append("guard let \(parameterName) else { throw InvalidInvocation() }")
    }
    var representableInputType = representableInputTypes.joined(separator: ", ")
    let isVoidReturning = signature.returnClause == nil
    let outputType = returnClause.type.trimmed
    signature.returnClause = returnClause
    let representableOutputType = (functionRepresentation?.returnClause ?? returnClause).type
      .trimmed
    signature.returnClause?.type = representableOutputType.asQueryExpression()
    let bodyReturnClause = " \(returnClause.trimmedDescription)"
    let bodyType = """
      (\(bodyArguments.joined(separator: ", ")))\
      \(declaration.signature.effectSpecifiers?.trimmedDescription ?? "")\
      \(bodyReturnClause)
      """
    let bodyInvocation = """
      \(declaration.signature.effectSpecifiers?.throwsClause != nil ? "try " : "")self.body(\
      \(argumentBindings.joined(separator: ", "))\
      )
      """
    // TODO: Diagnose 'asyncClause'?
    signature.effectSpecifiers?.throwsClause = nil

    var invocationBody =
      isVoidReturning
      ? """
      \(bodyInvocation)
      return .null
      """
      : """
      return \(functionRepresentation?.returnClause.type ?? outputType)(
      queryOutput: \(bodyInvocation)
      )
      .queryBinding
      """
    if declaration.signature.effectSpecifiers?.throwsClause != nil {
      invocationBody = """
        do {
        \(invocationBody)
        } catch {
        return .invalid(error)
        }
        """
    }

    var attributes = declaration.attributes
    if let index = attributes.firstIndex(where: {
      $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text
        == "DatabaseFunction"
    }) {
      attributes.remove(at: index)
    }
    var access: TokenSyntax?
    var `static`: TokenSyntax?
    for modifier in declaration.modifiers {
      switch modifier.name.tokenKind {
      case .keyword(.private), .keyword(.internal), .keyword(.package), .keyword(.public):
        access = modifier.name
      case .keyword(.static):
        `static` = modifier.name
      default:
        continue
      }
    }
    representableInputType =
      representableInputTypes.count == 1
      ? representableInputType
      : "(\(representableInputType))"

    let argumentCount =
      argumentCounts.isEmpty
      ? "0"
      : """
      var argumentCount = 0
      \(argumentCounts.map { "argumentCount += \($0)._columnWidth\n" }.joined())\
      return argumentCount
      """

    return [
      """
      \(attributes)\(access)\(`static`)\(nonisolated)var $\(raw: declarationName): \(functionTypeName) {
      \(functionTypeName)(\(declaration.name.trimmed))
      }
      """,
      """
      \(attributes)\(access)\(nonisolated)struct \(functionTypeName): \
      StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
      public typealias Input = \(raw: representableInputType)
      public typealias Output = \(representableOutputType)
      public let name = \(databaseFunctionName)
      public var argumentCount: Int? {
      \(raw: argumentCount)
      }
      public let isDeterministic = \(raw: isDeterministic)
      public let body: \(raw: bodyType)
      public init(_ body: @escaping \(raw: bodyType)) {
      self.body = body
      }
      public func callAsFunction\(signature.trimmed) {
      StructuredQueriesCore.$_isSelecting.withValue(false) {
      StructuredQueriesCore.SQLQueryExpression(
      "\\(quote: self.name)(\(raw: parameters.map { "\\(\($0))" }.joined(separator: ", ")))"
      )
      }
      }
      public func invoke(
      _ decoder: inout some QueryDecoder
      ) throws -> StructuredQueriesCore.QueryBinding {
      \(raw: (decodings + decodingUnwrappings).map { "\($0)\n" }.joined())\
      \(raw: invocationBody)
      }
      private struct InvalidInvocation: Error {}
      }
      """,
    ]
  }
}

extension Collection {
  fileprivate var only: Element? {
    guard let first else { return nil }
    return dropFirst().first == nil ? first : nil
  }
}

extension ExprSyntax {
  fileprivate var isNonEmptyStringLiteral: Bool {
    guard let literal = self.as(StringLiteralExprSyntax.self)?.representedLiteralValue
    else { return false }
    return !literal.isEmpty
  }
}

extension String {
  fileprivate func trimmingBackticks() -> String {
    var result = self[...]
    if result.first == "`" && result.dropFirst().last == "`" {
      result = result.dropFirst().dropLast()
    }
    return String(result)
  }
}

extension TypeSyntaxProtocol {
  fileprivate func asQueryExpression(any: Bool = false) -> TypeSyntax {
    """
    \(raw: `any` ? "any" : "some") \
    StructuredQueriesCore.QueryExpression<\(trimmed)>\(trailingTrivia)
    """
  }
}
