import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct TableMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar: Int
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [bar._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Int.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func comment() {
      assertMacro {
        """
        @Table
        struct User {
          /// The user's identifier.
          let id: /* TODO: UUID */Int
          /// The user's email.
          var email: String?  // TODO: Should this be non-optional?
          /// The user's age.
          var age: Int
        }
        """
      } expansion: {
        #"""
        struct User {
          /// The user's identifier.
          let id: /* TODO: UUID */Int
          /// The user's email.
          var email: String?  // TODO: Should this be non-optional?
          /// The user's age.
          var age: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = User
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let email = StructuredQueriesCore.TableColumn<QueryValue, String?>("email", keyPath: \QueryValue.email, default: nil)
            public let age = StructuredQueriesCore.TableColumn<QueryValue, Int>("age", keyPath: \QueryValue.age)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.email], [QueryValue.columns.age]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.email], [QueryValue.columns.age]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.email), \(self.age)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              email: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil),
              age: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [id._allColumns, email._allColumns, age._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = User
            let id: /* TODO: UUID */ Int?
            var email: String?
            var age: Int
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let email = StructuredQueriesCore.TableColumn<QueryValue, String?>("email", keyPath: \QueryValue.email, default: nil)
              public let age = StructuredQueriesCore.TableColumn<QueryValue, Int>("age", keyPath: \QueryValue.age)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.email], [QueryValue.columns.age]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.email], [QueryValue.columns.age]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.email), \(self.age)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                email: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil),
                age: some StructuredQueriesCore.QueryExpression<Int>
              ) {
                self.allColumns = [id._allColumns, email._allColumns, age._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              User.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              self.email = try decoder.decode(String.self) ?? nil
              let age = try decoder.decode(Int.self)
              guard let age else {
                throw QueryDecodingError.missingRequiredColumn
              }
              self.age = age
            }

            public nonisolated init(_ other: User) {
              self.id = other.id
              self.email = other.email
              self.age = other.age
            }
            public init(
              id: /* TODO: UUID */ Int? = nil,
              email: String? = nil,
              age: Int
            ) {
              self.id = id
              self.email = email
              self.age = age
            }
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "users"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            self.email = try decoder.decode(String.self) ?? nil
            let age = try decoder.decode(Int.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let age else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.age = age
          }
        }
        """#
      }
    }

    @Test func tableName() {
      assertMacro {
        """
        @Table("foo")
        struct Foo {
          var bar: Int
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [bar._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foo"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Int.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func tableNameNil() {
      assertMacro {
        """
        @Table(nil)
        struct Foo {
          var bar: Int
        }
        """
      } diagnostics: {
        """
        @Table(nil)
               ┬──
               ╰─ 🛑 Argument must be a non-empty string literal
        struct Foo {
          var bar: Int
        }
        """
      }
    }

    @Test func tableNameEmpty() {
      assertMacro {
        """
        @Table("")
        struct Foo {
          var bar: Int
        }
        """
      } diagnostics: {
        """
        @Table("")
               ┬─
               ╰─ 🛑 Argument must be a non-empty string literal
        struct Foo {
          var bar: Int
        }
        """
      }
    }

    @Test func schemaName() {
      assertMacro {
        """
        @Table("bar", schema: "foo")
        struct Bar {
          var baz: Int
        }
        """
      } expansion: {
        #"""
        struct Bar {
          var baz: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Bar
            public let baz = StructuredQueriesCore.TableColumn<QueryValue, Int>("baz", keyPath: \QueryValue.baz)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.baz]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.baz]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.baz)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Bar
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              baz: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [baz._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Bar: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "bar"
          }
          public nonisolated static let schemaName: Swift.String? = "foo"
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let baz = try decoder.decode(Int.self)
            guard let baz else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.baz = baz
          }
        }
        """#
      }
    }

    @Test func schemaNameNil() {
      assertMacro {
        """
        @Table(schema: nil)
        struct Foo {
          var bar: Int
        }
        """
      } diagnostics: {
        """
        @Table(schema: nil)
                       ┬──
                       ╰─ 🛑 Argument must be a non-empty string literal
        struct Foo {
          var bar: Int
        }
        """
      }
    }

    @Test func schemaNameEmpty() {
      assertMacro {
        """
        @Table(schema: "")
        struct Foo {
          var bar: Int
        }
        """
      } diagnostics: {
        """
        @Table(schema: "")
                       ┬─
                       ╰─ 🛑 Argument must be a non-empty string literal
        struct Foo {
          var bar: Int
        }
        """
      }
    }

    @Test func literals() {
      assertMacro {
        """
        @Table
        struct Foo {
          var c1 = true
          var c2 = 1
          var c3 = 1.2
          var c4 = ""
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var c1 = true
          var c2 = 1
          var c3 = 1.2
          var c4 = ""

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let c1 = StructuredQueriesCore.TableColumn<QueryValue, Swift.Bool>("c1", keyPath: \QueryValue.c1, default: true)
            public let c2 = StructuredQueriesCore.TableColumn<QueryValue, Swift.Int>("c2", keyPath: \QueryValue.c2, default: 1)
            public let c3 = StructuredQueriesCore.TableColumn<QueryValue, Swift.Double>("c3", keyPath: \QueryValue.c3, default: 1.2)
            public let c4 = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>("c4", keyPath: \QueryValue.c4, default: "")
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.c1], [QueryValue.columns.c2], [QueryValue.columns.c3], [QueryValue.columns.c4]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.c1], [QueryValue.columns.c2], [QueryValue.columns.c3], [QueryValue.columns.c4]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.c1), \(self.c2), \(self.c3), \(self.c4)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              c1: some StructuredQueriesCore.QueryExpression<Swift.Bool> = Swift.Bool(queryOutput: true),
              c2: some StructuredQueriesCore.QueryExpression<Swift.Int> = Swift.Int(queryOutput: 1),
              c3: some StructuredQueriesCore.QueryExpression<Swift.Double> = Swift.Double(queryOutput: 1.2),
              c4: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
            ) {
              self.allColumns = [c1._allColumns, c2._allColumns, c3._allColumns, c4._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.c1 = try decoder.decode(Swift.Bool.self) ?? true
            self.c2 = try decoder.decode(Swift.Int.self) ?? 1
            self.c3 = try decoder.decode(Swift.Double.self) ?? 1.2
            self.c4 = try decoder.decode(Swift.String.self) ?? ""
          }
        }
        """#
      }
    }

    @Test func columnName() {
      assertMacro {
        """
        @Table
        struct Foo {
          @Column("Bar")
          var bar: Int
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore.TableColumn<QueryValue, Int>("Bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [bar._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Int.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func columnNameNil() {
      assertMacro {
        """
        @Table
        struct Foo {
          @Column(nil)
          var bar: Int
        }
        """
      } diagnostics: {
        """
        @Table
        struct Foo {
          @Column(nil)
                  ┬──
                  ╰─ 🛑 Argument must be a non-empty string literal
          var bar: Int
        }
        """
      }
    }

    @Test func columnNameEmpty() {
      assertMacro {
        """
        @Table
        struct Foo {
          @Column("")
          var bar: Int
        }
        """
      } diagnostics: {
        """
        @Table
        struct Foo {
          @Column("")
                  ┬─
                  ╰─ 🛑 Argument must be a non-empty string literal
          var bar: Int
        }
        """
      }
    }

    @Test func representable() {
      assertMacro {
        """
        @Table
        struct Foo {
          @Column(as: Date.UnixTimeRepresentation.self)
          var bar: Date
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Date

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore.TableColumn<QueryValue, Date.UnixTimeRepresentation>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation>
            ) {
              self.allColumns = [bar._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Date.UnixTimeRepresentation.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func columnGenerated() throws {
      assertMacro {
        """
        @Table struct User {
          var name: String
          @Column(generated: .stored)
          let generated: String
        }
        """
      } expansion: {
        #"""
        struct User {
          var name: String
          let generated: String

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = User
            public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public var generated: StructuredQueriesCore.GeneratedColumn<QueryValue, String> {
              StructuredQueriesCore.GeneratedColumn<QueryValue, String>("generated", keyPath: \QueryValue.generated)
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.name], [QueryValue.columns.generated]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.name]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.name), \(self.generated)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              name: some StructuredQueriesCore.QueryExpression<String>,
              generated: some StructuredQueriesCore.QueryExpression<String>
            ) {
              self.allColumns = [name._allColumns, generated._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "users"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let name = try decoder.decode(String.self)
            let generated = try decoder.decode(String.self)
            guard let name else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let generated else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.name = name
            self.generated = generated
          }
        }
        """#
      }
    }

    @Test func columnGeneratedDiagnostic() throws {
      assertMacro {
        """
        @Table struct User {
          var name: String
          @Column(generated: .stored)
          var generated: String
        }
        """
      } diagnostics: {
        """
        @Table struct User {
          var name: String
          @Column(generated: .stored)
          var generated: String
          ┬──
          ╰─ 🛑 Generated column property must be declared with a 'let'
             ✏️ Replace 'var' with 'let'
        }
        """
      } fixes: {
        """
        @Table struct User {
          var name: String
          @Column(generated: .stored)
          let generated: String
        }
        """
      } expansion: {
        #"""
        struct User {
          var name: String
          let generated: String

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = User
            public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public var generated: StructuredQueriesCore.GeneratedColumn<QueryValue, String> {
              StructuredQueriesCore.GeneratedColumn<QueryValue, String>("generated", keyPath: \QueryValue.generated)
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.name], [QueryValue.columns.generated]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.name]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.name), \(self.generated)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              name: some StructuredQueriesCore.QueryExpression<String>,
              generated: some StructuredQueriesCore.QueryExpression<String>
            ) {
              self.allColumns = [name._allColumns, generated._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "users"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let name = try decoder.decode(String.self)
            let generated = try decoder.decode(String.self)
            guard let name else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let generated else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.name = name
            self.generated = generated
          }
        }
        """#
      }
    }

    @Test func columnGeneratedPrimaryKeyedTable() throws {
      assertMacro {
        """
        @Table struct User {
          let id: Int
          var name: String
          @Column(generated: .stored)
          let generated: Int
        }
        """
      } expansion: {
        #"""
        struct User {
          let id: Int
          var name: String
          let generated: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = User
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public var generated: StructuredQueriesCore.GeneratedColumn<QueryValue, Int> {
              StructuredQueriesCore.GeneratedColumn<QueryValue, Int>("generated", keyPath: \QueryValue.generated)
            }
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.name], [QueryValue.columns.generated]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.name), \(self.generated)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              name: some StructuredQueriesCore.QueryExpression<String>,
              generated: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [id._allColumns, name._allColumns, generated._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = User
            let id: Int?
            var name: String
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                name: some StructuredQueriesCore.QueryExpression<String>
              ) {
                self.allColumns = [id._allColumns, name._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              User.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              let name = try decoder.decode(String.self)
              guard let name else {
                throw QueryDecodingError.missingRequiredColumn
              }
              self.name = name
            }

            public nonisolated init(_ other: User) {
              self.id = other.id
              self.name = other.name
            }
            public init(
              id: Int? = nil,
              name: String
            ) {
              self.id = id
              self.name = name
            }
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "users"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            let name = try decoder.decode(String.self)
            let generated = try decoder.decode(Int.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let generated else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.name = name
            self.generated = generated
          }
        }
        """#
      }
    }

    @Test func computed() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar: Int
          var baz: Int { 42 }
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Int
          var baz: Int { 42 }

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [bar._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Int.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func `static`() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar: Int
          static var baz: Int { 42 }
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Int
          static var baz: Int { 42 }

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [bar._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Int.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func backticks() {
      assertMacro {
        """
        @Table
        struct Foo {
          var `bar`: Int
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var `bar`: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let `bar` = StructuredQueriesCore.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.`bar`)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.`bar`]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.`bar`]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.`bar`)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              `bar`: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [`bar`._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let `bar` = try decoder.decode(Int.self)
            guard let `bar` else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.`bar` = `bar`
          }
        }
        """#
      }
    }

    @Test func capitalSelf() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar: ID<Self>
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: ID<Self>

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore.TableColumn<QueryValue, ID<Foo>>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<ID<Foo>>
            ) {
              self.allColumns = [bar._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(ID<Foo>.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func capitalSelfDefault() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar = ID<Self>()
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar = ID<Self>()

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore.TableColumn<QueryValue, _>("bar", keyPath: \QueryValue.bar, default: ID<Foo>())
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.bar]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression
            ) {
              self.allColumns = [bar._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.bar = try decoder.decode() ?? ID<Foo>()
          }
        }
        """#
      }
    }

    @Test func capitalSelfPrimaryKey() {
      assertMacro {
        """
        @Table
        struct User {
          @Column(as: ID<Self, UUID.BytesRepresentation>.self)
          let id: ID<Self, UUID>
          @Column(as: ID<Self, UUID.BytesRepresentation>?.self)
          var referrerID: ID<Self, UUID>?
        }
        """
      } expansion: {
        #"""
        struct User {
          let id: ID<Self, UUID>
          var referrerID: ID<Self, UUID>?

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = User
            public typealias PrimaryKey = ID<User, UUID.BytesRepresentation>
            public let id = StructuredQueriesCore.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>>("id", keyPath: \QueryValue.id)
            public let referrerID = StructuredQueriesCore.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("referrerID", keyPath: \QueryValue.referrerID, default: nil)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.referrerID]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.referrerID]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.referrerID)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<ID<User, UUID.BytesRepresentation>>,
              referrerID: some StructuredQueriesCore.QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil)
            ) {
              self.allColumns = [id._allColumns, referrerID._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = User
            let id: ID<User, UUID>?
            var referrerID: ID<User, UUID>?
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("id", keyPath: \QueryValue.id, default: nil)
              public let referrerID = StructuredQueriesCore.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("referrerID", keyPath: \QueryValue.referrerID, default: nil)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.referrerID]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.referrerID]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.referrerID)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil),
                referrerID: some StructuredQueriesCore.QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil)
              ) {
                self.allColumns = [id._allColumns, referrerID._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              User.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(ID<User, UUID.BytesRepresentation>.self) ?? nil
              self.referrerID = try decoder.decode(ID<User, UUID.BytesRepresentation>.self) ?? nil
            }

            public nonisolated init(_ other: User) {
              self.id = other.id
              self.referrerID = other.referrerID
            }
            public init(
              id: ID<User, UUID>? = nil,
              referrerID: ID<User, UUID>? = nil
            ) {
              self.id = id
              self.referrerID = referrerID
            }
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "users"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(ID<User, UUID.BytesRepresentation>.self)
            self.referrerID = try decoder.decode(ID<User, UUID.BytesRepresentation>.self) ?? nil
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }
    }

    @Test func ephemeralField() {
      assertMacro {
        """
        @Table struct SyncUp {
          var name: String
          @Ephemeral
          var computed: Int
        }
        """
      } expansion: {
        #"""
        struct SyncUp {
          var name: String
          var computed: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = SyncUp
            public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.name]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.name]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.name)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = SyncUp
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              name: some StructuredQueriesCore.QueryExpression<String>
            ) {
              self.allColumns = [name._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension SyncUp: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "syncUps"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let name = try decoder.decode(String.self)
            guard let name else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.name = name
          }
        }
        """#
      }
    }

    @Test func ephemeralFieldPrimaryKeyedTable() {
      assertMacro {
        """
        @Table struct SyncUp {
          let id: Int
          var name: String
          @Ephemeral
          var computed: Int
        }
        """
      } expansion: {
        #"""
        struct SyncUp {
          let id: Int
          var name: String
          var computed: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = SyncUp
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.name)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = SyncUp
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              name: some StructuredQueriesCore.QueryExpression<String>
            ) {
              self.allColumns = [id._allColumns, name._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = SyncUp
            let id: Int?
            var name: String
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                name: some StructuredQueriesCore.QueryExpression<String>
              ) {
                self.allColumns = [id._allColumns, name._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              SyncUp.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              let name = try decoder.decode(String.self)
              guard let name else {
                throw QueryDecodingError.missingRequiredColumn
              }
              self.name = name
            }

            public nonisolated init(_ other: SyncUp) {
              self.id = other.id
              self.name = other.name
            }
            public init(
              id: Int? = nil,
              name: String
            ) {
              self.id = id
              self.name = name
            }
          }
        }

        nonisolated extension SyncUp: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "syncUps"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            let name = try decoder.decode(String.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.name = name
          }
        }
        """#
      }
    }

    @Test func noType() {
      assertMacro {
        """
        @Table struct SyncUp {
          let id: Int
          var seconds = 60 * 5
        }
        """
      } diagnostics: {
        """
        @Table struct SyncUp {
          let id: Int
          var seconds = 60 * 5
              ┬───────────────
              ╰─ 🛑 '@Table' requires 'seconds' to have a type annotation in order to generate a memberwise initializer
                 ✏️ Insert ': <#Type#>'
        }
        """
      } fixes: {
        """
        @Table struct SyncUp {
          let id: Int
          var seconds: <#Type#> = 60 * 5
        }
        """
      } expansion: {
        #"""
        struct SyncUp {
          let id: Int
          var seconds: <#Type#> = 60 * 5

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = SyncUp
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let seconds = StructuredQueriesCore.TableColumn<QueryValue, <#Type#>>("seconds", keyPath: \QueryValue.seconds, default: 60 * 5)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.seconds]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.seconds]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.seconds)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = SyncUp
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              seconds: some StructuredQueriesCore.QueryExpression<<#Type#>> = <#Type#>(queryOutput: 60 * 5)
            ) {
              self.allColumns = [id._allColumns, seconds._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = SyncUp
            let id: Int?
            var seconds: <#Type#> = 60 * 5
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let seconds = StructuredQueriesCore.TableColumn<QueryValue, <#Type#>>("seconds", keyPath: \QueryValue.seconds, default: 60 * 5)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.seconds]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.seconds]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.seconds)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                seconds: some StructuredQueriesCore.QueryExpression<<#Type#>> = <#Type#>(queryOutput: 60 * 5)
              ) {
                self.allColumns = [id._allColumns, seconds._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              SyncUp.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              self.seconds = try decoder.decode(<#Type#>.self) ?? 60 * 5
            }

            public nonisolated init(_ other: SyncUp) {
              self.id = other.id
              self.seconds = other.seconds
            }
            public init(
              id: Int? = nil,
              seconds: <#Type#> = 60 * 5
            ) {
              self.id = id
              self.seconds = seconds
            }
          }
        }

        nonisolated extension SyncUp: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "syncUps"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            self.seconds = try decoder.decode(<#Type#>.self) ?? 60 * 5
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }
    }

    @Test func noTypeWithAs() {
      assertMacro {
        """
        @Table
        struct RemindersList: Hashable, Identifiable {
          var id: Int
          @Column(as: Color.HexRepresentation.self)
          var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
          var name = ""
        }
        """
      } expansion: {
        #"""
        struct RemindersList: Hashable, Identifiable {
          var id: Int
          var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
          var name = ""

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = RemindersList
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let color = StructuredQueriesCore.TableColumn<QueryValue, Color.HexRepresentation>("color", keyPath: \QueryValue.color, default: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255))
            public let name = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>("name", keyPath: \QueryValue.name, default: "")
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.color], [QueryValue.columns.name]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.color], [QueryValue.columns.name]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.color), \(self.name)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = RemindersList
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              color: some StructuredQueriesCore.QueryExpression<Color.HexRepresentation> = Color.HexRepresentation(queryOutput: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)),
              name: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
            ) {
              self.allColumns = [id._allColumns, color._allColumns, name._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = RemindersList
            var id: Int?
            var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
            var name = ""
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let color = StructuredQueriesCore.TableColumn<QueryValue, Color.HexRepresentation>("color", keyPath: \QueryValue.color, default: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255))
              public let name = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>("name", keyPath: \QueryValue.name, default: "")
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.color], [QueryValue.columns.name]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.color], [QueryValue.columns.name]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.color), \(self.name)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                color: some StructuredQueriesCore.QueryExpression<Color.HexRepresentation> = Color.HexRepresentation(queryOutput: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)),
                name: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
              ) {
                self.allColumns = [id._allColumns, color._allColumns, name._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              RemindersList.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              self.color = try decoder.decode(Color.HexRepresentation.self) ?? Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
              self.name = try decoder.decode(Swift.String.self) ?? ""
            }

            public nonisolated init(_ other: RemindersList) {
              self.id = other.id
              self.color = other.color
              self.name = other.name
            }
            public init(
              id: Int? = nil,
              color: Color.HexRepresentation.QueryOutput = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255),
              name: Swift.String = ""
            ) {
              self.id = id
              self.color = color
              self.name = name
            }
          }
        }

        nonisolated extension RemindersList: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "remindersLists"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            self.color = try decoder.decode(Color.HexRepresentation.self) ?? Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
            self.name = try decoder.decode(Swift.String.self) ?? ""
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }
    }

    @Test func emptyStruct() {
      assertMacro {
        """
        @Table
        struct Foo {
        }
        """
      } diagnostics: {
        """
        @Table
        ┬─────
        ╰─ 🛑 '@Table' requires at least one stored column property to be defined on 'Foo'
        struct Foo {
        }
        """
      }
    }
  }

  @Test func willSet() {
    assertMacro {
      """
      @Table
      struct Foo {
        var name: String {
          willSet { print(newValue) }
        }
      }
      """
    } expansion: {
      #"""
      struct Foo {
        var name: String {
          willSet { print(newValue) }
        }

        public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
          public typealias QueryValue = Foo
          public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
          public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
            [[QueryValue.columns.name]].flatMap(\.self)
          }
          public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
            [[QueryValue.columns.name]].flatMap(\.self)
          }
          public var queryFragment: QueryFragment {
            "\(self.name)"
          }
        }

        public struct Selection: StructuredQueriesCore.TableExpression {
          public typealias QueryValue = Foo
          public let allColumns: [any StructuredQueriesCore.QueryExpression]
          public init(
            name: some StructuredQueriesCore.QueryExpression<String>
          ) {
            self.allColumns = [name._allColumns].flatMap(\.self)
          }
        }
      }

      nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
        public typealias QueryValue = Self
        public typealias From = Swift.Never
        public nonisolated static var columns: TableColumns {
          TableColumns()
        }
        public nonisolated static var tableName: String {
          "foos"
        }
        public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
          let name = try decoder.decode(String.self)
          guard let name else {
            throw QueryDecodingError.missingRequiredColumn
          }
          self.name = name
        }
      }
      """#
    }
  }

  @MainActor
  @Suite struct PrimaryKeyTests {
    @Test func basics() {
      assertMacro {
        """
        @Table
        struct Foo {
          let id: Int
        }
        """
      } expansion: {
        #"""
        struct Foo {
          let id: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Foo
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [id._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = Foo
            let id: Int?
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil)
              ) {
                self.allColumns = [id._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              Foo.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
            }

            public nonisolated init(_ other: Foo) {
              self.id = other.id
            }
            public init(
              id: Int? = nil
            ) {
              self.id = id
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }

      assertMacro {
        #"""
        struct Foo {
          @Column("id", primaryKey: true)
          let id: Int
        }

        extension Foo: StructuredQueries.Table {
          public struct Columns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let id = StructuredQueries.Column<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public var allColumns: [any StructuredQueries.ColumnExpression] {
              [self.id]
            }
          }
          @_Draft(Foo.self)
          public struct Draft {
            @Column(primaryKey: false)
            let id: Int
          }
          public static let columns = Columns()
          public static let tableName = "foos"
          public init(decoder: some StructuredQueries.QueryDecoder) throws {
            self.id = try decoder.decode(Int.self)
          }
        }
        """#
      } expansion: {
        #"""
        struct Foo {
          let id: Int
        }

        extension Foo: StructuredQueries.Table {
          public struct Columns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let id = StructuredQueries.Column<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public var allColumns: [any StructuredQueries.ColumnExpression] {
              [self.id]
            }
          }
          public struct Draft {
            let id: Int

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id)"
              }
            }

            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>
              ) {
                self.allColumns = [id._allColumns].flatMap(\.self)
              }
            }
          }
          public static let columns = Columns()
          public static let tableName = "foos"
          public init(decoder: some StructuredQueries.QueryDecoder) throws {
            self.id = try decoder.decode(Int.self)
          }
        }

        nonisolated extension Foo.Draft: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            Foo.tableName
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
          public nonisolated init(_ other: Foo) {
            self.id = other.id
          }
        }
        """#
      }
    }

    @Test func willSet() {
      assertMacro {
        """
        @Table
        struct Foo {
          var id: Int {
            willSet { print(newValue) }
          }
          var name: String {
            willSet { print(newValue) }
          }
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var id: Int {
            willSet { print(newValue) }
          }
          var name: String {
            willSet { print(newValue) }
          }

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Foo
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.name)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              name: some StructuredQueriesCore.QueryExpression<String>
            ) {
              self.allColumns = [id._allColumns, name._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = Foo
            var id: Int?
            var name: String
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let name = StructuredQueriesCore.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.name]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                name: some StructuredQueriesCore.QueryExpression<String>
              ) {
                self.allColumns = [id._allColumns, name._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              Foo.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              let name = try decoder.decode(String.self)
              guard let name else {
                throw QueryDecodingError.missingRequiredColumn
              }
              self.name = name
            }

            public nonisolated init(_ other: Foo) {
              self.id = other.id
              self.name = other.name
            }
            public init(
              id: Int? = nil,
              name: String
            ) {
              self.id = id
              self.name = name
            }
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "foos"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            let name = try decoder.decode(String.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.name = name
          }
        }
        """#
      }
    }

    @Test func advanced() {
      assertMacro {
        """
        @Table
        struct Reminder {
          let id: Int
          var title = ""
          @Column(as: Date.UnixTimeRepresentation?.self)
          var date: Date?
          var priority: Priority?
        }
        """
      } expansion: {
        #"""
        struct Reminder {
          let id: Int
          var title = ""
          var date: Date?
          var priority: Priority?

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Reminder
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let title = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>("title", keyPath: \QueryValue.title, default: "")
            public let date = StructuredQueriesCore.TableColumn<QueryValue, Date.UnixTimeRepresentation?>("date", keyPath: \QueryValue.date, default: nil)
            public let priority = StructuredQueriesCore.TableColumn<QueryValue, Priority?>("priority", keyPath: \QueryValue.priority, default: nil)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.title], [QueryValue.columns.date], [QueryValue.columns.priority]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.title], [QueryValue.columns.date], [QueryValue.columns.priority]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.title), \(self.date), \(self.priority)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Reminder
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
              date: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation?> = Date.UnixTimeRepresentation?(queryOutput: nil),
              priority: some StructuredQueriesCore.QueryExpression<Priority?> = Priority?(queryOutput: nil)
            ) {
              self.allColumns = [id._allColumns, title._allColumns, date._allColumns, priority._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = Reminder
            let id: Int?
            var title = ""
            var date: Date?
            var priority: Priority?
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let title = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>("title", keyPath: \QueryValue.title, default: "")
              public let date = StructuredQueriesCore.TableColumn<QueryValue, Date.UnixTimeRepresentation?>("date", keyPath: \QueryValue.date, default: nil)
              public let priority = StructuredQueriesCore.TableColumn<QueryValue, Priority?>("priority", keyPath: \QueryValue.priority, default: nil)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.title], [QueryValue.columns.date], [QueryValue.columns.priority]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.title], [QueryValue.columns.date], [QueryValue.columns.priority]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.title), \(self.date), \(self.priority)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
                date: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation?> = Date.UnixTimeRepresentation?(queryOutput: nil),
                priority: some StructuredQueriesCore.QueryExpression<Priority?> = Priority?(queryOutput: nil)
              ) {
                self.allColumns = [id._allColumns, title._allColumns, date._allColumns, priority._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              Reminder.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              self.title = try decoder.decode(Swift.String.self) ?? ""
              self.date = try decoder.decode(Date.UnixTimeRepresentation.self) ?? nil
              self.priority = try decoder.decode(Priority.self) ?? nil
            }

            public nonisolated init(_ other: Reminder) {
              self.id = other.id
              self.title = other.title
              self.date = other.date
              self.priority = other.priority
            }
            public init(
              id: Int? = nil,
              title: Swift.String = "",
              date: Date? = nil,
              priority: Priority? = nil
            ) {
              self.id = id
              self.title = title
              self.date = date
              self.priority = priority
            }
          }
        }

        nonisolated extension Reminder: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "reminders"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            self.title = try decoder.decode(Swift.String.self) ?? ""
            self.date = try decoder.decode(Date.UnixTimeRepresentation.self) ?? nil
            self.priority = try decoder.decode(Priority.self) ?? nil
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }
    }

    @Test func uuid() {
      assertMacro {
        """
        @Table
        struct Reminder {
          @Column(as: UUID.BytesRepresentation.self)
          let id: UUID
        }
        """
      } expansion: {
        #"""
        struct Reminder {
          let id: UUID

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Reminder
            public typealias PrimaryKey = UUID.BytesRepresentation
            public let id = StructuredQueriesCore.TableColumn<QueryValue, UUID.BytesRepresentation>("id", keyPath: \QueryValue.id)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, UUID.BytesRepresentation> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Reminder
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<UUID.BytesRepresentation>
            ) {
              self.allColumns = [id._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = Reminder
            let id: UUID?
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, UUID.BytesRepresentation?>("id", keyPath: \QueryValue.id, default: nil)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<UUID.BytesRepresentation?> = UUID.BytesRepresentation?(queryOutput: nil)
              ) {
                self.allColumns = [id._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              Reminder.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(UUID.BytesRepresentation.self) ?? nil
            }

            public nonisolated init(_ other: Reminder) {
              self.id = other.id
            }
            public init(
              id: UUID? = nil
            ) {
              self.id = id
            }
          }
        }

        nonisolated extension Reminder: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "reminders"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(UUID.BytesRepresentation.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }
    }

    @Test func turnOffPrimaryKey() {
      assertMacro {
        """
        @Table
        struct Reminder {
          @Column(primaryKey: false)
          let id: Int
        }
        """
      } expansion: {
        #"""
        struct Reminder {
          let id: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Reminder
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Reminder
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.allColumns = [id._allColumns].flatMap(\.self)
            }
          }
        }

        nonisolated extension Reminder: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "reminders"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }
    }

    @Test func commentAfterOptionalID() {
      assertMacro {
        """
        @Table
        struct Reminder {
          let id: Int?  // TODO: Migrate to UUID
          var title = ""
        }
        """
      } expansion: {
        #"""
        struct Reminder {
          let id: Int?  // TODO: Migrate to UUID
          var title = ""

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Reminder
            public typealias PrimaryKey = Int?
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
            public let title = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>("title", keyPath: \QueryValue.title, default: "")
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int?> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.title]].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], [QueryValue.columns.title]].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.title)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Reminder
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
              title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
            ) {
              self.allColumns = [id._allColumns, title._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = Reminder
            let id: Int?  // TODO: Migrate to UUID
            var title = ""
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let title = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>("title", keyPath: \QueryValue.title, default: "")
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.title]].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], [QueryValue.columns.title]].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.title)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
              ) {
                self.allColumns = [id._allColumns, title._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              Reminder.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              self.title = try decoder.decode(Swift.String.self) ?? ""
            }

            public nonisolated init(_ other: Reminder) {
              self.id = other.id
              self.title = other.title
            }
            public init(
              id: Int? = nil,
              title: Swift.String = ""
            ) {
              self.id = id
              self.title = title
            }
          }
        }

        nonisolated extension Reminder: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "reminders"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Int.self) ?? nil
            self.title = try decoder.decode(Swift.String.self) ?? ""
          }
        }
        """#
      }
    }

    @Test func nested() {
      assertMacro {
        """
        @Table
        private struct Row {
          let id: UUID
          @Columns
          var timestamps: Timestamps
        }
        """
      } expansion: {
        #"""
        private struct Row {
          let id: UUID
          var timestamps: Timestamps

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Row
            public typealias PrimaryKey = UUID
            public let id = StructuredQueriesCore.TableColumn<QueryValue, UUID>("id", keyPath: \QueryValue.id)
            public let timestamps = StructuredQueriesCore.ColumnGroup<QueryValue, Timestamps>(keyPath: \QueryValue.timestamps)
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, UUID> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [[QueryValue.columns.id], StructuredQueriesCore.ColumnGroup.allColumns(keyPath: \QueryValue.timestamps)].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [[QueryValue.columns.id], StructuredQueriesCore.ColumnGroup.writableColumns(keyPath: \QueryValue.timestamps)].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.timestamps)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Row
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<UUID>,
              timestamps: some StructuredQueriesCore.QueryExpression<Timestamps>
            ) {
              self.allColumns = [id._allColumns, timestamps._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = Row
            let id: UUID?
            var timestamps: Timestamps
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, UUID?>("id", keyPath: \QueryValue.id, default: nil)
              public let timestamps = StructuredQueriesCore.ColumnGroup<QueryValue, Timestamps>(keyPath: \QueryValue.timestamps)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [[QueryValue.columns.id], StructuredQueriesCore.ColumnGroup.allColumns(keyPath: \QueryValue.timestamps)].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [[QueryValue.columns.id], StructuredQueriesCore.ColumnGroup.writableColumns(keyPath: \QueryValue.timestamps)].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.timestamps)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<UUID?> = UUID?(queryOutput: nil),
                timestamps: some StructuredQueriesCore.QueryExpression<Timestamps>
              ) {
                self.allColumns = [id._allColumns, timestamps._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              Row.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(UUID.self) ?? nil
              let timestamps = try decoder.decode(Timestamps.self)
              guard let timestamps else {
                throw QueryDecodingError.missingRequiredColumn
              }
              self.timestamps = timestamps
            }

            public nonisolated init(_ other: Row) {
              self.id = other.id
              self.timestamps = other.timestamps
            }
            public init(
              id: UUID? = nil,
              timestamps: Timestamps
            ) {
              self.id = id
              self.timestamps = timestamps
            }
          }
        }

        nonisolated extension Row: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "rows"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(UUID.self)
            let timestamps = try decoder.decode(Timestamps.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let timestamps else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.timestamps = timestamps
          }
        }
        """#
      }
    }

    @Test func nestedLet() {
      assertMacro {
        """
        @Table("remindersTags")
        struct ReminderTag: Identifiable {
          @Columns
          let id: ReminderTagID
        }
        """
      } expansion: {
        #"""
        struct ReminderTag: Identifiable {
          let id: ReminderTagID

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = ReminderTag
            public typealias PrimaryKey = ReminderTagID
            public let id = StructuredQueriesCore.ColumnGroup<QueryValue, ReminderTagID>(keyPath: \QueryValue.id)
            public var primaryKey: StructuredQueriesCore.ColumnGroup<QueryValue, ReminderTagID> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [StructuredQueriesCore.ColumnGroup.allColumns(keyPath: \QueryValue.id)].flatMap(\.self)
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [StructuredQueriesCore.ColumnGroup.writableColumns(keyPath: \QueryValue.id)].flatMap(\.self)
            }
            public var queryFragment: QueryFragment {
              "\(self.id)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = ReminderTag
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<ReminderTagID>
            ) {
              self.allColumns = [id._allColumns].flatMap(\.self)
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = ReminderTag
            let id: ReminderTagID?
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.ColumnGroup<QueryValue, ReminderTagID?>(keyPath: \QueryValue.id)
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                [StructuredQueriesCore.ColumnGroup.allColumns(keyPath: \QueryValue.id)].flatMap(\.self)
              }
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                [StructuredQueriesCore.ColumnGroup.writableColumns(keyPath: \QueryValue.id)].flatMap(\.self)
              }
              public var queryFragment: QueryFragment {
                "\(self.id)"
              }
            }
            public struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<ReminderTagID?> = ReminderTagID?(queryOutput: nil)
              ) {
                self.allColumns = [id._allColumns].flatMap(\.self)
              }
            }
            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var tableName: String {
              ReminderTag.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(ReminderTagID.self) ?? nil
            }

            public nonisolated init(_ other: ReminderTag) {
              self.id = other.id
            }
            public init(
              id: ReminderTagID? = nil
            ) {
              self.id = id
            }
          }
        }

        nonisolated extension ReminderTag: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "remindersTags"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(ReminderTagID.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }
    }
  }
}
