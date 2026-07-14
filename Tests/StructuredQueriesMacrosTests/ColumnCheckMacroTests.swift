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
             ✏️ Apply '@Column(as: [String].JSONBRepresentation.self)' to store as JSONB
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
          ╰─ 🛑 'NotRepresentable()' is not a '@Selection' or representable as a column
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

    @Test func groupWithName() {
      assertMacro([
        "_ColumnCheck": ColumnCheckGroupMacro.self
      ]) {
        """
        struct Row {
          @Column("addr")
          @_ColumnCheck(Address.self)
          var address: Address
        }
        """
      } diagnostics: {
        """
        struct Row {
          @Column("addr")
                  ┬─────
                  ╰─ 🛑 Column name cannot be applied to a column group
                     ✏️ Remove '"addr"'
          @_ColumnCheck(Address.self)
          var address: Address
        }
        """
      } fixes: {
        """
        struct Row {
          @Column
          @_ColumnCheck(Address.self)
          var address: Address
        }
        """
      } expansion: {
        """
        struct Row {
          @Column
          var address: Address
        }
        """
      }
    }

    @Test func groupWithGenerated() {
      assertMacro([
        "_ColumnCheck": ColumnCheckGroupMacro.self
      ]) {
        """
        struct Row {
          @Column(generated: .stored, primaryKey: true)
          @_ColumnCheck(Address.self)
          let address: Address
        }
        """
      } diagnostics: {
        """
        struct Row {
          @Column(generated: .stored, primaryKey: true)
                  ┬──────────────────
                  ╰─ 🛑 Argument 'generated' cannot be applied to a column group
                     ✏️ Remove 'generated: .stored'
          @_ColumnCheck(Address.self)
          let address: Address
        }
        """
      } fixes: {
        """
        struct Row {
          @Column(primaryKey: true)
          @_ColumnCheck(Address.self)
          let address: Address
        }
        """
      } expansion: {
        """
        struct Row {
          @Column(primaryKey: true)
          let address: Address
        }
        """
      }
    }

    @Test func groupPass() {
      assertMacro([
        "_ColumnCheck": ColumnCheckGroupMacro.self
      ]) {
        """
        struct Row {
          @Column(as: Address.self, primaryKey: true)
          @_ColumnCheck(Address.self)
          var address: Address
        }
        """
      } expansion: {
        """
        struct Row {
          @Column(as: Address.self, primaryKey: true)
          var address: Address
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
