import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct ColumnCheckMacroTests {
    @Test func codable() {
      assertMacro([
        "_ColumnCheck": ColumnCheckFailJSONMacro.self
      ]) {
        """
        struct Row {
          @_ColumnCheck([String].self)
          var tags: [String]
        }
        """
      } diagnostics: {
        """
        struct Row {
          @_ColumnCheck([String].self)
          ╰─ 🛑 '[String]' is not representable as a column
             ✏️ Apply '@Column(as: [String].JSONRepresentation.self)' to store as JSON
             ✏️ Apply '@Column(as:)' to specify a representation
             ✏️ Apply '@Ephemeral' to exclude from table
          var tags: [String]
        }
        """
      } fixes: {
        """
        struct Row {
          @Column(as: [String].JSONRepresentation.self) 
          var tags: [String]
        }
        """
      } expansion: {
        """
        struct Row {
          @Column(as: [String].JSONRepresentation.self)
          var tags: [String]
        }
        """
      }
    }

    @Test func notRepresentable() {
      assertMacro([
        "_ColumnCheck": ColumnCheckFailMacro.self
      ]) {
        """
        struct Row {
          @_ColumnCheck(NotRepresentable.self)
          var value: NotRepresentable
        }
        """
      } diagnostics: {
        """
        struct Row {
          @_ColumnCheck(NotRepresentable.self)
          ╰─ 🛑 'NotRepresentable' is not representable as a column
             ✏️ Apply '@Column(as:)' to specify a representation
             ✏️ Apply '@Ephemeral' to exclude from table
          var value: NotRepresentable
        }
        """
      } fixes: {
        """
        struct Row {
          @Column(as: <#QueryRepresentable.Type#>) 
          var value: NotRepresentable
        }
        """
      } expansion: {
        """
        struct Row {
          @Column(as: <#QueryRepresentable.Type#>)
          var value: NotRepresentable
        }
        """
      }
    }

    @Test func notRepresentableInferred() {
      assertMacro([
        "_ColumnCheck": ColumnCheckFailMacro.self
      ]) {
        """
        struct Row {
          @_ColumnCheck(NotRepresentable())
          var value = NotRepresentable()
        }
        """
      } diagnostics: {
        """
        struct Row {
          @_ColumnCheck(NotRepresentable())
          ╰─ 🛑 'NotRepresentable()' is not representable as a column
             ✏️ Apply '@Column(as:)' to specify a representation
             ✏️ Apply '@Ephemeral' to exclude from table
          var value = NotRepresentable()
        }
        """
      } fixes: {
        """
        struct Row {
          @Column(as: <#QueryRepresentable.Type#>) 
          var value = NotRepresentable()
        }
        """
      } expansion: {
        """
        struct Row {
          @Column(as: <#QueryRepresentable.Type#>)
          var value = NotRepresentable()
        }
        """
      }
    }

    @Test func pass() {
      assertMacro([
        "_ColumnCheck": ColumnCheckPassMacro.self
      ]) {
        """
        struct Row {
          @_ColumnCheck(Int.self)
          var count: Int
        }
        """
      } expansion: {
        """
        struct Row {
          var count: Int
        }
        """
      }
    }
  }
}
