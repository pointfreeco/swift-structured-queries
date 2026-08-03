import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct ColumnCheckMacroTests {
    @Test func codable() {
      assertMacro([
        "ColumnCheck": ColumnCheckFailJSONMacro.self
      ]) {
        """
        struct Row {
          @ColumnCheck([String].self)
          var tags: [String]
        }
        """
      } diagnostics: {
        """
        struct Row {
          @ColumnCheck([String].self)
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
        "ColumnCheck": ColumnCheckFailMacro.self
      ]) {
        """
        struct Row {
          @ColumnCheck(NotRepresentable.self)
          var value: NotRepresentable
        }
        """
      } diagnostics: {
        """
        struct Row {
          @ColumnCheck(NotRepresentable.self)
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
        "ColumnCheck": ColumnCheckFailMacro.self
      ]) {
        """
        struct Row {
          @ColumnCheck(NotRepresentable())
          var value = NotRepresentable()
        }
        """
      } diagnostics: {
        """
        struct Row {
          @ColumnCheck(NotRepresentable())
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
        "ColumnCheck": ColumnCheckGroupMacro.self
      ]) {
        """
        struct Row {
          @Column("addr")
          @ColumnCheck(Address.self)
          var address: Address
        }
        """
      } expansion: {
        """
        struct Row {
          @Column("addr")
          var address: Address
        }
        """
      }
    }

    @Test func groupWithGenerated() {
      assertMacro([
        "ColumnCheck": ColumnCheckGroupMacro.self
      ]) {
        """
        struct Row {
          @Column(generated: .stored, primaryKey: true)
          @ColumnCheck(Address.self)
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
          @ColumnCheck(Address.self)
          let address: Address
        }
        """
      } fixes: {
        """
        struct Row {
          @Column(primaryKey: true)
          @ColumnCheck(Address.self)
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
        "ColumnCheck": ColumnCheckGroupMacro.self
      ]) {
        """
        struct Row {
          @Column(as: Address.self, primaryKey: true)
          @ColumnCheck(Address.self)
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
        "ColumnCheck": ColumnCheckPassMacro.self
      ]) {
        """
        struct Row {
          @ColumnCheck(Int.self)
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
