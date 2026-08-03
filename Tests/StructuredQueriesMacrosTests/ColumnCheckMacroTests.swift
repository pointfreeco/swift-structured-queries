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

    @Test func rawRepresentable() {
      assertMacro([
        "_ColumnCheck": ColumnCheckFailRawRepresentableMacro.self
      ]) {
        """
        struct Row {
          @_ColumnCheck(Priority.self)
          var priority: Priority
        }
        """
      } diagnostics: {
        """
        struct Row {
          @_ColumnCheck(Priority.self)
          ╰─ 🛑 'Priority' is not representable as a column; conform it to 'QueryBindable' to store it as its raw value
             ✏️ Apply '@Column(as: Priority.RawRepresentation.self)' to store as its raw value
             ✏️ Apply '@Column(as:)' to specify a representation
             ✏️ Apply '@Ephemeral' to exclude from table
          var priority: Priority
        }
        """
      } fixes: {
        """
        struct Row {
          @Column(as: Priority.RawRepresentation.self) 
          var priority: Priority
        }
        """
      } expansion: {
        """
        struct Row {
          @Column(as: Priority.RawRepresentation.self)
          var priority: Priority
        }
        """
      }
    }

    @Test func rawRepresentableOptional() {
      assertMacro([
        "_ColumnCheck": ColumnCheckFailRawRepresentableMacro.self
      ]) {
        """
        struct Row {
          @_ColumnCheck(Priority?.self)
          var priority: Priority?
        }
        """
      } diagnostics: {
        """
        struct Row {
          @_ColumnCheck(Priority?.self)
          ╰─ 🛑 'Priority?' is not representable as a column; conform it to 'QueryBindable' to store it as its raw value
             ✏️ Apply '@Column(as: Priority?.RawRepresentation.self)' to store as its raw value
             ✏️ Apply '@Column(as:)' to specify a representation
             ✏️ Apply '@Ephemeral' to exclude from table
          var priority: Priority?
        }
        """
      } fixes: {
        """
        struct Row {
          @Column(as: Priority?.RawRepresentation.self) 
          var priority: Priority?
        }
        """
      } expansion: {
        """
        struct Row {
          @Column(as: Priority?.RawRepresentation.self)
          var priority: Priority?
        }
        """
      }
    }

    @Test func rawRepresentableInferred() {
      assertMacro([
        "_ColumnCheck": ColumnCheckFailRawRepresentableMacro.self
      ]) {
        """
        struct Row {
          @_ColumnCheck(Priority.high)
          var priority = Priority.high
        }
        """
      } diagnostics: {
        """
        struct Row {
          @_ColumnCheck(Priority.high)
          ╰─ 🛑 'Priority.high' is not representable as a column; conform it to 'QueryBindable' to store it as its raw value
             ✏️ Apply '@Column(as:)' to specify a representation
             ✏️ Apply '@Ephemeral' to exclude from table
          var priority = Priority.high
        }
        """
      } fixes: {
        """
        struct Row {
          @Column(as: <#QueryRepresentable.Type#>) 
          var priority = Priority.high
        }
        """
      } expansion: {
        """
        struct Row {
          @Column(as: <#QueryRepresentable.Type#>)
          var priority = Priority.high
        }
        """
      }
    }
  }
}
