import SwiftSyntax

extension PatternBindingListSyntax.Element {
  var getter: (throws: Bool, asyncSpecifier: TokenSyntax?, body: CodeBlockItemListSyntax)? {
    switch accessorBlock?.accessors {
    case .getter(let getter):
      return (false, nil, getter)
    case .accessors(let accessors):
      for accessor in accessors {
        if accessor.accessorSpecifier.tokenKind == .keyword(.get), let body = accessor.body {
          return (
            accessor.effectSpecifiers?.throwsClause != nil,
            accessor.effectSpecifiers?.asyncSpecifier,
            body.statements
          )
        }
      }
      return nil
    default:
      return nil
    }
  }
}
