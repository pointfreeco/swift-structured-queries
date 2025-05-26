import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct BindMacroTests {
    @Test func basics() {
      assertMacro {
        #"""
        \(date) < #bind(Date())
        """#
      } expansion: {
        #"""
        \(date) < StructuredQueriesCore.BindQueryExpression(Date())
        """#
      }
    }

    @Test func queryValueType() {
      assertMacro {
        #"""
        \(date) < #bind(Date(), as: Date.UnixTimeRepresentation.self)
        """#
      } expansion: {
        #"""
        \(date) < StructuredQueriesCore.BindQueryExpression(Date(), as: Date.UnixTimeRepresentation.self)
        """#
      }
    }
  }
}
