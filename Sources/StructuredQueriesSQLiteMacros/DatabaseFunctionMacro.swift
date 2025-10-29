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

    var decodings: [String] = []
    var decodingUnwrappings: [String] = []
    var canThrowInvalidInvocation = false

    let isAggregate: Bool
    var representableInputType: String
    var rowType = ""
    let projectedCallSyntax: ExprSyntax

    if signature.parameterClause.parameters.count == 1,
      let parameter = signature.parameterClause.parameters.first,
      var someOrAnyParameterType = parameter.type.as(SomeOrAnyTypeSyntax.self),
      someOrAnyParameterType.someOrAnySpecifier.tokenKind == .keyword(.some),
      let parameterType = someOrAnyParameterType.constraint.as(IdentifierTypeSyntax.self),
      ["Sequence", "Swift.Sequence"].contains(parameterType.name.text),
      let genericArgumentClause = parameterType.genericArgumentClause,
      genericArgumentClause.arguments.count == 1,
      let genericArgument = genericArgumentClause.arguments.first
    {
      isAggregate = true

      someOrAnyParameterType.someOrAnySpecifier.tokenKind = .keyword(.any)
      let bodySignature =
        signature
        .with(
          \.parameterClause.parameters[signature.parameterClause.parameters.startIndex],
          parameter
            .with(\.firstName, .wildcardToken(trailingTrivia: .space))
            .with(\.type, TypeSyntax(someOrAnyParameterType))
        )
      bodyArguments.append("\(bodySignature.parameterClause.parameters)")

      var parameterClause = signature.parameterClause.with(\.parameters, [])
      let firstName = parameter.firstName.tokenKind == .wildcard ? nil : parameter.firstName

      let tupleType =
        genericArgument.argument.as(TupleTypeSyntax.self)
        ?? TupleTypeSyntax(
          elements: [
            TupleTypeElementSyntax(
              firstName: firstName,
              secondName: parameter.secondName,
              type: genericArgument.argument.cast(TypeSyntax.self)
            )
          ]
        )

      let representableInputGeneric = functionRepresentation?
        .parameters.first?
        .type.as(SomeOrAnyTypeSyntax.self)?
        .constraint.as(IdentifierTypeSyntax.self)?
        .genericArgumentClause?
        .arguments.first
      let representableInputGenericArgument = representableInputGeneric?.argument

      representableInputType = "\(representableInputGeneric ?? genericArgument)"
      rowType = "\(genericArgument)"

      let representableInputArguments =
        representableInputGenericArgument?.as(TupleTypeSyntax.self)?.elements.map(\.type)
        ?? (representableInputGenericArgument?.cast(TypeSyntax.self)).map { [$0] }
      var representableInputArgumentsIterator = representableInputArguments?.makeIterator()

      var offset = 0
      for var element in tupleType.elements {
        defer { offset += 1 }
        var type = representableInputArgumentsIterator?.next() ?? element.type
        element.type = type.asQueryExpression()
        type = type.trimmed
        representableInputTypes.append(type.description)
        invocationArgumentTypes.append(type)
        let firstName = element.firstName?.trimmedDescription
        let secondName = element.secondName?.trimmedDescription ?? firstName ?? "p\(offset)"
        parameters.append(secondName)
        argumentBindings.append(secondName)

        argumentCounts.append("\(type)")
        decodings.append(
          "let \(secondName) = try decoder.decode(_requireQueryRepresentable(\(type).self))"
        )
        decodingUnwrappings.append(
          "guard let \(secondName) else { throw InvalidInvocation() }"
        )
        canThrowInvalidInvocation = true

        parameterClause.parameters.append(
          FunctionParameterSyntax(
            firstName: firstName.map { .identifier($0) } ?? .wildcardToken(),
            secondName: firstName == secondName
              ? nil
              : .identifier(secondName, leadingTrivia: .space),
            colon: .colonToken(),
            type: element.type,
            trailingComma: .commaToken(),
            trailingTrivia: .space
          )
        )
      }
      parameterClause.parameters.append(
        FunctionParameterSyntax(
          firstName: "order",
          colon: .colonToken(),
          type: "(some QueryExpression)?" as TypeSyntax,
          defaultValue: InitializerClauseSyntax(
            equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
            value: "Bool?.none" as ExprSyntax
          ),
          trailingComma: .commaToken(),
          trailingTrivia: .space
        )
      )
      parameterClause.parameters.append(
        FunctionParameterSyntax(
          firstName: "filter",
          colon: .colonToken(trailingTrivia: .space),
          type: "(some QueryExpression<Bool>)?" as TypeSyntax,
          defaultValue: InitializerClauseSyntax(
            equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
            value: "Bool?.none" as ExprSyntax
          )
        )
      )
      signature.parameterClause = parameterClause
      projectedCallSyntax = """
        \(functionTypeName) {
        \(raw: declaration.signature.effectSpecifiers?.throwsClause != nil ? "try " : "")\
        \(declaration.name.trimmed)(\(raw: firstName.map { "\($0.trimmedDescription): " } ?? "")$0)
        }
        """
    } else {
      isAggregate = false
      var functionRepresentationIterator = functionRepresentation?.parameters.makeIterator()

      for index in signature.parameterClause.parameters.indices {
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
        decodings.append(
          "let \(parameterName) = try decoder.decode(_requireQueryRepresentable(\(type).self))"
        )
        decodingUnwrappings.append("guard let \(parameterName) else { throw InvalidInvocation() }")
        canThrowInvalidInvocation = true
      }
      representableInputType = representableInputTypes.joined(separator: ", ")
      representableInputType =
        representableInputTypes.count == 1
        ? representableInputType
        : "(\(representableInputType))"
      projectedCallSyntax = "\(functionTypeName)(\(declaration.name.trimmed))"
    }
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
    // TODO: Diagnose 'asyncClause'?
    signature.effectSpecifiers?.throwsClause = nil

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

    let argumentCount =
      argumentCounts.isEmpty
      ? "0"
      : """
      var argumentCount = 0
      \(argumentCounts.map { "argumentCount += _columnWidth(\($0).self)\n" }.joined())\
      return argumentCount
      """

    var methods: [DeclSyntax] = []
    if isAggregate {
      var parameter = declaration.signature.parameterClause.parameters[
        declaration.signature.parameterClause.parameters.startIndex
      ]
      parameter.firstName = .wildcardToken(trailingTrivia: .space)
      parameter.secondName = "arguments"

      methods.append(
        """
        public func callAsFunction\(signature.trimmed) {
        StructuredQueriesCore.$_isSelecting.withValue(false) {
        StructuredQueriesCore.AggregateFunctionExpression(
        self.name, \
        \(raw: parameters.joined(separator: ", ")), \
        order: order, \
        filter: filter
        )
        }
        }
        """
      )

      let stepReturnClause: String
      switch parameters.count {
      case 0: stepReturnClause = ""
      case 1: stepReturnClause = "return \(parameters[0])\n"
      default: stepReturnClause = "return (\(parameters.joined(separator: ", ")))\n"
      }

      methods.append(
        """
        public func step(
        _ decoder: inout some QueryDecoder
        ) throws -> \(raw: rowType) {
        \(raw: (decodings + decodingUnwrappings).map { "\($0)\n" }.joined())\
        \(raw: stepReturnClause)\
        }
        """
      )

      let bodyInvocation = """
        \(declaration.signature.effectSpecifiers?.throwsClause != nil ? "try " : "")\
        self.body(arguments)
        """
      var invocationBody =
        isVoidReturning
        ? """
        \(bodyInvocation)
        return .null
        """
        : "return \(representableOutputType)(queryOutput: \(bodyInvocation)).queryBinding"
      if declaration.signature.effectSpecifiers?.throwsClause != nil {
        invocationBody = """
          do {
          \(invocationBody)
          } catch {
          return .invalid(error)
          }
          """
      }
      methods.append(
        """
        public func invoke(\(parameter)) -> QueryBinding {
        \(raw: invocationBody)
        }
        """
      )
    } else {
      methods.append(
        """
        public func callAsFunction\(signature.trimmed) {
        StructuredQueriesCore.$_isSelecting.withValue(false) {
        StructuredQueriesCore.SQLQueryExpression(
        "\\(quote: self.name)(\(raw: parameters.map { "\\(\($0))" }.joined(separator: ", ")))"
        )
        }
        }
        """
      )

      let bodyInvocation = """
        \(declaration.signature.effectSpecifiers?.throwsClause != nil ? "try " : "")self.body(\
        \(argumentBindings.joined(separator: ", "))\
        )
        """
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

      methods.append(
        """
        public func invoke(
        _ decoder: inout some QueryDecoder
        ) throws -> StructuredQueriesCore.QueryBinding {
        \(raw: (decodings + decodingUnwrappings).map { "\($0)\n" }.joined())\
        \(raw: invocationBody)
        }
        """
      )
    }

    return [
      """
      \(attributes)\(access)\(`static`)\(nonisolated)var $\(raw: declarationName): \
      \(functionTypeName) {
      \(projectedCallSyntax)
      }
      """,
      """
      \(attributes)\(access)\(nonisolated)struct \(functionTypeName): \
      StructuredQueriesSQLiteCore.\(raw: isAggregate ? "Aggregate" : "Scalar")DatabaseFunction {
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
      \(raw: methods.map(\.description).joined(separator: "\n"))\
      \(raw: canThrowInvalidInvocation ? "\nprivate struct InvalidInvocation: Error {}" : "")
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
