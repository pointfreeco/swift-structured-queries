import SwiftSyntax

extension DeclGroupSyntax {
  var isTableMacroSupported: Bool {
    #if CasePaths
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

  var accessLevelModifier: DeclModifierSyntax? {
    modifiers.first { modifier in
      switch modifier.name.tokenKind {
      case .keyword(.public), .keyword(.package), .keyword(.internal),
        .keyword(.fileprivate), .keyword(.private), .keyword(.open):
        return true
      default:
        return false
      }
    }
  }
}

extension SyntaxProtocol {
  var declGroupAccessLevelModifier: DeclModifierSyntax? {
    self.as(StructDeclSyntax.self)?.accessLevelModifier
      ?? self.as(EnumDeclSyntax.self)?.accessLevelModifier
      ?? self.as(ClassDeclSyntax.self)?.accessLevelModifier
      ?? self.as(ActorDeclSyntax.self)?.accessLevelModifier
      ?? self.as(ExtensionDeclSyntax.self)?.accessLevelModifier
  }
}
