import SwiftBasicFormat
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum TableMacro {}

extension TableMacro: ExtensionMacro {
  public static func expansion<D: DeclGroupSyntax, T: TypeSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    attachedTo declaration: D,
    providingExtensionsOf type: T,
    conformingTo protocols: [TypeSyntax],
    in context: C
  ) throws -> [ExtensionDeclSyntax] {
    guard
      let declaration = declaration.as(StructDeclSyntax.self)
    else {
      context.diagnose(
        Diagnostic(
          node: declaration.introducer,
          message: MacroExpansionErrorMessage("'@Table' can only be applied to struct types")
        )
      )
      return []
    }
    var allColumns: [TokenSyntax] = []
    var columnsProperties: [DeclSyntax] = []
    var decodings: [String] = []
    var decodingUnwrappings: [String] = []
    var decodingAssignments: [String] = []
    var diagnostics: [Diagnostic] = []

    // NB: A compiler bug prevents us from applying the '@_Draft' macro directly
    var draftBindings: [(PatternBindingSyntax, queryOutputType: TypeSyntax?, optionalize: Bool)] =
      []
    // NB: End of workaround

    var draftProperties: [DeclSyntax] = []
    var draftTableType: TypeSyntax?
    var primaryKey:
      (
        identifier: TokenSyntax,
        label: TokenSyntax?,
        queryOutputType: TypeSyntax?,
        queryValueType: TypeSyntax?
      )?
    let selfRewriter = SelfRewriter(
      selfEquivalent: type.as(IdentifierTypeSyntax.self)?.name ?? "QueryValue"
    )
    var schemaName: ExprSyntax?
    var tableName = ExprSyntax(
      StringLiteralExprSyntax(
        content: declaration.name.trimmed.text.lowerCamelCased().pluralized()
      )
    )
    if case .argumentList(let arguments) = node.arguments {
      for argumentIndex in arguments.indices {
        let argument = arguments[argumentIndex]
        switch argument.label {
        case nil:
          if node.attributeName.identifier == "_Draft" {
            let memberAccess = argument.expression.cast(MemberAccessExprSyntax.self)
            let base = memberAccess.base!.trimmed
            draftTableType = TypeSyntax("\(base)")
            tableName = "\(base).tableName"
          } else {
            if !argument.expression.isNonEmptyStringLiteral {
              diagnostics.append(
                Diagnostic(
                  node: argument.expression,
                  message: MacroExpansionErrorMessage("Argument must be a non-empty string literal")
                )
              )
            }
            tableName = argument.expression.trimmed
          }

        case .some(let label) where label.text == "schema":
          if node.attributeName.identifier == "_Draft" {
            let memberAccess = argument.expression.cast(MemberAccessExprSyntax.self)
            let base = memberAccess.base!.trimmed
            draftTableType = TypeSyntax("\(base)")
            schemaName = "\(base).schemaName"
          } else {
            if !argument.expression.isNonEmptyStringLiteral {
              diagnostics.append(
                Diagnostic(
                  node: argument.expression,
                  message: MacroExpansionErrorMessage("Argument must be a non-empty string literal")
                )
              )
            }
            schemaName = argument.expression.trimmed
          }

        case let argument?:
          fatalError("Unexpected argument: \(argument)")
        }
      }
    }
    for member in declaration.memberBlock.members {
      guard
        let property = member.decl.as(VariableDeclSyntax.self),
        !property.isStatic,
        !property.isComputed,
        property.bindings.count == 1,
        let binding = property.bindings.first,
        let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed
      else { continue }

      var columnName = ExprSyntax(
        StringLiteralExprSyntax(content: identifier.text.trimmingBackticks())
      )
      var columnQueryValueType =
        (binding.typeAnnotation?.type.trimmed
        ?? binding.initializer?.value.literalType)
        .map { $0.rewritten(selfRewriter) }
      var columnQueryOutputType = columnQueryValueType
      var isPrimaryKey = primaryKey == nil && identifier.text == "id"
      var isEphemeral = false
      var isGenerated = false

      for attribute in property.attributes {
        guard
          let attribute = attribute.as(AttributeSyntax.self),
          let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
        else { continue }
        isEphemeral = isEphemeral || attributeName == "Ephemeral"
        guard
          attributeName == "Column" || isEphemeral,
          case .argumentList(let arguments) = attribute.arguments
        else { continue }

        for argumentIndex in arguments.indices {
          let argument = arguments[argumentIndex]

          switch argument.label {
          case nil:
            if !argument.expression.isNonEmptyStringLiteral {
              diagnostics.append(
                Diagnostic(
                  node: argument.expression,
                  message: MacroExpansionErrorMessage("Argument must be a non-empty string literal")
                )
              )
            }
            columnName = argument.expression

          case .some(let label) where label.text == "as":
            guard
              let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.tokenKind == .keyword(.self),
              let base = memberAccess.base
            else {
              diagnostics.append(
                Diagnostic(
                  node: argument.expression,
                  message: MacroExpansionErrorMessage("Argument 'as' must be a type literal")
                )
              )
              continue
            }

            columnQueryValueType = "\(raw: base.rewritten(selfRewriter).trimmedDescription)"
            columnQueryOutputType = "\(columnQueryValueType).QueryOutput"

          case .some(let label) where label.text == "primaryKey":
            guard
              argument.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind
                == .keyword(.true)
            else {
              isPrimaryKey = false
              break
            }
            if let primaryKey, let originalLabel = primaryKey.label {
              var newArguments = arguments
              newArguments.remove(at: argumentIndex)
              diagnostics.append(
                Diagnostic(
                  node: label,
                  message: MacroExpansionErrorMessage(
                    "'@Table' only supports a single primary key"
                  ),
                  notes: [
                    Note(
                      node: Syntax(originalLabel),
                      position: originalLabel.position,
                      message: MacroExpansionNoteMessage(
                        "Primary key already applied to '\(primaryKey.identifier)'"
                      )
                    )
                  ],
                  fixIt: .replace(
                    message: MacroExpansionFixItMessage("Remove 'primaryKey: true'"),
                    oldNode: Syntax(attribute),
                    newNode: Syntax(attribute.with(\.arguments, .argumentList(newArguments)))
                  )
                )
              )
            }
            primaryKey = (
              identifier: identifier,
              label: label,
              queryOutputType: columnQueryOutputType,
              queryValueType: columnQueryValueType
            )

          case .some(let label) where label.text == "generated":
            guard
              let memberName = argument.expression.as(MemberAccessExprSyntax.self)?.declName
                .baseName.text,
              ["stored", "virtual"].contains(memberName)
            else {
              continue
            }
            guard property.bindingSpecifier.tokenKind == .keyword(.let)
            else {
              diagnostics.append(
                Diagnostic(
                  node: property.bindingSpecifier,
                  message: MacroExpansionErrorMessage(
                    "Generated column property must be declared with a 'let'"
                  ),
                  fixIt: .replace(
                    message: MacroExpansionFixItMessage("Replace 'var' with 'let'"),
                    oldNode: Syntax(property.bindingSpecifier),
                    newNode: Syntax(
                      property.bindingSpecifier.with(\.tokenKind, .keyword(.let))
                    )
                  )
                )
              )
              continue
            }
            isGenerated = true

          case let argument?:
            fatalError("Unexpected argument: \(argument)")
          }
        }
      }
      guard !isEphemeral
      else { continue }

      if isPrimaryKey {
        primaryKey = (
          identifier: identifier,
          label: nil,
          queryOutputType: columnQueryOutputType,
          queryValueType: columnQueryValueType
        )
      }

      if !isGenerated {
        // NB: A compiler bug prevents us from applying the '@_Draft' macro directly
        draftBindings.append((binding, columnQueryOutputType, identifier == primaryKey?.identifier))
        // NB: End of workaround
      }

      var assignedType: String? {
        binding
          .initializer?
          .value
          .as(FunctionCallExprSyntax.self)?
          .calledExpression
          .as(DeclReferenceExprSyntax.self)?
          .baseName
          .text
      }

      let defaultValue = binding.initializer?.value.rewritten(selfRewriter)
      if isGenerated {
        columnsProperties.append(
          """
          public var \(identifier): \(moduleName).GeneratedColumn<\
          QueryValue, \
          \(raw: columnQueryValueType?.trimmedDescription ?? "_")\
          > {
          \(moduleName).GeneratedColumn<\
          QueryValue, \
          \(columnQueryValueType?.rewritten(selfRewriter) ?? "_")\
          >(\
          \(columnName), \
          keyPath: \\QueryValue.\(identifier))
          }
          """
        )
      } else {
        columnsProperties.append(
          """
          public let \(identifier) = \(moduleName).TableColumn<\
          QueryValue, \
          \(columnQueryValueType?.rewritten(selfRewriter) ?? "_")\
          >(\
          \(columnName), \
          keyPath: \\QueryValue.\(identifier)\((defaultValue?.trimmedDescription).map { ", default: \($0)" } ?? "")\
          )
          """
        )
        allColumns.append(identifier)
      }
      let decodedType = columnQueryValueType?.asNonOptionalType()
      if let defaultValue {
        decodings.append(
          """
          self.\(identifier) = try decoder.decode(\(decodedType.map { "\($0).self" } ?? "")) \
          ?? \(defaultValue)
          """
        )
      } else if columnQueryValueType.map({ $0.isOptionalType }) ?? false {
        decodings.append(
          """
          self.\(identifier) = try decoder.decode(\(decodedType.map { "\($0).self" } ?? ""))
          """
        )
      } else {
        decodings.append(
          """
          let \(identifier) = try decoder.decode(\(decodedType.map { "\($0).self" } ?? ""))
          """
        )
        decodingUnwrappings.append(
          """
          guard let \(identifier) else { throw QueryDecodingError.missingRequiredColumn }
          """
        )
        decodingAssignments.append(
          """
          self.\(identifier) = \(identifier)
          """
        )
      }

      if !isGenerated {
        if let primaryKey, primaryKey.identifier == identifier {
          var hasColumnAttribute = false
          var property = property
          for attributeIndex in property.attributes.indices {
            guard
              var attribute = property.attributes[attributeIndex].as(AttributeSyntax.self),
              let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
              attributeName == "Column",
              case .argumentList(var arguments) = attribute.arguments
            else { continue }
            hasColumnAttribute = true
            var hasPrimaryKeyArgument = false
            for argumentIndex in arguments.indices {
              var argument = arguments[argumentIndex]
              defer { arguments[argumentIndex] = argument }
              switch argument.label?.text {
              case "as":
                if var expression = argument.expression.as(MemberAccessExprSyntax.self) {
                  expression.base = "\(expression.base)?"
                  argument.expression = ExprSyntax(expression)
                }

              case "primaryKey":
                hasPrimaryKeyArgument = true
                argument.expression = ExprSyntax(BooleanLiteralExprSyntax(false))

              default:
                break
              }
            }
            if !hasPrimaryKeyArgument {
              arguments[arguments.index(before: arguments.endIndex)].trailingComma = .commaToken(
                trailingTrivia: .space
              )
              arguments.append(
                LabeledExprSyntax(
                  label: "primaryKey",
                  expression: BooleanLiteralExprSyntax(false)
                )
              )
            }
            attribute.arguments = .argumentList(arguments)
            property.attributes[attributeIndex] = .attribute(attribute)
          }
          if !hasColumnAttribute {
            let attribute = "@Column(primaryKey: false)\n"
            property.attributes.insert(
              AttributeListSyntax.Element("\(raw: attribute)"),
              at: property.attributes.startIndex
            )
          }
          var binding = binding
          if let type = binding.typeAnnotation?.type.asOptionalType() {
            binding.typeAnnotation?.type = type
          }
          property.bindings = [binding]
          draftProperties.append(
            DeclSyntax(
              property.trimmed
                .with(\.bindingSpecifier.leadingTrivia, "")
                .removingAccessors()
                .rewritten(selfRewriter)
            )
          )
        } else {
          draftProperties.append(
            DeclSyntax(
              property.trimmed
                .with(\.bindingSpecifier.leadingTrivia, "")
                .removingAccessors()
                .rewritten(selfRewriter)
            )
          )
        }
      }
    }

    var draft: DeclSyntax?
    var initFromOther: DeclSyntax?
    if let draftTableType {
      initFromOther = """

        public \(nonisolated)init(_ other: \(draftTableType)) {
        \(allColumns.map { "self.\($0) = other.\($0)" as ExprSyntax }, separator: "\n")
        }
        """
    } else if let primaryKey {
      columnsProperties.append(
        """
        public var primaryKey: \(moduleName).TableColumn<QueryValue, \(primaryKey.queryValueType)> \
        { self.\(primaryKey.identifier) }
        """
      )
      draft = """

        @_Draft(\(type).self)
        public struct Draft {
        \(draftProperties, separator: "\n")
        }
        """

      // NB: A compiler bug prevents us from applying the '@_Draft' macro directly
      var memberBlocks = try expansion(
        of: "@_Draft(\(type).self)",
        providingMembersOf: StructDeclSyntax("\(draft)"),
        conformingTo: [],
        in: context
      )
      .compactMap(\.trimmed)
      memberBlocks.append(
        contentsOf: try expansion(
          of: "@_Draft(\(type).self)",
          attachedTo: StructDeclSyntax("\(draft)"),
          providingExtensionsOf: TypeSyntax("\(type).Draft"),
          conformingTo: [],
          in: context
        )
        .flatMap {
          $0.memberBlock.members.trimmed.map(\.decl)
        }
      )
      var memberwiseArguments: [PatternBindingSyntax] = []
      var memberwiseAssignments: [TokenSyntax] = []
      for (binding, queryOutputType, optionalize) in draftBindings {
        var argument = binding.trimmed
        if optionalize {
          argument = argument.optionalized()
        }
        argument = argument.annotated(queryOutputType).rewritten(selfRewriter)
        if argument.typeAnnotation == nil {
          let identifier =
            (argument.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmedDescription)
            .map { "'\($0)'" }
            ?? "field"
          diagnostics.append(
            Diagnostic(
              node: binding,
              message: MacroExpansionErrorMessage(
                """
                '@Table' requires \(identifier) to have a type annotation in order to generate a \
                memberwise initializer
                """
              ),
              fixIts: [
                FixIt(
                  message: MacroExpansionFixItMessage(
                    """
                    Insert ': <#Type#>'
                    """
                  ),
                  changes: [
                    .replace(
                      oldNode: Syntax(binding),
                      newNode: Syntax(
                        binding
                          .with(\.pattern.trailingTrivia, "")
                          .with(
                            \.typeAnnotation,
                            TypeAnnotationSyntax(
                              colon: .colonToken(trailingTrivia: .space),
                              type: IdentifierTypeSyntax(name: "<#Type#>"),
                              trailingTrivia: .space
                            )
                          )
                      )
                    )
                  ]
                )
              ]
            )
          )
          continue
        }
        memberwiseArguments.append(argument)
        memberwiseAssignments.append(
          argument.trimmed.pattern.cast(IdentifierPatternSyntax.self).identifier
        )
      }
      let memberwiseInit: DeclSyntax = """
        public init(
        \(memberwiseArguments, separator: ",\n")
        ) {
        \(memberwiseAssignments.map { "self.\($0) = \($0)" as ExprSyntax }, separator: "\n")
        }
        """
      draft = """

        public struct Draft: \(moduleName).TableDraft {
        public typealias PrimaryTable = \(type)
        \(draftProperties, separator: "\n")
        \(memberBlocks, separator: "\n")
        \(memberwiseInit)
        }
        """
      // NB: End of workaround
    }

    var conformances: [TypeSyntax] = []
    let protocolNames: [TokenSyntax] =
      primaryKey != nil
      ? ["Table", "PrimaryKeyedTable"]
      : ["Table"]
    if let inheritanceClause = declaration.inheritanceClause {
      for type in protocolNames {
        if !inheritanceClause.inheritedTypes.contains(where: {
          [type.text, "\(moduleName).\(type)"].contains($0.type.trimmedDescription)
        }) {
          conformances.append("\(moduleName).\(type)")
        }
      }
    } else {
      conformances = protocolNames.map { "\(moduleName).\($0)" }
    }

    if columnsProperties.isEmpty {
      diagnostics.append(
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            """
            '@Table' requires at least one stored column property to be defined on '\(type)'
            """
          )
        )
      )
    }

    guard diagnostics.isEmpty else {
      diagnostics.forEach(context.diagnose)
      return []
    }

    var statics: [DeclSyntax] = []
    var letSchemaName: DeclSyntax?
    if let schemaName {
      letSchemaName = """

        public \(nonisolated)static let schemaName: Swift.String? = \(schemaName)
        """
    }
    var initDecoder: DeclSyntax?
    if declaration.hasMacroApplication("Selection") {
      conformances.append("\(moduleName).PartialSelectStatement")
      statics.append(contentsOf: [
        """

        public typealias QueryValue = Self
        """,
        """
        public typealias From = Swift.Never
        """,
      ])
    } else {
      initDecoder = """

        public \(nonisolated)init(decoder: inout some \(moduleName).QueryDecoder) throws {
        \(raw: (decodings + decodingUnwrappings + decodingAssignments).joined(separator: "\n"))
        }
        """
    }

    return [
      DeclSyntax(
        """
        \(declaration.attributes.availability)\(nonisolated)extension \(type)\
        \(conformances.isEmpty ? "" : ": \(conformances, separator: ", ")") {\
        \(statics, separator: "\n")
        public \(nonisolated)static var columns: TableColumns { TableColumns() }
        public \(nonisolated)static var tableName: String { \(tableName) }\(letSchemaName)\(initDecoder)\(initFromOther)
        }
        """
      )
      .cast(ExtensionDeclSyntax.self)
    ]
  }
}

extension TableMacro: MemberMacro {
  public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingMembersOf declaration: D,
    conformingTo protocols: [TypeSyntax],
    in context: C
  ) throws -> [DeclSyntax] {
    guard
      let declaration = declaration.as(StructDeclSyntax.self)
    else {
      return []
    }
    let type = IdentifierTypeSyntax(name: declaration.name.trimmed)
    var allColumns: [TokenSyntax] = []
    var writableColumns: [TokenSyntax] = []
    var selectedColumns: [TokenSyntax] = []
    var columnsProperties: [DeclSyntax] = []
    var decodings: [String] = []
    var decodingUnwrappings: [String] = []
    var decodingAssignments: [String] = []
    var expansionFailed = false

    // NB: A compiler bug prevents us from applying the '@_Draft' macro directly
    var draftBindings: [(PatternBindingSyntax, queryOutputType: TypeSyntax?, optionalize: Bool)] =
      []
    // NB: End of workaround

    var draftProperties: [DeclSyntax] = []
    var primaryKey:
      (
        identifier: TokenSyntax,
        label: TokenSyntax?,
        queryOutputType: TypeSyntax?,
        queryValueType: TypeSyntax?
      )?
    let selfRewriter = SelfRewriter(selfEquivalent: type.name)
    for member in declaration.memberBlock.members {
      guard
        let property = member.decl.as(VariableDeclSyntax.self),
        !property.isStatic,
        !property.isComputed,
        property.bindings.count == 1,
        let binding = property.bindings.first,
        let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed
      else { continue }

      var columnName = ExprSyntax(
        StringLiteralExprSyntax(content: identifier.text.trimmingBackticks())
      )
      var columnQueryValueType =
        (binding.typeAnnotation?.type.trimmed
        ?? binding.initializer?.value.literalType)
        .map { $0.rewritten(selfRewriter) }
      var columnQueryOutputType = columnQueryValueType
      var isPrimaryKey = primaryKey == nil && identifier.text == "id"
      var isEphemeral = false
      var isGenerated = false

      for attribute in property.attributes {
        guard
          let attribute = attribute.as(AttributeSyntax.self),
          let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
        else { continue }
        isEphemeral = isEphemeral || attributeName == "Ephemeral"
        guard
          attributeName == "Column" || isEphemeral,
          case .argumentList(let arguments) = attribute.arguments
        else { continue }

        for argumentIndex in arguments.indices {
          let argument = arguments[argumentIndex]

          switch argument.label {
          case nil:
            if !argument.expression.isNonEmptyStringLiteral {
              expansionFailed = true
            }
            columnName = argument.expression

          case .some(let label) where label.text == "as":
            guard
              let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.tokenKind == .keyword(.self),
              let base = memberAccess.base
            else {
              expansionFailed = true
              continue
            }

            columnQueryValueType = "\(raw: base.rewritten(selfRewriter).trimmedDescription)"
            columnQueryOutputType = "\(columnQueryValueType).QueryOutput"

          case .some(let label) where label.text == "primaryKey":
            guard
              argument.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind
                == .keyword(.true)
            else {
              isPrimaryKey = false
              break
            }
            if primaryKey != nil {
              var newArguments = arguments
              newArguments.remove(at: argumentIndex)
              expansionFailed = true
            }
            primaryKey = (
              identifier: identifier,
              label: label,
              queryOutputType: columnQueryOutputType,
              queryValueType: columnQueryValueType
            )

          case .some(let label) where label.text == "generated":
            guard
              let memberName = argument.expression.as(MemberAccessExprSyntax.self)?.declName
                .baseName.text,
              ["stored", "virtual"].contains(memberName)
            else { continue }
            isGenerated = true

          case let argument?:
            fatalError("Unexpected argument: \(argument)")
          }
        }
      }
      guard !isEphemeral
      else { continue }

      if isPrimaryKey {
        primaryKey = (
          identifier: identifier,
          label: nil,
          queryOutputType: columnQueryOutputType,
          queryValueType: columnQueryValueType
        )
      }

      selectedColumns.append(identifier)

      if !isGenerated {
        // NB: A compiler bug prevents us from applying the '@_Draft' macro directly
        draftBindings.append((binding, columnQueryOutputType, identifier == primaryKey?.identifier))
        // NB: End of workaround
      }

      var assignedType: String? {
        binding
          .initializer?
          .value
          .as(FunctionCallExprSyntax.self)?
          .calledExpression
          .as(DeclReferenceExprSyntax.self)?
          .baseName
          .text
      }

      let defaultValue = binding.initializer?.value.rewritten(selfRewriter)
      if isGenerated {
        columnsProperties.append(
          """
          public var \(identifier): \(moduleName).GeneratedColumn<\
          QueryValue, \
          \(raw: columnQueryValueType?.trimmedDescription ?? "_")\
          > { \
          \(moduleName).GeneratedColumn<\
          QueryValue, \
          \(columnQueryValueType?.rewritten(selfRewriter) ?? "_")\
          >(\
          \(columnName), \
          keyPath: \\QueryValue.\(identifier)\
          )
          }
          """
        )
        allColumns.append(identifier)
      } else {
        columnsProperties.append(
          """
          public let \(identifier) = \(moduleName).TableColumn<\
          QueryValue, \
          \(columnQueryValueType?.rewritten(selfRewriter) ?? "_")\
          >(\
          \(columnName), \
          keyPath: \\QueryValue.\(identifier)\((defaultValue?.trimmedDescription).map { ", default: \($0)" } ?? "")\
          )
          """
        )
        allColumns.append(identifier)
        writableColumns.append(identifier)
      }
      let decodedType = columnQueryValueType?.asNonOptionalType()
      if let defaultValue {
        decodings.append(
          """
          self.\(identifier) = try decoder.decode(\(decodedType.map { "\($0).self" } ?? "")) \
          ?? \(defaultValue)
          """
        )
      } else if columnQueryValueType.map({ $0.isOptionalType }) ?? false {
        decodings.append(
          """
          self.\(identifier) = try decoder.decode(\(decodedType.map { "\($0).self" } ?? ""))
          """
        )
      } else {
        decodings.append(
          """
          let \(identifier) = try decoder.decode(\(decodedType.map { "\($0).self" } ?? ""))
          """
        )
        decodingUnwrappings.append(
          """
          guard let \(identifier) else { throw QueryDecodingError.missingRequiredColumn }
          """
        )
        decodingAssignments.append(
          """
          self.\(identifier) = \(identifier)
          """
        )
      }

      if !isGenerated {
        if let primaryKey, primaryKey.identifier == identifier {
          var hasColumnAttribute = false
          var property = property
          for attributeIndex in property.attributes.indices {
            guard
              var attribute = property.attributes[attributeIndex].as(AttributeSyntax.self),
              let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
              attributeName == "Column",
              case .argumentList(var arguments) = attribute.arguments
            else { continue }
            hasColumnAttribute = true
            var hasPrimaryKeyArgument = false
            for argumentIndex in arguments.indices {
              var argument = arguments[argumentIndex]
              defer { arguments[argumentIndex] = argument }
              switch argument.label?.text {
              case "as":
                if var expression = argument.expression.as(MemberAccessExprSyntax.self) {
                  expression.base = "\(expression.base)?"
                  argument.expression = ExprSyntax(expression)
                }

              case "primaryKey":
                hasPrimaryKeyArgument = true
                argument.expression = ExprSyntax(BooleanLiteralExprSyntax(false))

              default:
                break
              }
            }
            if !hasPrimaryKeyArgument {
              arguments[arguments.index(before: arguments.endIndex)].trailingComma = .commaToken(
                trailingTrivia: .space
              )
              arguments.append(
                LabeledExprSyntax(
                  label: "primaryKey",
                  expression: BooleanLiteralExprSyntax(false)
                )
              )
            }
            attribute.arguments = .argumentList(arguments)
            property.attributes[attributeIndex] = .attribute(attribute)
          }
          property = property.trimmed
          if !hasColumnAttribute {
            let attribute = "@Column(primaryKey: false)\n"
            property.attributes.insert(
              AttributeListSyntax.Element("\(raw: attribute)"),
              at: property.attributes.startIndex
            )
          }
          var binding = binding
          if let type = binding.typeAnnotation?.type.asOptionalType() {
            binding.typeAnnotation?.type = type
          }
          property.bindings = [binding]
          draftProperties.append(
            DeclSyntax(
              property
                .with(\.bindingSpecifier.leadingTrivia, "")
                .removingAccessors()
                .rewritten(selfRewriter)
            )
          )
        } else {
          draftProperties.append(
            DeclSyntax(
              property.trimmed
                .with(\.bindingSpecifier.leadingTrivia, "")
                .removingAccessors()
                .rewritten(selfRewriter)
            )
          )
        }
      }
    }

    var draft: DeclSyntax?
    if let primaryKey {
      columnsProperties.append(
        """
        public var primaryKey: \(moduleName).TableColumn<QueryValue, \(primaryKey.queryValueType)> \
        { self.\(primaryKey.identifier) }
        """
      )
      draft = """

        @_Draft(\(type).self)
        public struct Draft {
        \(draftProperties, separator: "\n")
        }
        """

      // NB: A compiler bug prevents us from applying the '@_Draft' macro directly
      var memberBlocks = try expansion(
        of: "@_Draft(\(type).self)",
        providingMembersOf: StructDeclSyntax("\(draft)"),
        conformingTo: [],
        in: context
      )
      .compactMap(\.trimmed)
      memberBlocks.append(
        contentsOf: try expansion(
          of: "@_Draft(\(type).self)",
          attachedTo: StructDeclSyntax("\(draft)"),
          providingExtensionsOf: TypeSyntax("\(type).Draft"),
          conformingTo: [],
          in: context
        )
        .flatMap {
          $0.memberBlock.members.trimmed.map(\.decl)
        }
      )
      var memberwiseArguments: [PatternBindingSyntax] = []
      var memberwiseAssignments: [TokenSyntax] = []
      for (binding, queryOutputType, optionalize) in draftBindings {
        var argument = binding.trimmed
        if optionalize {
          argument = argument.optionalized()
        }
        argument = argument.annotated(queryOutputType).rewritten(selfRewriter)
        if argument.typeAnnotation == nil {
          expansionFailed = true
          continue
        }
        memberwiseArguments.append(argument)
        memberwiseAssignments.append(
          argument.trimmed.pattern.cast(IdentifierPatternSyntax.self).identifier
        )
      }
      let memberwiseInit: DeclSyntax = """
        public init(
        \(memberwiseArguments, separator: ",\n")
        ) {
        \(memberwiseAssignments.map { "self.\($0) = \($0)" as ExprSyntax }, separator: "\n")
        }
        """
      draft = """

        public struct Draft: \(moduleName).TableDraft {
        public typealias PrimaryTable = \(type)
        \(draftProperties, separator: "\n")
        \(memberBlocks, separator: "\n")
        \(memberwiseInit)
        }
        """
      // NB: End of workaround
    }

    var conformances: [TypeSyntax] = []
    let protocolNames: [TokenSyntax] =
      primaryKey != nil
      ? ["Table", "PrimaryKeyedTable"]
      : ["Table"]
    let schemaConformances: [ExprSyntax] =
      primaryKey != nil
      ? ["\(moduleName).TableDefinition", "\(moduleName).PrimaryKeyedTableDefinition"]
      : ["\(moduleName).TableDefinition"]
    if let inheritanceClause = declaration.inheritanceClause {
      for type in protocolNames {
        if !inheritanceClause.inheritedTypes.contains(where: {
          [type.text, "\(moduleName).\(type)"].contains($0.type.trimmedDescription)
        }) {
          conformances.append("\(moduleName).\(type)")
        }
      }
    } else {
      conformances = protocolNames.map { "\(moduleName).\($0)" }
    }

    if columnsProperties.isEmpty {
      expansionFailed = true
    }

    guard !expansionFailed else {
      return []
    }

    var typeAliases: [DeclSyntax] = []
    if declaration.hasMacroApplication("Selection") {
      conformances.append("\(moduleName).PartialSelectStatement")
      typeAliases.append(contentsOf: [
        """

        public typealias QueryValue = Self
        """,
        """
        public typealias From = Swift.Never
        """,
      ])
    }

    return [
      """
      public \(nonisolated)struct TableColumns: \(schemaConformances, separator: ", ") {
      public typealias QueryValue = \(type.trimmed)
      \(columnsProperties, separator: "\n")
      public static var allColumns: [any \(moduleName).TableColumnExpression] { \
      [\(allColumns.map { "QueryValue.columns.\($0)" as ExprSyntax }, separator: ", ")]
      }
      public static var writableColumns: [any \(moduleName).WritableTableColumnExpression] { \
      [\(writableColumns.map { "QueryValue.columns.\($0)" as ExprSyntax }, separator: ", ")]
      }
      public var queryFragment: QueryFragment {
      "\(raw: selectedColumns.map { #"\(self.\#($0))"# }.joined(separator: ", "))"
      }
      }
      """,
      draft,
    ]
    .compactMap { $0 }
  }
}

extension TableMacro: MemberAttributeMacro {
  public static func expansion<D: DeclGroupSyntax, T: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    attachedTo declaration: D,
    providingAttributesFor member: T,
    in context: C
  ) throws -> [AttributeSyntax] {
    guard
      declaration.is(StructDeclSyntax.self),
      let property = member.as(VariableDeclSyntax.self),
      !property.isStatic,
      !property.isComputed,
      !property.hasMacroApplication("Column"),
      !property.hasMacroApplication("Ephemeral"),
      property.bindings.count == 1,
      let binding = property.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        .trimmingBackticks()
    else { return [] }
    if identifier == "id" {
      for member in declaration.memberBlock.members {
        guard
          let property = member.decl.as(VariableDeclSyntax.self),
          !property.isStatic,
          !property.isComputed
        else { continue }
        for attribute in property.attributes {
          guard
            let attribute = attribute.as(AttributeSyntax.self),
            let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
            attributeName == "Column",
            case .argumentList(let arguments) = attribute.arguments,
            arguments.contains(
              where: {
                $0.label?.text.trimmingBackticks() == "primaryKey"
                  && $0.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind
                    == .keyword(.true)
              }
            )
          else { continue }
          return [
            """
            @Column("\(raw: identifier)")
            """
          ]
        }
      }
    }
    return [
      """
      @Column("\(raw: identifier)"\(raw: identifier == "id" ? ", primaryKey: true" : ""))
      """
    ]
  }
}
