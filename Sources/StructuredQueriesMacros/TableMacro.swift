import SwiftBasicFormat
import SwiftDiagnostics
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

#if CasePaths
  import CasePathsMacrosSupport
#endif

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
              '@Table' can only be applied to enum types when the 'CasePaths' \
              package trait is enabled
              """
              : """
              '@Table' can only be applied to struct types (and enum types with the \
              'CasePaths' package trait enabled)
              """
          )
        )
      )
      return []
    }

    var allColumns: [TokenSyntax] = []
    var columnsProperties: [DeclSyntax] = []
    var columnWidths: [ExprSyntax] = []
    var diagnostics: [Diagnostic] = []

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
            draftTableType = TypeSyntax("\(memberAccess.base!.trimmed)")
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
          if !argument.expression.isNonEmptyStringLiteral {
            diagnostics.append(
              Diagnostic(
                node: argument.expression,
                message: MacroExpansionErrorMessage("Argument must be a non-empty string literal")
              )
            )
          }
          schemaName = argument.expression.trimmed

        case let argument?:
          fatalError("Unexpected argument: \(argument)")
        }
      }
    }

    let initAccess =
      draftTableType != nil
      ? declaration.accessLevelModifier.map { "\($0.name.text) " } ?? ""
      : "public "

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
        var hasRepresentation = false

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
              hasRepresentation = true

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

            case .some(let label) where label.text == "lazyInitializable":
              guard
                draftTableType == nil,
                binding.typeAnnotation?.type.isOptionalType == true
              else { break }
              var newAttribute = attribute
              var newArguments = arguments
              newArguments.remove(at: argumentIndex)
              if newArguments.isEmpty {
                newAttribute.leftParen = nil
                newAttribute.arguments = nil
                newAttribute.rightParen = nil
              } else {
                newArguments[newArguments.index(before: newArguments.endIndex)].trailingComma = nil
                newAttribute.arguments = .argumentList(newArguments)
              }
              context.diagnose(
                Diagnostic(
                  node: argument,
                  message: MacroExpansionWarningMessage(
                    """
                    Argument 'lazyInitializable' has no effect on optional column \
                    '\(identifier.text)'
                    """
                  ),
                  fixIt: .replace(
                    message: MacroExpansionFixItMessage("Remove 'lazyInitializable'"),
                    oldNode: Syntax(attribute),
                    newNode: Syntax(newAttribute)
                  )
                )
              )

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

        columnWidths.append(
          columnQueryValueType.map { "\($0)._columnWidth" as ExprSyntax }
            ?? "\(moduleName)._columnWidth(\\QueryValue.\(identifier))"
        )

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
            \(raw: primaryKey ? "@\(macrosModuleName)._PrimaryKeyDefault public var" : "public let") \
            \(primaryKey ? "primaryKey" : identifier) = \
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
        let decodeArgument = hasRepresentation ? (decodedType.map { "\($0).self" } ?? "") : ""
        if let defaultValue {
          decodings.append(
            """
            self.\(identifier) = try decoder.decode(\(decodeArgument)) \
            ?? \(defaultValue)
            """
          )
        } else if columnQueryValueType.map({ $0.isOptionalType }) ?? false {
          decodings.append(
            """
            self.\(identifier) = try decoder.decode(\(decodeArgument))
            """
          )
        } else {
          let requiredArgument =
            hasRepresentation ? decodeArgument : "\\QueryValue.\(identifier)"
          decodings.append(
            """
            let \(identifier) = try decoder.decode(\(requiredArgument))
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

      }
      initDecoder = """

        \(raw: initAccess)\(nonisolated)init(decoder: inout some \(moduleName).QueryDecoder) throws {
        \(raw: (decodings + decodingUnwrappings + decodingAssignments).joined(separator: "\n"))
        }
        """
    } else if declaration.is(EnumDeclSyntax.self) {
      var decodings: [String] = []
      var decodingAssignments: [String] = []
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

            case .some(let label) where label.text == "lazyInitializable":
              diagnostics.append(
                Diagnostic(
                  node: argument.expression,
                  message: MacroExpansionErrorMessage(
                    "Argument 'lazyInitializable' is not supported on enum table columns"
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
          let \(identifier) = try decoder.decode(\(decodedType).self)
          """
        )
        let caseArgumentLabel: String
        if let firstName = parameter.firstName, firstName.tokenKind != .wildcard {
          caseArgumentLabel = "\(firstName.text.trimmingBackticks()): "
        } else {
          caseArgumentLabel = ""
        }
        decodingAssignments.append(
          """
          if let \(identifier) {
          self = .\(identifier)(\(caseArgumentLabel)\(identifier))
          }
          """
        )
      }
      initDecoder = """

        public \(nonisolated)init(decoder: inout some \(moduleName).QueryDecoder) throws {
        \(raw: decodings.joined(separator: "\n"))
        \(raw: decodingAssignments.joined(separator: " else ")) else {
        throw \(moduleName).QueryDecodingError.missingRequiredColumn
        }
        }
        """
    }

    var initFromOther: DeclSyntax?
    if draftTableType != nil {
      initFromOther = """

        \(raw: initAccess)\(nonisolated)init(_ other: SourceTable) {
        \(allColumns.map { "self.\($0) = other.\($0)" as ExprSyntax }, separator: "\n")
        }
        """
    }

    var conformances: [TypeSyntax] = []
    var protocolNames: [TokenSyntax] =
      draftTableType != nil
      ? []
      : primaryKey != nil
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
    if draftTableType == nil {
      conformances.append("\(moduleName).PartialSelectStatement")
    }
    statics.append(contentsOf: [
      """

      public typealias QueryValue = Self
      """,
      """
      public typealias From = Swift.Never
      """,
    ])
    let columnWidth = """
      var columnWidth = 0
      columnWidth += \(columnWidths.map(\.description).joined(separator: "\ncolumnWidth += "))
      return columnWidth
      """

    var extensionMembers: [DeclSyntax] = []
    if draftTableType == nil {
      extensionMembers.append(contentsOf: statics)
      extensionMembers.append(
        "public \(nonisolated)static var columns: TableColumns { TableColumns() }"
      )
      extensionMembers.append(
        "public \(nonisolated)static var _columnWidth: Int { \(raw: columnWidth) }"
      )
      extensionMembers.append("public \(nonisolated)static var tableName: String { \(tableName) }")
      if let letSchemaName {
        extensionMembers.append(letSchemaName)
      }
    }
    if let initDecoder {
      extensionMembers.append(initDecoder)
    }
    if let initFromOther {
      extensionMembers.append(initFromOther)
    }

    var extensions: [ExtensionDeclSyntax] = [
      DeclSyntax(
        """
        \(declaration.attributes.availability)\(nonisolated)extension \(type)\
        \(conformances.isEmpty ? "" : ": \(conformances, separator: ", ")") {
        \(raw: extensionMembers.map(\.trimmedDescription).joined(separator: "\n"))
        }
        """
      )
      .cast(ExtensionDeclSyntax.self)
    ]
    #if CasePaths
      if declaration.is(EnumDeclSyntax.self) {
        extensions += try CasePathableMacro.expansion(
          of: node,
          attachedTo: declaration,
          providingExtensionsOf: type,
          conformingTo: protocols,
          in: context
        )
      }
    #endif
    return extensions
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
    var columnWidths: [ExprSyntax] = []
    var expansionFailed = false

    var draftProperties: [DeclSyntax] = []
    var draftHasLazyColumn = false
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
        var isLazyInitializable: Bool?

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

            case .some(let label) where label.text == "lazyInitializable":
              isLazyInitializable =
                argument.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind
                == .keyword(.true)

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
        columnWidths.append(
          columnQueryValueType.map { "\($0)._columnWidth" as ExprSyntax }
            ?? "\(moduleName)._columnWidth(\\QueryValue.\(identifier))"
        )

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
            \(raw: primaryKey ? "@\(macrosModuleName)._PrimaryKeyDefault public var" : "public let") \
            \(primaryKey ? "primaryKey" : identifier) = \
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
          let lazyInitializableByDefault: Bool
          #if LazyInitializableByDefault
            lazyInitializableByDefault = true
          #else
            lazyInitializableByDefault = false
          #endif
          let isLazyInitializableColumn =
            isLazyInitializable
            ?? (lazyInitializableByDefault && defaultValue == nil)
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
                  .with(\.bindingSpecifier, .keyword(.var, trailingTrivia: .space))
                  .removingAccessors()
                  .rewritten(selfRewriter)
              )
            )
          } else if isLazyInitializableColumn,
            let type = binding.typeAnnotation?.type,
            !type.isOptionalType
          {
            draftHasLazyColumn = true
            var property = property
            for attributeIndex in property.attributes.indices {
              guard
                var attribute = property.attributes[attributeIndex].as(AttributeSyntax.self)?
                  .trimmed,
                let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name
                  .text,
                ["Column", "Columns"].contains(attributeName)
              else { continue }
              if case .argumentList(var arguments) = attribute.arguments {
                for argumentIndex in arguments.indices {
                  var argument = arguments[argumentIndex]
                  defer { arguments[argumentIndex] = argument }
                  if argument.label?.text == "as",
                    var expression = argument.expression.as(MemberAccessExprSyntax.self)
                  {
                    expression.base = "\(expression.base)?"
                    argument.expression = ExprSyntax(expression)
                  }
                }
                attribute.arguments = .argumentList(arguments)
              }
              property.attributes[attributeIndex] = .attribute(
                attribute.with(\.trailingTrivia, .space)
              )
            }
            property = property.trimmed
            var binding = binding
            binding.typeAnnotation?.type = type.asOptionalType()
            property.bindings = [binding]
            draftProperties.append(
              DeclSyntax(
                property
                  .with(\.bindingSpecifier, .keyword(.var, trailingTrivia: .space))
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

            case .some(let label) where label.text == "lazyInitializable":
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
    if node.attributeName.identifier != "_Draft", primaryKey != nil || draftHasLazyColumn {
      let draftAccess: String
      switch declaration.accessLevelModifier?.name.tokenKind {
      case .keyword(.private), .keyword(.fileprivate):
        draftAccess = "fileprivate "
      case nil, .keyword(.internal):
        draftAccess = ""
      default:
        draftAccess = "\(declaration.accessLevelModifier?.name.text ?? "") "
      }
      draft = """

        @_Draft(\(type).self)
        \(raw: draftAccess)struct Draft: \(moduleName).TableDraft, \(moduleName).PartialSelectStatement {
        public typealias SourceTable = \(type)
        \(draftProperties, separator: "\n")
        }
        """
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
    let columnWidth = """
      var columnWidth = 0
      columnWidth += \(columnWidths.map(\.description).joined(separator: "\ncolumnWidth += "))
      return columnWidth
      """

    // NB: Workaround for https://github.com/pointfreeco/swift-structured-queries/issues/296
    let optimizeNoneWorkaround = """
      #if compiler(>=6.4)
      @_optimize(none)
      #endif

      """

    var members =
      [
        """
        public \(nonisolated)struct TableColumns: \(schemaConformances, separator: ", ") {
        public typealias QueryValue = \(type.trimmed)\(primaryKeyTypealias)
        \(columnsProperties, separator: "\n")
        \(raw: optimizeNoneWorkaround)public static var allColumns: [any \(moduleName).TableColumnExpression] {
        var allColumns: [any \(moduleName).TableColumnExpression] = []
        \(raw: allColumnsAssignment)return allColumns
        }
        \(raw: optimizeNoneWorkaround)public static var writableColumns: [any \(moduleName).WritableTableColumnExpression] {
        var writableColumns: [any \(moduleName).WritableTableColumnExpression] = []
        \(raw: writableColumnsAssignment)return writableColumns
        }
        public var queryFragment: QueryFragment {
        "\(raw: selectedColumns.map { c, _ in #"\(self.\#(c))"# }.joined(separator: ", "))"
        }
        }
        """,
        """
        public \(nonisolated)struct Selection: \(moduleName).TableExpression {
        public typealias QueryValue = \(type.trimmed)
        public let allColumns: [any \(moduleName).QueryExpression]
        \(selectionInitializers, separator: "\n")
        }
        """,
        draft,
      ]
      .compactMap { $0 }
      + (node.attributeName.identifier == "_Draft"
        ? typeAliases + [
          "public \(nonisolated)static var columns: TableColumns { TableColumns() }",
          "public \(nonisolated)static var _columnWidth: Swift.Int { \(raw: columnWidth) }",
        ]
        : [])
    #if CasePaths
      if declaration.is(EnumDeclSyntax.self) {
        members += try CasePathableMacro.expansion(
          of: node,
          providingMembersOf: declaration,
          in: context
        )
      }
    #endif
    return members
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
    let columnType = binding.typeAnnotation?.type.trimmed ?? binding.initializer?.value.literalType
    let checkAttribute: [AttributeSyntax]
    if let columnType {
      checkAttribute = ["@\(macrosModuleName)._ColumnCheck(\(columnType.trimmed).self)"]
    } else if let initializer = binding.initializer {
      checkAttribute = ["@\(macrosModuleName)._ColumnCheck(\(initializer.value.trimmed))"]
    } else {
      checkAttribute = []
    }
    let lazyInitializableHint: String
    #if LazyInitializableByDefault
      lazyInitializableHint =
        binding.initializer == nil && binding.typeAnnotation?.type.isOptionalType == false
        ? ", lazyInitializable: true"
        : ""
    #else
      lazyInitializableHint = ""
    #endif
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
            @Column("\(raw: identifier)"\(raw: lazyInitializableHint))
            """
          ] + checkAttribute
        }
      }
    }
    return [
      """
      @Column("\(raw: identifier)"\(raw: identifier == "id" ? ", primaryKey: true" : lazyInitializableHint))
      """
    ] + checkAttribute
  }
}
