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

    guard declaration.signature.returnClause != nil else {
      context.diagnose(
        Diagnostic(
          node: declaration.signature,
          position: declaration.signature.endPositionBeforeTrailingTrivia,
          message: MacroExpansionErrorMessage(
            "Missing required return type"
          ),
          fixIt: .replaceChild(
            message: MacroExpansionFixItMessage("Insert '-> <#QueryBindable#>'"),
            parent: declaration.signature,
            replacingChildAt: \.returnClause,
            with: ReturnClauseSyntax(
              type: IdentifierTypeSyntax(name: "<#QueryBindable#>")
                .with(\.leadingTrivia, .space)
                .with(\.trailingTrivia, .space)
            )
          )
        )
      )
      return []
    }

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
            let functionType = (
              argument
              .expression.as(MemberAccessExprSyntax.self)?
              .base?.as(TupleExprSyntax.self)?
              .elements.only?
              .trimmedDescription
            )
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
    let argumentCount = declaration.signature.parameterClause.parameters.count

    var bodyArguments: [String] = []
    var signature = declaration.signature
    var invocationArgumentTypes: [TypeSyntax] = []
    var parameters: [String] = []
    var argumentBindings: [(String, String)] = []
    var offset = 0
    var functionRepresentationIterator = functionRepresentation?.parameters.makeIterator()
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
      let type = (functionRepresentationIterator?.next()?.type ?? parameter.type).trimmed
      parameter.type = type.asQueryExpression()
      if let defaultValue = parameter.defaultValue,
        defaultValue.value.is(NilLiteralExprSyntax.self)
      {
        parameter.defaultValue?.value = "\(type).none"
      }
      signature.parameterClause.parameters[index] = parameter
      invocationArgumentTypes.append(type)
      let parameterName = "\(parameter.secondName ?? parameter.firstName)"
      parameters.append(parameterName)
      argumentBindings.append((parameterName, "\(type)(queryBinding: arguments[\(offset)])"))
    }
    var inputType = bodyArguments.joined(separator: ", ")
    let bodyReturnClause: String
    let outputType: TypeSyntax
    if let returnClause = signature.returnClause {
      outputType = returnClause.type.trimmed
      signature.returnClause?.type = (functionRepresentation?.returnClause ?? returnClause).type
        .asQueryExpression()
      bodyReturnClause = " \(returnClause.trimmedDescription)"
    } else {
      outputType = "Void"
      bodyReturnClause = " -> Void"
    }
    let bodyType = """
      (\(inputType))\
      \(declaration.signature.effectSpecifiers?.trimmedDescription ?? "")\
      \(bodyReturnClause)
      """
    // TODO: Diagnose 'asyncClause'?
    signature.effectSpecifiers?.throwsClause = nil

    var invocationBody = """
      \(functionRepresentation?.returnClause.type ?? outputType)(
      queryOutput: self.body(\
      \(argumentBindings.map { name, _ in "\(name).queryOutput" }.joined(separator: ", "))\
      )
      )
      .queryBinding
      """
    if declaration.signature.effectSpecifiers?.throwsClause != nil {
      invocationBody = """
        do {
        return try \(invocationBody)
        } catch {
        return .invalid(error)
        }
        """
    } else {
      invocationBody = "return \(invocationBody)"
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
    inputType = bodyArguments.count == 1 ? inputType : "(\(inputType))"

    return [
      """
      \(attributes)\(access)\(`static`)var $\(raw: declarationName): \(functionTypeName) {
      \(functionTypeName)(\(declaration.name.trimmed))
      }
      """,
      """
      \(attributes)\(access)struct \(functionTypeName): \
      StructuredQueriesSQLiteCore.ScalarDatabaseFunction {
      public typealias Input = \(raw: inputType)
      public typealias Output = \(outputType)
      public let name = \(databaseFunctionName)
      public let argumentCount: Int? = \(raw: argumentCount)
      public let isDeterministic = \(raw: isDeterministic)
      public let body: \(raw: bodyType)
      public init(_ body: @escaping \(raw: bodyType)) {
      self.body = body
      }
      public func callAsFunction\(signature.trimmed) {
      StructuredQueriesCore.SQLQueryExpression(
      "\\(quote: self.name)(\(raw: parameters.map { "\\(\($0))" }.joined(separator: ", ")))"
      )
      }
      public func invoke(
      _ arguments: [StructuredQueriesCore.QueryBinding]
      ) -> StructuredQueriesCore.QueryBinding {
      guard self.argumentCount == nil || self.argumentCount == arguments.count\
      \(raw: argumentBindings.map { ", let \($0) = \($1)" }.joined()) \
      else {
      return .invalid(InvalidInvocation())
      }
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
