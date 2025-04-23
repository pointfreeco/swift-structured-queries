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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foo"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let c1 = StructuredQueries.TableColumn<QueryValue, Swift.Bool>("c1", keyPath: \QueryValue.c1, default: true)
            public let c2 = StructuredQueries.TableColumn<QueryValue, Swift.Int>("c2", keyPath: \QueryValue.c2, default: 1)
            public let c3 = StructuredQueries.TableColumn<QueryValue, Swift.Double>("c3", keyPath: \QueryValue.c3, default: 1.2)
            public let c4 = StructuredQueries.TableColumn<QueryValue, Swift.String>("c4", keyPath: \QueryValue.c4, default: "")
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.c1, QueryValue.columns.c2, QueryValue.columns.c3, QueryValue.columns.c4]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Int>("Bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
          @Column(as: Date.ISO8601Representation.self)
          var bar: Date
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Date
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Date.ISO8601Representation>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
            let bar = try decoder.decode(Date.ISO8601Representation.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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

    @Test func dateDiagnostic() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar: Date
        }
        """
      } diagnostics: {
        """
        @Table
        struct Foo {
          var bar: Date
          ┬────────────
          ╰─ 🛑 'Date' column requires a query representation
             ✏️ Insert '@Column(as: Date.ISO8601Representation.self)'
             ✏️ Insert '@Column(as: Date.UnixTimeRepresentation.self)'
             ✏️ Insert '@Column(as: Date.JulianDayRepresentation.self)'
        }
        """
      } fixes: {
        """
        @Table
        struct Foo {
          @Column(as: Date.ISO8601Representation.self)
          var bar: Date
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Date
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Date.ISO8601Representation>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
            let bar = try decoder.decode(Date.ISO8601Representation.self)
            guard let bar else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func optionalDateDiagnostic() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar: Date?
        }
        """
      } diagnostics: {
        """
        @Table
        struct Foo {
          var bar: Date?
          ┬─────────────
          ╰─ 🛑 'Date' column requires a query representation
             ✏️ Insert '@Column(as: Date.ISO8601Representation?.self)'
             ✏️ Insert '@Column(as: Date.UnixTimeRepresentation?.self)'
             ✏️ Insert '@Column(as: Date.JulianDayRepresentation?.self)'
        }
        """
      } fixes: {
        """
        @Table
        struct Foo {
          @Column(as: Date.ISO8601Representation?.self)
          var bar: Date?
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Date?
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Date.ISO8601Representation?>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
            self.bar = try decoder.decode(Date.ISO8601Representation.self)
          }
        }
        """#
      }
    }

    @Test func optionalTypeDateDiagnostic() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar: Optional<Date>
        }
        """
      } diagnostics: {
        """
        @Table
        struct Foo {
          var bar: Optional<Date>
          ┬──────────────────────
          ╰─ 🛑 'Date' column requires a query representation
             ✏️ Insert '@Column(as: Date.ISO8601Representation?.self)'
             ✏️ Insert '@Column(as: Date.UnixTimeRepresentation?.self)'
             ✏️ Insert '@Column(as: Date.JulianDayRepresentation?.self)'
        }
        """
      } fixes: {
        """
        @Table
        struct Foo {
          @Column(as: Date.ISO8601Representation?.self)
          var bar: Optional<Date>
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar: Optional<Date>
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Date.ISO8601Representation?>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
            self.bar = try decoder.decode(Date.ISO8601Representation.self)
          }
        }
        """#
      }
    }

    @Test func defaultDateDiagnostic() {
      assertMacro {
        """
        @Table
        struct Foo {
          var bar = Date()
        }
        """
      } diagnostics: {
        """
        @Table
        struct Foo {
          var bar = Date()
          ┬───────────────
          ╰─ 🛑 'Date' column requires a query representation
             ✏️ Insert '@Column(as: Date.ISO8601Representation.self)'
             ✏️ Insert '@Column(as: Date.UnixTimeRepresentation.self)'
             ✏️ Insert '@Column(as: Date.JulianDayRepresentation.self)'
        }
        """
      } fixes: {
        """
        @Table
        struct Foo {
          @Column(as: Date.ISO8601Representation.self)
          var bar = Date()
        }
        """
      } expansion: {
        #"""
        struct Foo {
          var bar = Date()
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, Date.ISO8601Representation>("bar", keyPath: \QueryValue.bar, default: Date())
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
            self.bar = try decoder.decode(Date.ISO8601Representation.self) ?? Date()
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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let `bar` = StructuredQueries.TableColumn<QueryValue, Int>("bar", keyPath: \QueryValue.`bar`)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.`bar`]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, ID<Foo>>("bar", keyPath: \QueryValue.bar)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Foo: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueries.TableColumn<QueryValue, _>("bar", keyPath: \QueryValue.bar, default: ID<Foo>())
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.bar]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension User: StructuredQueries.Table, StructuredQueries.PrimaryKeyedTable {
          public struct TableColumns: StructuredQueries.TableDefinition, StructuredQueries.PrimaryKeyedTableDefinition {
            public typealias QueryValue = User
            public let id = StructuredQueries.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>>("id", keyPath: \QueryValue.id)
            public let referrerID = StructuredQueries.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("referrerID", keyPath: \QueryValue.referrerID)
            public var primaryKey: StructuredQueries.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>> {
              self.id
            }
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id, QueryValue.columns.referrerID]
            }
          }
          public struct Draft: StructuredQueries.TableDraft {
            public typealias PrimaryTable = User
            @Column(as: ID<User, UUID.BytesRepresentation>?.self, primaryKey: false) let id: ID<User, UUID>?
            @Column(as: ID<User, UUID.BytesRepresentation>?.self) var referrerID: ID<User, UUID>?
            public struct TableColumns: StructuredQueries.TableDefinition {
              public typealias QueryValue = User.Draft
              public let id = StructuredQueries.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("id", keyPath: \QueryValue.id)
              public let referrerID = StructuredQueries.TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>("referrerID", keyPath: \QueryValue.referrerID)
              public static var allColumns: [any StructuredQueries.TableColumnExpression] {
                [QueryValue.columns.id, QueryValue.columns.referrerID]
              }
            }
            public static let columns = TableColumns()
            public static let tableName = User.tableName
            public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
              self.id = try decoder.decode(ID<User, UUID.BytesRepresentation>.self)
              self.referrerID = try decoder.decode(ID<User, UUID.BytesRepresentation>.self)
            }
            public init(_ other: User) {
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
          public static let columns = TableColumns()
          public static let tableName = "users"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
            let id = try decoder.decode(ID<User, UUID.BytesRepresentation>.self)
            self.referrerID = try decoder.decode(ID<User, UUID.BytesRepresentation>.self)
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
        }

        extension SyncUp: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = SyncUp
            public let name = StructuredQueries.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.name]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "syncUps"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension SyncUp: StructuredQueries.Table, StructuredQueries.PrimaryKeyedTable {
          public struct TableColumns: StructuredQueries.TableDefinition, StructuredQueries.PrimaryKeyedTableDefinition {
            public typealias QueryValue = SyncUp
            public let id = StructuredQueries.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let name = StructuredQueries.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public var primaryKey: StructuredQueries.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id, QueryValue.columns.name]
            }
          }
          public struct Draft: StructuredQueries.TableDraft {
            public typealias PrimaryTable = SyncUp
            @Column(primaryKey: false)
            let id: Int?
            var name: String
            public struct TableColumns: StructuredQueries.TableDefinition {
              public typealias QueryValue = SyncUp.Draft
              public let id = StructuredQueries.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id)
              public let name = StructuredQueries.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
              public static var allColumns: [any StructuredQueries.TableColumnExpression] {
                [QueryValue.columns.id, QueryValue.columns.name]
              }
            }
            public static let columns = TableColumns()
            public static let tableName = SyncUp.tableName
            public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self)
              let name = try decoder.decode(String.self)
              guard let name else {
                throw QueryDecodingError.missingRequiredColumn
              }
              self.name = name
            }
            public init(_ other: SyncUp) {
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
          public static let columns = TableColumns()
          public static let tableName = "syncUps"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension SyncUp: StructuredQueries.Table, StructuredQueries.PrimaryKeyedTable {
          public struct TableColumns: StructuredQueries.TableDefinition, StructuredQueries.PrimaryKeyedTableDefinition {
            public typealias QueryValue = SyncUp
            public let id = StructuredQueries.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let seconds = StructuredQueries.TableColumn<QueryValue, <#Type#>>("seconds", keyPath: \QueryValue.seconds, default: 60 * 5)
            public var primaryKey: StructuredQueries.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id, QueryValue.columns.seconds]
            }
          }
          public struct Draft: StructuredQueries.TableDraft {
            public typealias PrimaryTable = SyncUp
            @Column(primaryKey: false)
            let id: Int?
            var seconds: <#Type#> = 60 * 5
            public struct TableColumns: StructuredQueries.TableDefinition {
              public typealias QueryValue = SyncUp.Draft
              public let id = StructuredQueries.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id)
              public let seconds = StructuredQueries.TableColumn<QueryValue, <#Type#>>("seconds", keyPath: \QueryValue.seconds, default: 60 * 5)
              public static var allColumns: [any StructuredQueries.TableColumnExpression] {
                [QueryValue.columns.id, QueryValue.columns.seconds]
              }
            }
            public static let columns = TableColumns()
            public static let tableName = SyncUp.tableName
            public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self)
              self.seconds = try decoder.decode(<#Type#>.self) ?? 60 * 5
            }
            public init(_ other: SyncUp) {
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
          public static let columns = TableColumns()
          public static let tableName = "syncUps"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension RemindersList: StructuredQueries.Table, StructuredQueries.PrimaryKeyedTable {
          public struct TableColumns: StructuredQueries.TableDefinition, StructuredQueries.PrimaryKeyedTableDefinition {
            public typealias QueryValue = RemindersList
            public let id = StructuredQueries.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let color = StructuredQueries.TableColumn<QueryValue, Color.HexRepresentation>("color", keyPath: \QueryValue.color, default: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255))
            public let name = StructuredQueries.TableColumn<QueryValue, Swift.String>("name", keyPath: \QueryValue.name, default: "")
            public var primaryKey: StructuredQueries.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id, QueryValue.columns.color, QueryValue.columns.name]
            }
          }
          public struct Draft: StructuredQueries.TableDraft {
            public typealias PrimaryTable = RemindersList
            @Column(primaryKey: false)
            var id: Int?
            @Column(as: Color.HexRepresentation.self) var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
            var name = ""
            public struct TableColumns: StructuredQueries.TableDefinition {
              public typealias QueryValue = RemindersList.Draft
              public let id = StructuredQueries.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id)
              public let color = StructuredQueries.TableColumn<QueryValue, Color.HexRepresentation>("color", keyPath: \QueryValue.color, default: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255))
              public let name = StructuredQueries.TableColumn<QueryValue, Swift.String>("name", keyPath: \QueryValue.name, default: "")
              public static var allColumns: [any StructuredQueries.TableColumnExpression] {
                [QueryValue.columns.id, QueryValue.columns.color, QueryValue.columns.name]
              }
            }
            public static let columns = TableColumns()
            public static let tableName = RemindersList.tableName
            public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self)
              self.color = try decoder.decode(Color.HexRepresentation.self) ?? Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
              self.name = try decoder.decode(Swift.String.self) ?? ""
            }
            public init(_ other: RemindersList) {
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
          public static let columns = TableColumns()
          public static let tableName = "remindersLists"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
      }

      extension Foo: StructuredQueries.Table {
        public struct TableColumns: StructuredQueries.TableDefinition {
          public typealias QueryValue = Foo
          public let name = StructuredQueries.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
          public static var allColumns: [any StructuredQueries.TableColumnExpression] {
            [QueryValue.columns.name]
          }
        }
        public static let columns = TableColumns()
        public static let tableName = "foos"
        public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Foo: StructuredQueries.Table, StructuredQueries.PrimaryKeyedTable {
          public struct TableColumns: StructuredQueries.TableDefinition, StructuredQueries.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Foo
            public let id = StructuredQueries.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public var primaryKey: StructuredQueries.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id]
            }
          }
          public struct Draft: StructuredQueries.TableDraft {
            public typealias PrimaryTable = Foo
            @Column(primaryKey: false)
            let id: Int?
            public struct TableColumns: StructuredQueries.TableDefinition {
              public typealias QueryValue = Foo.Draft
              public let id = StructuredQueries.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id)
              public static var allColumns: [any StructuredQueries.TableColumnExpression] {
                [QueryValue.columns.id]
              }
            }
            public static let columns = TableColumns()
            public static let tableName = Foo.tableName
            public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self)
            }
            public init(_ other: Foo) {
              self.id = other.id
            }
            public init(
              id: Int? = nil
            ) {
              self.id = id
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
          }
          public static let columns = Columns()
          public static let tableName = "foos"
          public init(decoder: some StructuredQueries.QueryDecoder) throws {
            self.id = try decoder.decode(Int.self)
          }
        }

        extension Foo.Draft: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Foo.Draft
            public let id = StructuredQueries.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = Foo.tableName
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            guard let id else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
          public init(_ other: Foo) {
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
        }

        extension Foo: StructuredQueries.Table, StructuredQueries.PrimaryKeyedTable {
          public struct TableColumns: StructuredQueries.TableDefinition, StructuredQueries.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Foo
            public let id = StructuredQueries.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let name = StructuredQueries.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
            public var primaryKey: StructuredQueries.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id, QueryValue.columns.name]
            }
          }
          public struct Draft: StructuredQueries.TableDraft {
            public typealias PrimaryTable = Foo
            @Column(primaryKey: false)
            var id: Int?
            var name: String
            public struct TableColumns: StructuredQueries.TableDefinition {
              public typealias QueryValue = Foo.Draft
              public let id = StructuredQueries.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id)
              public let name = StructuredQueries.TableColumn<QueryValue, String>("name", keyPath: \QueryValue.name)
              public static var allColumns: [any StructuredQueries.TableColumnExpression] {
                [QueryValue.columns.id, QueryValue.columns.name]
              }
            }
            public static let columns = TableColumns()
            public static let tableName = Foo.tableName
            public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self)
              let name = try decoder.decode(String.self)
              guard let name else {
                throw QueryDecodingError.missingRequiredColumn
              }
              self.name = name
            }
            public init(_ other: Foo) {
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
          public static let columns = TableColumns()
          public static let tableName = "foos"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Reminder: StructuredQueries.Table, StructuredQueries.PrimaryKeyedTable {
          public struct TableColumns: StructuredQueries.TableDefinition, StructuredQueries.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Reminder
            public let id = StructuredQueries.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let title = StructuredQueries.TableColumn<QueryValue, Swift.String>("title", keyPath: \QueryValue.title, default: "")
            public let date = StructuredQueries.TableColumn<QueryValue, Date.UnixTimeRepresentation?>("date", keyPath: \QueryValue.date)
            public let priority = StructuredQueries.TableColumn<QueryValue, Priority?>("priority", keyPath: \QueryValue.priority)
            public var primaryKey: StructuredQueries.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id, QueryValue.columns.title, QueryValue.columns.date, QueryValue.columns.priority]
            }
          }
          public struct Draft: StructuredQueries.TableDraft {
            public typealias PrimaryTable = Reminder
            @Column(primaryKey: false)
            let id: Int?
            var title = ""
            @Column(as: Date.UnixTimeRepresentation?.self) var date: Date?
            var priority: Priority?
            public struct TableColumns: StructuredQueries.TableDefinition {
              public typealias QueryValue = Reminder.Draft
              public let id = StructuredQueries.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id)
              public let title = StructuredQueries.TableColumn<QueryValue, Swift.String>("title", keyPath: \QueryValue.title, default: "")
              public let date = StructuredQueries.TableColumn<QueryValue, Date.UnixTimeRepresentation?>("date", keyPath: \QueryValue.date)
              public let priority = StructuredQueries.TableColumn<QueryValue, Priority?>("priority", keyPath: \QueryValue.priority)
              public static var allColumns: [any StructuredQueries.TableColumnExpression] {
                [QueryValue.columns.id, QueryValue.columns.title, QueryValue.columns.date, QueryValue.columns.priority]
              }
            }
            public static let columns = TableColumns()
            public static let tableName = Reminder.tableName
            public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self)
              self.title = try decoder.decode(Swift.String.self) ?? ""
              self.date = try decoder.decode(Date.UnixTimeRepresentation.self)
              self.priority = try decoder.decode(Priority.self)
            }
            public init(_ other: Reminder) {
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
          public static let columns = TableColumns()
          public static let tableName = "reminders"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            self.title = try decoder.decode(Swift.String.self) ?? ""
            self.date = try decoder.decode(Date.UnixTimeRepresentation.self)
            self.priority = try decoder.decode(Priority.self)
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
        }

        extension Reminder: StructuredQueries.Table, StructuredQueries.PrimaryKeyedTable {
          public struct TableColumns: StructuredQueries.TableDefinition, StructuredQueries.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Reminder
            public let id = StructuredQueries.TableColumn<QueryValue, UUID.BytesRepresentation>("id", keyPath: \QueryValue.id)
            public var primaryKey: StructuredQueries.TableColumn<QueryValue, UUID.BytesRepresentation> {
              self.id
            }
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id]
            }
          }
          public struct Draft: StructuredQueries.TableDraft {
            public typealias PrimaryTable = Reminder
            @Column(as: UUID.BytesRepresentation?.self, primaryKey: false) let id: UUID?
            public struct TableColumns: StructuredQueries.TableDefinition {
              public typealias QueryValue = Reminder.Draft
              public let id = StructuredQueries.TableColumn<QueryValue, UUID.BytesRepresentation?>("id", keyPath: \QueryValue.id)
              public static var allColumns: [any StructuredQueries.TableColumnExpression] {
                [QueryValue.columns.id]
              }
            }
            public static let columns = TableColumns()
            public static let tableName = Reminder.tableName
            public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
              self.id = try decoder.decode(UUID.BytesRepresentation.self)
            }
            public init(_ other: Reminder) {
              self.id = other.id
            }
            public init(
              id: UUID? = nil
            ) {
              self.id = id
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "reminders"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
        }

        extension Reminder: StructuredQueries.Table {
          public struct TableColumns: StructuredQueries.TableDefinition {
            public typealias QueryValue = Reminder
            public let id = StructuredQueries.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public static var allColumns: [any StructuredQueries.TableColumnExpression] {
              [QueryValue.columns.id]
            }
          }
          public static let columns = TableColumns()
          public static let tableName = "reminders"
          public init(decoder: inout some StructuredQueries.QueryDecoder) throws {
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
  }
}
