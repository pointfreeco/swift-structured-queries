import SwiftSyntax
import SwiftSyntaxBuilder

extension PatternBindingSyntax {
  func annotated(_ type: TypeSyntax? = nil) -> PatternBindingSyntax {
    var annotated = with(
      \.typeAnnotation,
      typeAnnotation
        ?? (type ?? initializer?.value.literalType).map {
          TypeAnnotationSyntax(
            type: $0.with(\.trailingTrivia, .space)
          )
        }
    )
    if annotated.typeAnnotation != nil {
      annotated.pattern.trailingTrivia = ""
      annotated = annotated.withoutTrailingComments()
    }
    annotated.accessorBlock = nil
    guard annotated.typeAnnotation?.type.isOptionalType == true
    else {
      return annotated.trimmed
    }

    annotated.initializer =
      annotated.initializer
      ?? InitializerClauseSyntax.init(
        equal: .equalToken(leadingTrivia: " ", trailingTrivia: " "),
        value: NilLiteralExprSyntax()
      )
    return annotated
  }

  func optionalized() -> PatternBindingSyntax {
    var optionalized = annotated()
    guard let optionalType = optionalized.typeAnnotation?.type.asOptionalType()
    else { return self }
    optionalized.typeAnnotation?.type = optionalType
    return optionalized
  }

  func withoutTrailingComments() -> PatternBindingSyntax {
    guard let lastToken = self.lastToken(viewMode: .sourceAccurate) else { return self }
    let newTrailingTrivia = Trivia(
      pieces: lastToken.trailingTrivia.filter { piece in
        switch piece {
        case .lineComment, .blockComment, .docLineComment, .docBlockComment: false
        default: true
        }
      }
    )
    let rewriter = TokenRewriter(
      replacing: lastToken,
      with: lastToken.with(\.trailingTrivia, newTrailingTrivia)
    )
    return rewriter.visit(self)
  }
}

private class TokenRewriter: SyntaxRewriter {
  let target: TokenSyntax
  let replacement: TokenSyntax

  init(replacing target: TokenSyntax, with replacement: TokenSyntax) {
    self.target = target
    self.replacement = replacement
  }

  override func visit(_ token: TokenSyntax) -> TokenSyntax {
    return token == target ? replacement : token
  }
}
