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

  func isOptional() -> Bool {
    // x: Optional<T> or x: T?
    if self.typeAnnotation?.type.isOptionalType == true { return true }
    // Missing cases
    // x = Optional<T>.some(_)
    // x = fnReturningOptionalType()
    return false
  }
}
