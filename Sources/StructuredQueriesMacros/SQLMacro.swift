import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum SQLMacro: ExpressionMacro {
  public static func expansion<N: FreestandingMacroExpansionSyntax, C: MacroExpansionContext>(
    of node: N,
    in context: C
  ) -> ExprSyntax {
    guard let argument = node.arguments.first?.expression else { fatalError() }
    let binds = [
      UInt8(ascii: "?"), UInt8(ascii: ":"), UInt8(ascii: "@"), UInt8(ascii: "$"),
    ]
    let delimiters: [UInt8: UInt8] = [
      UInt8(ascii: #"""#): UInt8(ascii: #"""#),
      UInt8(ascii: "'"): UInt8(ascii: "'"),
      UInt8(ascii: "`"): UInt8(ascii: "`"),
      UInt8(ascii: "["): UInt8(ascii: "]"),
      UInt8(ascii: "("): UInt8(ascii: ")"),
    ]
    var parenStack: [(delimiter: UInt8, segment: StringSegmentSyntax, offset: Int)] = []
    var currentDelimiter: (delimiter: UInt8, segment: StringSegmentSyntax, offset: Int)?
    var unexpectedBind: (segment: StringSegmentSyntax, offset: Int)?
    var unexpectedClose: (delimiter: UInt8, segment: StringSegmentSyntax, offset: Int)?
    var invalidBind = false
    var isInComment = false
    if let string = argument.as(StringLiteralExprSyntax.self) {
      for segment in string.segments {
        guard let segment = segment.as(StringSegmentSyntax.self)
        else {
          if invalidBind,
            let currentDelimiter,
            let segment = segment.as(ExpressionSegmentSyntax.self),
            let expression = segment.expressions.first
          {
            guard expression.label?.text == "raw" else {
              let openingDelimiter = UnicodeScalar(currentDelimiter.delimiter)
              let q = openingDelimiter == "'" ? #"""# : "'"
              context.diagnose(
                Diagnostic(
                  node: segment,
                  message: MacroExpansionErrorMessage(
                    """
                    Bind after opening \(q)\(openingDelimiter)\(q) in SQL string, producing \
                    invalid fragment; did you mean to make this explicit? To interpolate raw SQL, \
                    use '\\(raw:)'.
                    """
                  ),
                  notes: [
                    Note(
                      node: Syntax(string),
                      position: currentDelimiter.segment.position.advanced(
                        by: currentDelimiter.offset
                      ),
                      message: MacroExpansionNoteMessage("Opening \(q)\(openingDelimiter)\(q)")
                    )
                  ],
                  fixIt: .replace(
                    message: MacroExpansionFixItMessage("Insert 'raw: '"),
                    oldNode: expression,
                    newNode:
                      expression
                      .with(\.label, .identifier("raw"))
                      .with(\.colon, .colonToken(trailingTrivia: " "))
                  )
                )
              )
              continue
            }
          }
          continue
        }

        var offset = 0
        while offset < segment.content.syntaxTextBytes.endIndex {
          defer { offset += 1 }
          let byte = segment.content.syntaxTextBytes[offset]
          if isInComment {
            if byte == UInt8(ascii: "\n") {
              isInComment = false
            }
            continue
          }
          if let delimiter = currentDelimiter ?? parenStack.last {
            if byte == delimiters[delimiter.delimiter] {
              if currentDelimiter == nil {
                parenStack.removeLast()
                continue
              } else if delimiter.segment == segment,
                offset > delimiter.offset + 1,
                segment.content.syntaxTextBytes.indices.contains(offset + 1),
                segment.content.syntaxTextBytes[offset + 1] == byte
              {
                offset += 1
                continue
              } else {
                currentDelimiter = nil
                continue
              }
            }
          }
          if currentDelimiter == nil {
            if delimiters.keys.contains(byte) {
              if byte == UInt8(ascii: "(") {
                parenStack.append((byte, segment, offset))
              } else {
                currentDelimiter = (byte, segment, offset)
              }
            } else if delimiters.values.contains(byte) {
              unexpectedClose = (byte, segment, offset)
            } else if binds.contains(byte) {
              unexpectedBind = (segment, offset)
            } else if byte == UInt8(ascii: "-"),
              segment.content.syntaxTextBytes.indices.contains(offset + 1),
              segment.content.syntaxTextBytes[offset + 1] == byte
            {
              offset += 1
              isInComment = true
            }
          }
        }

        invalidBind = currentDelimiter?.segment == segment
      }

      if let currentDelimiter = currentDelimiter ?? parenStack.last,
        let closingDelimiter = delimiters[currentDelimiter.delimiter]
      {
        let openingDelimiter = UnicodeScalar(currentDelimiter.delimiter)
        let closingDelimiter = UnicodeScalar(closingDelimiter)
        let q = openingDelimiter == "'" ? #"""# : "'"
        context.diagnose(
          Diagnostic(
            node: string,
            position: currentDelimiter.segment.position.advanced(by: currentDelimiter.offset),
            message: MacroExpansionWarningMessage(
              """
              Cannot find \(q)\(closingDelimiter)\(q) to match opening \(q)\(openingDelimiter)\(q) \
              in SQL string, producing incomplete fragment; did you mean to make this explicit?
              """
            ),
            fixIt: .replace(
              message: MacroExpansionFixItMessage(
                "Use 'SQLQueryExpression.init(_:)' to silence this warning"
              ),
              oldNode: node,
              newNode: FunctionCallExprSyntax(
                calledExpression: DeclReferenceExprSyntax(
                  baseName: .identifier("SQLQueryExpression")
                ),
                leftParen: .leftParenToken(),
                arguments: node.arguments,
                rightParen: .rightParenToken()
              )
            )
          )
        )
      }
      if let unexpectedBind {
        context.diagnose(
          Diagnostic(
            node: string,
            position: unexpectedBind.segment.position.advanced(by: unexpectedBind.offset),
            message: MacroExpansionErrorMessage(
              """
              Invalid bind parameter in literal; use interpolation to bind values into SQL
              """
            )
          )
        )
      }
      if let unexpectedClose {
        let delimiters: [UInt8: UInt8] = [
          UInt8(ascii: "]"): UInt8(ascii: "["),
          UInt8(ascii: ")"): UInt8(ascii: "("),
        ]
        let closingDelimiter = UnicodeScalar(unexpectedClose.delimiter)
        let openingDelimiter = UnicodeScalar(
          delimiters[unexpectedClose.delimiter] ?? unexpectedClose.delimiter
        )
        let q = openingDelimiter == "'" ? #"""# : "'"

        context.diagnose(
          Diagnostic(
            node: string,
            position: unexpectedClose.segment.position.advanced(by: unexpectedClose.offset),
            message: MacroExpansionWarningMessage(
              """
              Cannot find \(q)\(openingDelimiter)\(q) to match closing \(q)\(closingDelimiter)\(q) \
              in SQL string, producing incomplete fragment; did you mean to make this explicit?
              """
            ),
            fixIt: .replace(
              message: MacroExpansionFixItMessage(
                "Use 'SQLQueryExpression.init(_:)' to silence this warning"
              ),
              oldNode: node,
              newNode: FunctionCallExprSyntax(
                calledExpression: DeclReferenceExprSyntax(
                  baseName: .identifier("SQLQueryExpression")
                ),
                leftParen: .leftParenToken(),
                arguments: node.arguments,
                rightParen: .rightParenToken()
              )
            )
          )
        )
      }
    }
    return "\(moduleName).SQLQueryExpression(\(argument))"
  }
}
