import SwiftSyntax

extension DeclGroupSyntax {
  var isTableMacroSupported: Bool {
    #if StructuredQueriesCasePaths
      self.is(StructDeclSyntax.self) || self.is(EnumDeclSyntax.self)
    #else
      self.is(StructDeclSyntax.self)
    #endif
  }

  var declarationName: TokenSyntax? {
    self.as(StructDeclSyntax.self)?.name
      ?? self.as(EnumDeclSyntax.self)?.name
  }

  func hasMacroApplication(_ name: String) -> Bool {
    for attribute in attributes {
      switch attribute {
      case .attribute(let attr):
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          return true
        }
      default:
        break
      }
    }
    return false
  }
}
