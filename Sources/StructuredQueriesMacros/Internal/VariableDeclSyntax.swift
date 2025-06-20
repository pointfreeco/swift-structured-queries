import SwiftSyntax

extension VariableDeclSyntax {
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

  var isComputed: Bool {
    for binding in bindings {
      switch binding.accessorBlock?.accessors {
      case .getter:
        return true
      case .accessors(let accessors):
        for accessor in accessors {
          if accessor.accessorSpecifier.tokenKind == .keyword(.get) {
            return true
          }
        }
      default:
        continue
      }
    }
    return false
  }

  var isStatic: Bool {
    modifiers.contains { modifier in
      modifier.name.tokenKind == .keyword(.static)
    }
  }

  func removingAccessors() -> Self {
    var variable = self
    variable.bindings = PatternBindingListSyntax(
      variable.bindings.map {
        var binding = $0
        binding.accessorBlock = nil
        return binding
      })
    return variable
  }
}
