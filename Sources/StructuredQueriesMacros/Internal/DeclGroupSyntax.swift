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

  func macroApplication(for name: String) -> AttributeSyntax? {
    for attribute in attributes {
      switch attribute {
      case .attribute(let attr):
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          return attr
        }
      default:
        break
      }
    }
    return nil
  }

  func hasMacroApplication(_ name: String) -> Bool {
    macroApplication(for: name) != nil
  }
}
