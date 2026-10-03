import CompilationTesting
import Testing

extension BaseSuite {
  @Suite struct StructuredQueriesCompilationTests {
    @Test func `RawRepresentable but not QueryBindable`() async {
      await assertCompilation {
        """
        enum Priority: Int { case low, medium, high }
        @Table struct Reminder {
          var priority: Priority
          var priorityWithDefault = Priority.low
        }
        """
      } diagnostics: {
        """
        import StructuredQueriesSQLite

        enum Priority: Int { case low, medium, high }
                                      ˄
                                      ╰─ error: type 'Priority' does not conform to protocol 'QueryRepresentable'
        @Table struct Reminder {
          var priority: Priority
          ˄
          ╰─ error: 'Priority' is not representable as a column; conform it to 'QueryBindable' to store it as its raw value (from macro 'StructuredQueries.ColumnCheck')
          ╰─ note: Apply '@Column(as: Priority.RawRepresentation.self)' to store as its raw value
          ╰─ note: Apply '@Column(as:)' to specify a representation
          ╰─ note: Apply '@Ephemeral' to exclude from table
          var priorityWithDefault = Priority.low
          ˄
          ╰─ error: 'Priority.low' is not representable as a column; conform it to 'QueryBindable' to store it as its raw value (from macro 'StructuredQueries.ColumnCheck')
          ╰─ note: Apply '@Column(as:)' to specify a representation
          ╰─ note: Apply '@Ephemeral' to exclude from table
        }
        """
      }
    }

    @Test func `JSON representation`() async {
      await assertCompilation {
        """
        @Table struct Model {
          var strings: [String]
        }
        """
      } diagnostics: {
        """
        import StructuredQueriesSQLite

        @Table struct Model {
                             ˄
                             ╰─ error: '_TableColumn' requires the types 'String' and 'UInt8' be equivalent
                             ˄
                             ╰─ error: '_TableColumn' requires the types 'String' and 'UInt8' be equivalent
          var strings: [String]
          ˄
          ╰─ error: '[String]' is not representable as a column (from macro 'StructuredQueries.ColumnCheck')
          ╰─ note: Apply '@Column(as: [String].JSONRepresentation.self)' to store as JSON
          ╰─ note: Apply '@Column(as: [String].JSONBRepresentation.self)' to store as JSONB
          ╰─ note: Apply '@Column(as:)' to specify a representation
          ╰─ note: Apply '@Ephemeral' to exclude from table
        }
        """
      }
    }

    @Test func `unavailable == and !=`() async {
      await assertCompilation {
        """
        @Table struct Reminder {
          let id: Int
        }
        let _ = Reminder.where { $0.id == 1 }
        let _ = Reminder.where { $0.id != 1 }
        """
      } diagnostics: {
        """
        import StructuredQueriesSQLite

        @Table struct Reminder {
          let id: Int
        }
        let _ = Reminder.where { $0.id == 1 }
                                       ˄
                                       ╰─ error: '==' is unavailable: Use 'eq' (or 'is') instead.
        let _ = Reminder.where { $0.id != 1 }
                                       ˄
                                       ╰─ error: '!=' is unavailable: Use 'neq' or 'isNot' instead.
        """
      }
    }

    @Test func `assigning custom representation without #bind`() async {
      await assertCompilation {
        """
        import Foundation
        @Table struct Reminder {
          @Column(as: UUID.UppercasedRepresentation.self)
          var id: UUID
        }
        _ = Reminder.update { $0.id = UUID() }
        """
      } diagnostics: {
        """
        import StructuredQueriesSQLite

        import Foundation
        @Table struct Reminder {
          @Column(as: UUID.UppercasedRepresentation.self)
          var id: UUID
        }
        _ = Reminder.update { $0.id = UUID() }
                              ˄
                              ╰─ error: 'subscript(dynamicMember:)' is unavailable: Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
        """
      }
    }

    @Test func `deprecated count property`() async {
      await assertCompilation {
        """
        @Table struct Model {
          var value = ""
        }
        _ = Model.select { $0.value.count }
        """
      } diagnostics: {
        """
        import StructuredQueriesSQLite

        @Table struct Model {
          var value = ""
        }
        _ = Model.select { $0.value.count }
                                    ˄
                                    ╰─ warning: 'count' is deprecated: Use 'count()' for SQL's 'count' aggregate function, or 'length()' [#DeprecatedDeclaration]
        """
      }
    }

    @Test func `deprecated string interpolation`() async {
      await assertCompilation {
        #"""
        @Table struct Model {
          var value = ""
        }
        _ = "\(Model.value)"
        """#
      } diagnostics: {
        #"""
        import StructuredQueriesSQLite

        @Table struct Model {
          var value = ""
        }
        _ = "\(Model.value)"
              ˄
              ╰─ warning: 'appendInterpolation' is deprecated: String interpolation produces a debug description for a SQL expression. Use '+' to concatenate SQL expressions, instead." [#DeprecatedDeclaration]
        """#
      }
    }
  }
}
