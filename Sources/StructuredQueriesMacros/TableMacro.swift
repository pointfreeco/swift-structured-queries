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
    if node.attributeName.identifier == "Selection",
      let tableNode = declaration.macroApplication(for: "Table")
    {
      context.diagnose(
        Diagnostic(
          node: node,
          message: MacroExpansionWarningMessage(
            """
            '@Table' and '@Selection' should not be applied together

            Apply '@Table' to types representing stored tables, virtual tables, and database views.

            Apply '@Selection' to types representing multiple columns that can be selected from a \
            table or query, and types that represent common table expressions.
            """
          ),
          fixIts: [
            .replace(
              message: MacroExpansionFixItMessage("Remove '@Selection'"),
              oldNode: node,
              newNode: TokenSyntax("")
            ),
            .replace(
              message: MacroExpansionFixItMessage("Remove '@Table'"),
              oldNode: tableNode,
              newNode: TokenSyntax("")
            ),
          ]
        )
      )
      return []
    }
    guard
      declaration.isTableMacroSupported,
      let declarationName = declaration.declarationName
    else {
      context.diagnose(
        Diagnostic(
          node: declaration.introducer,
          message: MacroExpansionErrorMessage(
            declaration.is(EnumDeclSyntax.self)
              ? """
              '@Table' can only be applied to enum types when the 'StructuredQueriesCasePaths' \
              package trait is enabled
              """
              : """
              '@Table' can only be applied to struct types (and enum types with the \
              'StructuredQueriesCasePaths' package trait enabled)
              """
          )
        )
      )
      return []
    }
    if declaration.is(EnumDeclSyntax.self), !declaration.hasMacroApplication("CasePathable") {
      var newAttributes: AttributeListSyntax = declaration.attributes
      newAttributes.insert(
        .attribute(
          AttributeSyntax(
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: "CasePathable"),
            trailingTrivia: .space
          )
        ),
        at: newAttributes.startIndex
      )
      context.diagnose(
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            """
            '@Table' enum type missing required '@CasePathable' macro application
            """
          ),
          fixIt: .replace(
            message: MacroExpansionFixItMessage(
              """
              Insert '@CasePathable'
              """
            ),
            oldNode: declaration.attributes,
            newNode: newAttributes
          )
        )
      )
      return []
    }

    var allColumns: [TokenSyntax] = []
    var columnsProperties: [DeclSyntax] = []
    var columnWidths: [ExprSyntax] = []
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
        queryValueType: TypeSyntax?,
        isColumnGroup: Bool
      )?
    let selfRewriter = SelfRewriter(
      selfEquivalent: type.as(IdentifierTypeSyntax.self)?.name ?? "QueryValue"
    )
    var schemaName: ExprSyntax?
    var tableName = ExprSyntax(
      StringLiteralExprSyntax(
        content: declarationName.trimmed.text.lowerCamelCased().pluralized()
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

    var initDecoder: DeclSyntax?
    if declaration.is(StructDeclSyntax.self) {
      var decodings: [String] = []
      var decodingUnwrappings: [String] = []
      var decodingAssignments: [String] = []
      for member in declaration.memberBlock.members {
        guard
          let property = member.decl.as(VariableDeclSyntax.self),
          !property.isStatic,
          !property.isComputed
        else { continue }
        guard
          // TODO: Support multi-binding variables where '@Column{,s}' macro is omitted?
          property.bindings.count == 1,
          let binding = property.bindings.first,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed
        else {
          diagnostics.append(
            Diagnostic(
              node: property,
              message: MacroExpansionErrorMessage(
                """
                Table property must contain a single value representing one or more columns
                """
              )
            )
          )
          continue
        }

        var columnName = ExprSyntax(
          StringLiteralExprSyntax(content: identifier.text.trimmingBackticks())
        )
        var columnQueryValueType =
          (binding.typeAnnotation?.type.trimmed
          ?? binding.initializer?.value.literalType)
          .map { $0.rewritten(selfRewriter) }
        var columnQueryOutputType = columnQueryValueType
        var isPrimaryKey = primaryKey == nil && identifier.text == "id"
        var isColumnGroup = false
        var isEphemeral = false
        var isExplicitColumn = false
        var isGenerated = false

        for attribute in property.attributes {
          guard
            let attribute = attribute.as(AttributeSyntax.self),
            let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
          else { continue }
          isColumnGroup = isColumnGroup || attributeName == "Columns"
          isEphemeral = isEphemeral || attributeName == "Ephemeral"
          isExplicitColumn = isExplicitColumn || attributeName == "Column"
          guard
            isExplicitColumn || isEphemeral || isColumnGroup,
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
                    message: MacroExpansionErrorMessage(
                      "Argument must be a non-empty string literal"
                    )
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
                // TODO: Update to suggest using '@Columns' to specify a composite primary key
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
              isPrimaryKey = true
              primaryKey = (
                identifier: identifier,
                label: label,
                queryOutputType: columnQueryOutputType,
                queryValueType: columnQueryValueType,
                isColumnGroup: isColumnGroup
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
            queryValueType: columnQueryValueType,
            isColumnGroup: isColumnGroup
          )
        }

        if !isGenerated {
          // NB: A compiler bug prevents us from applying the '@_Draft' macro directly
          draftBindings.append(
            (binding, columnQueryOutputType, identifier == primaryKey?.identifier)
          )
          // NB: End of workaround
        }

        columnWidths.append("\(columnQueryValueType)._columnWidth")

        let defaultValue =
          binding.initializer?.value.rewritten(selfRewriter)
          ?? (columnQueryValueType?.isOptionalType == true
            ? ExprSyntax(NilLiteralExprSyntax()) : nil)
        let tableColumnType =
          isGenerated
          ? "GeneratedColumn"
          : isColumnGroup
            ? "ColumnGroup"
            : isExplicitColumn
              ? "TableColumn"
              : "_TableColumn"
        let tableColumnInitializer = tableColumnType == "_TableColumn" ? ".for" : ""
        let defaultParameter =
          isColumnGroup
          ? ""
          : defaultValue.map { ", default: \($0.trimmedDescription)" } ?? ""
        func appendColumnProperty(primaryKey: Bool = false) {
          columnsProperties.append(
            """
            public let \(primaryKey ? "primaryKey" : identifier) = \
            \(moduleName).\(raw: tableColumnType)<\
            QueryValue, \
            \(raw: columnQueryValueType?.trimmedDescription ?? "_")\
            >\(raw: tableColumnInitializer)(\
            \(raw: isColumnGroup ? "" : "\(columnName), ")\
            keyPath: \\QueryValue.\(identifier)\
            \(raw: defaultParameter)\
            )
            """
          )
        }
        appendColumnProperty()
        if isPrimaryKey {
          appendColumnProperty(primaryKey: true)
        }
        allColumns.append(identifier)
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
            guard let \(identifier) else {
            throw \(moduleName).QueryDecodingError.missingRequiredColumn
            }
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
            var property = property
            for attributeIndex in property.attributes.indices {
              guard
                var attribute = property.attributes[attributeIndex].as(AttributeSyntax.self)?
                  .trimmed,
                let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name
                  .text,
                ["Column", "Columns"].contains(attributeName)
              else { continue }
              var hasPrimaryKeyArgument = false
              var arguments: LabeledExprListSyntax = []
              if case .argumentList(let list) = attribute.arguments { arguments = list }
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
                if !arguments.isEmpty {
                  arguments[arguments.index(before: arguments.endIndex)].trailingComma =
                    .commaToken(
                      trailingTrivia: .space
                    )
                }
                arguments.append(
                  LabeledExprSyntax(
                    label: "primaryKey",
                    expression: BooleanLiteralExprSyntax(false)
                  )
                )
              }
              if !arguments.isEmpty {
                attribute.leftParen = TokenSyntax.leftParenToken()
                attribute.arguments = .argumentList(arguments)
                attribute.rightParen = TokenSyntax.rightParenToken()
                property.attributes[attributeIndex] = .attribute(attribute)
              }
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
      initDecoder = """

        public \(nonisolated)init(decoder: inout some \(moduleName).QueryDecoder) throws {
        \(raw: (decodings + decodingUnwrappings + decodingAssignments).joined(separator: "\n"))
        }
        """
    } else if declaration.is(EnumDeclSyntax.self) {
      var decodings: [String] = []
      for member in declaration.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
        guard
          // TODO: Support multi-element cases where '@Column{,s}' macro is omitted?
          caseDecl.elements.count == 1,
          let caseElement = caseDecl.elements.first,
          let parameters = caseElement.parameterClause?.parameters,
          // TODO: Support enum cases with multiple associated values?
          // TODO: Support enum case with no associated value?
          parameters.count == 1,
          let parameter = parameters.first
        else {
          diagnostics.append(
            Diagnostic(
              node: caseDecl,
              message: MacroExpansionErrorMessage(
                """
                Table case must contain a single associated value representing one or more \
                optional columns
                """
              )
            )
          )
          continue
        }

        let identifier = caseElement.name
        var columnName = ExprSyntax(
          StringLiteralExprSyntax(content: identifier.text.trimmingBackticks())
        )
        var columnQueryValueType = parameter.type.trimmed.rewritten(selfRewriter)
        var isColumnGroup = false
        var isExplicitColumn = false

        for attribute in caseDecl.attributes {
          guard
            let attribute = attribute.as(AttributeSyntax.self),
            let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
          else { continue }
          guard
            attributeName != "Ephemeral"
          else {
            diagnostics.append(
              Diagnostic(
                node: attribute,
                message: MacroExpansionErrorMessage("Table case cannot be ephemeral"),
                fixIt: .replace(
                  message: MacroExpansionFixItMessage("Remove '@Ephemeral'"),
                  oldNode: attribute,
                  newNode: TokenSyntax("")
                )
              )
            )
            continue
          }
          isColumnGroup = isColumnGroup || attributeName == "Columns"
          isExplicitColumn = isExplicitColumn || attributeName == "Column"
          guard
            isExplicitColumn || isColumnGroup,
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
                    message: MacroExpansionErrorMessage(
                      "Argument must be a non-empty string literal"
                    )
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

            case .some(let label) where label.text == "primaryKey":
              diagnostics.append(
                Diagnostic(
                  node: argument.expression,
                  message: MacroExpansionErrorMessage(
                    "Argument 'primaryKey' is not supported on enum table columns"
                  )
                )
              )
              continue

            case .some(let label) where label.text == "generated":
              diagnostics.append(
                Diagnostic(
                  node: argument.expression,
                  message: MacroExpansionErrorMessage(
                    "Argument 'generated' is not supported on enum table columns"
                  )
                )
              )
              continue

            case let argument?:
              fatalError("Unexpected argument: \(argument)")
            }
          }
        }

        columnWidths.append("\(columnQueryValueType)._columnWidth")

        let defaultValue = parameter.defaultValue?.value.rewritten(selfRewriter)
        let tableColumnType =
          isColumnGroup
          ? "ColumnGroup"
          : isExplicitColumn
            ? "TableColumn"
            : "_TableColumn"
        let tableColumnInitializer = tableColumnType == "_TableColumn" ? ".for" : ""
        let defaultParameter =
          isColumnGroup
          ? ""
          : defaultValue.map { ", default: \($0.trimmedDescription)" } ?? ""
        func appendColumnProperty(primaryKey: Bool = false) {
          columnsProperties.append(
            """
            public let \(primaryKey ? "primaryKey" : identifier) = \
            \(moduleName).\(raw: tableColumnType)<\
            QueryValue, \
            \(raw: columnQueryValueType.trimmedDescription)?\
            >\(raw: tableColumnInitializer)(\
            \(raw: isColumnGroup ? "" : "\(columnName), ")\
            keyPath: \\QueryValue.\(identifier)\
            \(raw: defaultParameter)\
            )
            """
          )
        }
        appendColumnProperty()
        allColumns.append(identifier)
        let decodedType = columnQueryValueType.asNonOptionalType()
        decodings.append(
          """
          if let \(identifier) = try decoder.decode(\(decodedType).self) {
          self = .\(identifier)(\(identifier))
          }
          """
        )
      }
      initDecoder = """

        public \(nonisolated)init(decoder: inout some \(moduleName).QueryDecoder) throws {
        \(raw: decodings.joined(separator: " else ")) else {
        throw \(moduleName).QueryDecodingError.missingRequiredColumn
        }
        }
        """
    }

    var draft: DeclSyntax?
    var initFromOther: DeclSyntax?
    if let draftTableType {
      initFromOther = """

        public \(nonisolated)init(_ other: \(draftTableType)) {
        \(allColumns.map { "self.\($0) = other.\($0)" as ExprSyntax }, separator: "\n")
        }
        """
    } else if primaryKey != nil {
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
              fixIt: .replace(
                message: MacroExpansionFixItMessage(
                  """
                  Insert ': <#Type#>'
                  """
                ),
                oldNode: binding,
                newNode:
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
    var protocolNames: [TokenSyntax] =
      primaryKey != nil
      ? ["Table", "PrimaryKeyedTable"]
      : ["Table"]
    if node.attributeName.identifier == "Selection" {
      protocolNames.append("_Selection")
    }
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
            declaration.is(EnumDeclSyntax.self)
              ? """
              '@Table' requires at least one case to be defined on '\(type)'
              """
              : """
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
    conformances.append("\(moduleName).PartialSelectStatement")
    statics.append(contentsOf: [
      """

      public typealias QueryValue = Self
      """,
      """
      public typealias From = Swift.Never
      """,
    ])
    let columnWidth: ExprSyntax = """
      var columnWidth = 0
      columnWidth += \(columnWidths, separator: "\ncolumnWidth += ")
      return columnWidth
      """

    return [
      DeclSyntax(
        """
        \(declaration.attributes.availability)\(nonisolated)extension \(type)\
        \(conformances.isEmpty ? "" : ": \(conformances, separator: ", ")") {\
        \(statics, separator: "\n")
        public \(nonisolated)static var columns: TableColumns { TableColumns() }
        public \(nonisolated)static var _columnWidth: Int { \(columnWidth) }
        public \(nonisolated)static var tableName: String { \(tableName) }\
        \(letSchemaName)\(initDecoder)\(initFromOther)
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
    if node.attributeName.identifier == "Selection", declaration.hasMacroApplication("Table") {
      return []
    }
    guard
      declaration.isTableMacroSupported,
      let declarationName = declaration.declarationName
    else {
      return []
    }
    let type = IdentifierTypeSyntax(name: declarationName.trimmed)
    var allColumns:
      [(name: TokenSyntax, firstName: TokenSyntax, type: TypeSyntax?, default: ExprSyntax?)] = []
    var allColumnNames: [TokenSyntax] = []
    var writableColumns: [TokenSyntax] = []
    var selectedColumns: [(name: TokenSyntax, type: TypeSyntax?)] = []
    var columnsProperties: [DeclSyntax] = []
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
        queryValueType: TypeSyntax?,
        isColumnGroup: Bool
      )?
    let selfRewriter = SelfRewriter(selfEquivalent: type.name)
    var selectionInitializers: [DeclSyntax] = []
    if declaration.is(StructDeclSyntax.self) {
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
        var isPrimaryKey =
          primaryKey == nil
          && identifier.text == "id"
          && node.attributeName.identifier != "_Draft"
        var isColumnGroup = false
        var isEphemeral = false
        var isExplicitColumn = false
        var isGenerated = false

        for attribute in property.attributes {
          guard
            let attribute = attribute.as(AttributeSyntax.self),
            let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
          else { continue }
          isColumnGroup = isColumnGroup || attributeName == "Columns"
          isEphemeral = isEphemeral || attributeName == "Ephemeral"
          isExplicitColumn = isExplicitColumn || attributeName == "Column"
          guard
            isExplicitColumn || isEphemeral || isColumnGroup,
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
              isPrimaryKey = true
              if primaryKey != nil {
                var newArguments = arguments
                newArguments.remove(at: argumentIndex)
                expansionFailed = true
              }
              primaryKey = (
                identifier: identifier,
                label: label,
                queryOutputType: columnQueryOutputType,
                queryValueType: columnQueryValueType,
                isColumnGroup: isColumnGroup
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
            queryValueType: columnQueryValueType,
            isColumnGroup: isColumnGroup
          )
        }

        selectedColumns.append((identifier, columnQueryValueType))

        if !isGenerated {
          // NB: A compiler bug prevents us from applying the '@_Draft' macro directly
          draftBindings.append(
            (binding, columnQueryOutputType, identifier == primaryKey?.identifier)
          )
          // NB: End of workaround
        }

        let defaultValue =
          binding.initializer?.value.rewritten(selfRewriter)
          ?? (columnQueryValueType?.isOptionalType == true
            ? ExprSyntax(NilLiteralExprSyntax()) : nil)
        let tableColumnType =
          isGenerated
          ? "GeneratedColumn"
          : isColumnGroup
            ? "ColumnGroup"
            : isExplicitColumn
              ? "TableColumn"
              : "_TableColumn"
        let tableColumnInitializer = tableColumnType == "_TableColumn" ? ".for" : ""
        let defaultParameter =
          isColumnGroup
          ? ""
          : defaultValue.map { ", default: \($0.trimmedDescription)" } ?? ""
        func appendColumnProperty(primaryKey: Bool = false) {
          columnsProperties.append(
            """
            public let \(primaryKey ? "primaryKey" : identifier) = \
            \(moduleName).\(raw: tableColumnType)<\
            QueryValue, \
            \(raw: columnQueryValueType?.trimmedDescription ?? "_")\
            >\(raw: tableColumnInitializer)(\
            \(raw: isColumnGroup ? "" : "\(columnName), ")\
            keyPath: \\QueryValue.\(identifier)\
            \(raw: defaultParameter)\
            )
            """
          )
        }
        appendColumnProperty()
        if isPrimaryKey {
          appendColumnProperty(primaryKey: true)
        }
        allColumns.append((identifier, "_", columnQueryValueType, defaultValue?.trimmed))
        allColumnNames.append(identifier)
        if !isGenerated {
          writableColumns.append(identifier)
          if let primaryKey, primaryKey.identifier == identifier {
            var property = property
            for attributeIndex in property.attributes.indices {
              guard
                var attribute = property.attributes[attributeIndex].as(AttributeSyntax.self)?
                  .trimmed,
                let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name
                  .text,
                ["Column", "Columns"].contains(attributeName)
              else { continue }
              var hasPrimaryKeyArgument = false
              var arguments: LabeledExprListSyntax = []
              if case .argumentList(let list) = attribute.arguments { arguments = list }
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
                if !arguments.isEmpty {
                  arguments[arguments.index(before: arguments.endIndex)].trailingComma =
                    .commaToken(
                      trailingTrivia: .space
                    )
                }
                arguments.append(
                  LabeledExprSyntax(
                    label: "primaryKey",
                    expression: BooleanLiteralExprSyntax(false)
                  )
                )
              }
              if !arguments.isEmpty {
                attribute.leftParen = TokenSyntax.leftParenToken()
                attribute.arguments = .argumentList(arguments)
                attribute.rightParen = TokenSyntax.rightParenToken()
                property.attributes[attributeIndex] = .attribute(attribute)
              }
            }
            property = property.trimmed
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
                  .with(\.attributes.trailingTrivia, .space)
                  .with(\.bindingSpecifier.leadingTrivia, "")
                  .removingAccessors()
                  .rewritten(selfRewriter)
              )
            )
          }
        }
      }
      let selectionInitArguments =
        allColumns
        .map { name, _, type, `default` in
          var query = "\(name): some \(moduleName).QueryExpression"
          if let type {
            query.append("<\(type)>")
            if let `default` {
              query.append(" = \(type)(queryOutput: \(`default`))")
            }
          }
          return query
        }
        .joined(separator: ",\n")

      let selectionAssignment =
        selectedColumns
        .map { c, _ in "allColumns.append(contentsOf: \(c)._allColumns)\n" }
        .joined()

      selectionInitializers.append(
        """
        public init(
        \(raw: selectionInitArguments)
        ) {
        var allColumns: [any StructuredQueriesCore.QueryExpression] = []
        \(raw: selectionAssignment)self.allColumns = allColumns
        }
        """
      )
    } else if declaration.is(EnumDeclSyntax.self) {
      for member in declaration.memberBlock.members {
        guard
          let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
          caseDecl.elements.count == 1,
          let caseElement = caseDecl.elements.first,
          let parameters = caseElement.parameterClause?.parameters,
          parameters.count == 1,
          let parameter = parameters.first
        else { continue }

        let identifier = caseElement.name
        var columnName = ExprSyntax(
          StringLiteralExprSyntax(content: identifier.text.trimmingBackticks())
        )
        var columnQueryValueType = parameter.type.trimmed.rewritten(selfRewriter)
        var isColumnGroup = false
        var isExplicitColumn = false

        for attribute in caseDecl.attributes {
          guard
            let attribute = attribute.as(AttributeSyntax.self),
            let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
          else { continue }
          isExplicitColumn = isExplicitColumn || attributeName == "Column"
          isColumnGroup = isColumnGroup || attributeName == "Columns"
          guard
            isExplicitColumn || isColumnGroup,
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

            case .some(let label) where label.text == "primaryKey":
              expansionFailed = true

            case .some(let label) where label.text == "generated":
              expansionFailed = true

            case let argument?:
              fatalError("Unexpected argument: \(argument)")
            }
          }
        }

        selectedColumns.append((identifier, columnQueryValueType))

        let defaultValue = parameter.defaultValue?.value.rewritten(selfRewriter)
        let tableColumnType =
          isColumnGroup
          ? "ColumnGroup"
          : isExplicitColumn
            ? "TableColumn"
            : "_TableColumn"
        let tableColumnInitializer = tableColumnType == "_TableColumn" ? ".for" : ""
        let defaultParameter =
          isColumnGroup
          ? ""
          : defaultValue.map { ", default: \($0.trimmedDescription)" } ?? ""
        func appendColumnProperty(primaryKey: Bool = false) {
          columnsProperties.append(
            """
            public let \(primaryKey ? "primaryKey" : identifier) = \
            \(moduleName).\(raw: tableColumnType)<\
            QueryValue, \
            \(raw: columnQueryValueType.trimmedDescription)?\
            >\(raw: tableColumnInitializer)(\
            \(raw: isColumnGroup ? "" : "\(columnName), ")\
            keyPath: \\QueryValue.\(identifier)\
            \(raw: defaultParameter)\
            )
            """
          )
        }
        appendColumnProperty()
        allColumns.append(
          (identifier, parameter.firstName ?? "_", columnQueryValueType, defaultValue?.trimmed)
        )
        allColumnNames.append(identifier)
        writableColumns.append(identifier)
      }
      for (identifier, firstName, valueType, defaultValue) in allColumns {
        var argument = """
          \(firstName) \(identifier): some \(moduleName).QueryExpression<\(type)>
          """
        if let defaultValue {
          argument.append(" = \(type)(queryOutput: \(defaultValue))")
        }
        let staticColumns = selectedColumns.map {
          $0 == identifier ? "\($0)" : "\($1)?(queryOutput: nil)" as ExprSyntax
        }
        let staticInitialization =
          staticColumns
          .map { "allColumns.append(contentsOf: \($0)._allColumns)\n" }
          .joined()

        selectionInitializers.append(
          """
          public static func \(identifier)(
          \(firstName) \(identifier): some \(moduleName).QueryExpression<\(valueType)>
          ) -> Self {
          var allColumns: [any StructuredQueriesCore.QueryExpression] = []
          \(raw: staticInitialization)return Self(allColumns: allColumns)
          }
          """
        )
      }
    }

    var draft: DeclSyntax?
    if primaryKey != nil {
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
    conformances.append("\(moduleName).PartialSelectStatement")
    typeAliases.append(contentsOf: [
      """

      public typealias QueryValue = Self
      """,
      """
      public typealias From = Swift.Never
      """,
    ])

    let primaryKeyTypealias: DeclSyntax? = primaryKey.map {
      """

      public typealias PrimaryKey = \($0.queryValueType)
      """
    }

    let allColumnsAssignment =
      allColumnNames
      .map { "allColumns.append(contentsOf: QueryValue.columns.\($0)._allColumns)\n" }
      .joined()
    let writableColumnsAssignment =
      writableColumns
      .map { "writableColumns.append(contentsOf: QueryValue.columns.\($0)._writableColumns)\n" }
      .joined()

    return [
      """
      public \(nonisolated)struct TableColumns: \(schemaConformances, separator: ", ") {
      public typealias QueryValue = \(type.trimmed)\(primaryKeyTypealias)
      \(columnsProperties, separator: "\n")
      public static var allColumns: [any \(moduleName).TableColumnExpression] {
      var allColumns: [any \(moduleName).TableColumnExpression] = []
      \(raw: allColumnsAssignment)return allColumns
      }
      public static var writableColumns: [any \(moduleName).WritableTableColumnExpression] {
      var writableColumns: [any \(moduleName).WritableTableColumnExpression] = []
      \(raw: writableColumnsAssignment)return writableColumns
      }
      public var queryFragment: QueryFragment {
      "\(raw: selectedColumns.map { c, _ in #"\(self.\#(c))"# }.joined(separator: ", "))"
      }
      }
      """,
      """
      public nonisolated struct Selection: \(moduleName).TableExpression {
      public typealias QueryValue = \(type.trimmed)
      public let allColumns: [any \(moduleName).QueryExpression]
      \(selectionInitializers, separator: "\n")
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
    if node.attributeName.identifier == "Selection", declaration.hasMacroApplication("Table") {
      return []
    }
    guard
      declaration.is(StructDeclSyntax.self),
      let property = member.as(VariableDeclSyntax.self),
      !property.isStatic,
      !property.isComputed,
      !property.hasMacroApplication("Column"),
      !property.hasMacroApplication("Columns"),
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
