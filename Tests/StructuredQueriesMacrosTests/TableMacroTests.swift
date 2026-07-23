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
          @StructuredQueries._ColumnCheck(Int.self)
          var bar: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func selection() {
      assertMacro {
        """
        @Selection
        struct Foo {
          var bar: Int
        }
        """
      } expansion: {
        #"""
        struct Foo {
          @StructuredQueries._ColumnCheck(Int.self)
          var bar: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore._Selection, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
          }
        }
        """#
      }
    }

    @Test func tableSelection() {
      assertMacro {
        """
        @Table @Selection
        struct Foo {
          var bar: Int
        }
        """
      } diagnostics: {
        """
        @Table @Selection
               ┬─────────
               ╰─ ⚠️ '@Table' and '@Selection' should not be applied together

        Apply '@Table' to types representing stored tables, virtual tables, and database views.

        Apply '@Selection' to types representing multiple columns that can be selected from a table or query, and types that represent common table expressions.
                  ✏️ Remove '@Selection'
                  ✏️ Remove '@Table'
        struct Foo {
          var bar: Int
        }
        """
      } fixes: {
        """
        struct Foo {
          var bar: Int
        }
        """
      } expansion: {
        """
        struct Foo {
          var bar: Int
        }
        """
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
          @StructuredQueries._ColumnCheck(Int.self)
          var bar: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foo"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(Int.self)
          var baz: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Bar
            public let baz = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("baz", keyPath: \QueryValue.baz)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.baz._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.baz._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.baz)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Bar
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              baz: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: baz._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "bar"
          }

          public nonisolated static let schemaName: Swift.String? = "foo"
        }

        nonisolated extension Bar: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let baz = try decoder.decode(Self.columns.baz)
            guard let baz else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(Swift.Bool.self)
          var c1 = true
          @StructuredQueries._ColumnCheck(Swift.Int.self)
          var c2 = 1
          @StructuredQueries._ColumnCheck(Swift.Double.self)
          var c3 = 1.2
          @StructuredQueries._ColumnCheck(Swift.String.self)
          var c4 = ""

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let c1 = StructuredQueriesCore._TableColumn<QueryValue, Swift.Bool>.for("c1", keyPath: \QueryValue.c1, default: true)
            public let c2 = StructuredQueriesCore._TableColumn<QueryValue, Swift.Int>.for("c2", keyPath: \QueryValue.c2, default: 1)
            public let c3 = StructuredQueriesCore._TableColumn<QueryValue, Swift.Double>.for("c3", keyPath: \QueryValue.c3, default: 1.2)
            public let c4 = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("c4", keyPath: \QueryValue.c4, default: "")
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.c1._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.c2._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.c3._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.c4._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.c1._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.c2._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.c3._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.c4._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.c1), \(self.c2), \(self.c3), \(self.c4)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              c1: some StructuredQueriesCore.QueryExpression<Swift.Bool> = Swift.Bool(queryOutput: true),
              c2: some StructuredQueriesCore.QueryExpression<Swift.Int> = Swift.Int(queryOutput: 1),
              c3: some StructuredQueriesCore.QueryExpression<Swift.Double> = Swift.Double(queryOutput: 1.2),
              c4: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: c1._allColumns)
              allColumns.append(contentsOf: c2._allColumns)
              allColumns.append(contentsOf: c3._allColumns)
              allColumns.append(contentsOf: c4._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Swift.Bool._columnWidth
            columnWidth += Swift.Int._columnWidth
            columnWidth += Swift.Double._columnWidth
            columnWidth += Swift.String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let c1 = try decoder.decode(Self.columns.c1)
            let c2 = try decoder.decode(Self.columns.c2)
            let c3 = try decoder.decode(Self.columns.c3)
            let c4 = try decoder.decode(Self.columns.c4)
            guard let c1 else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let c2 else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let c3 else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let c4 else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.c1 = c1
            self.c2 = c2
            self.c3 = c3
            self.c4 = c4
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
          @StructuredQueries._ColumnCheck(Int.self)
          var bar: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("Bar", keyPath: \QueryValue.bar)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(Date.UnixTimeRepresentation.self)
          var bar: Date

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, Date.UnixTimeRepresentation>.for("bar", keyPath: \QueryValue.bar)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Date.UnixTimeRepresentation._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(String.self)
          var name: String
          @StructuredQueries._ColumnCheck(String.self)
          let generated: String

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = User
            public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
            public let generated = StructuredQueriesCore.GeneratedColumn<QueryValue, String>("generated", keyPath: \QueryValue.generated)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.generated._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.name), \(self.generated)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              name: some StructuredQueriesCore.QueryExpression<String>,
              generated: some StructuredQueriesCore.QueryExpression<String>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: name._allColumns)
              allColumns.append(contentsOf: generated._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += String._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "users"
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let name = try decoder.decode(Self.columns.name)
            let generated = try decoder.decode(Self.columns.generated)
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let generated else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(String.self)
          var name: String
          @StructuredQueries._ColumnCheck(String.self)
          let generated: String

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = User
            public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
            public let generated = StructuredQueriesCore.GeneratedColumn<QueryValue, String>("generated", keyPath: \QueryValue.generated)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.generated._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.name), \(self.generated)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              name: some StructuredQueriesCore.QueryExpression<String>,
              generated: some StructuredQueriesCore.QueryExpression<String>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: name._allColumns)
              allColumns.append(contentsOf: generated._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += String._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "users"
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let name = try decoder.decode(Self.columns.name)
            let generated = try decoder.decode(Self.columns.generated)
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let generated else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
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
          @StructuredQueries._ColumnCheck(Int.self)
          var bar: Int
          var baz: Int { 42 }

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(Int.self)
          var bar: Int
          static var baz: Int { 42 }

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.bar)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(Int.self)
          var `bar`: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let `bar` = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("bar", keyPath: \QueryValue.`bar`)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.`bar`._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.`bar`._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.`bar`)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              `bar`: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: `bar`._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let `bar` = try decoder.decode(Self.columns.`bar`)
            guard let `bar` else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(ID<Self>.self)
          var bar: ID<Self>

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, ID<Foo>>.for("bar", keyPath: \QueryValue.bar)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression<ID<Foo>>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += ID<Foo>._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(ID<Self>())
          var bar = ID<Self>()

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Foo
            public let bar = StructuredQueriesCore._TableColumn<QueryValue, _>.for("bar", keyPath: \QueryValue.bar, default: ID<Foo>())
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.bar._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.bar._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.bar)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              bar: some StructuredQueriesCore.QueryExpression
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: bar._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += StructuredQueriesCore._columnWidth(\QueryValue.bar)
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let bar = try decoder.decode(Self.columns.bar)
            guard let bar else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.bar = bar
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
          @StructuredQueries._ColumnCheck(ID<Self, UUID.BytesRepresentation>.self)
          let id: ID<Self, UUID>
          @StructuredQueries._ColumnCheck(ID<Self, UUID.BytesRepresentation>?.self)
          var referrerID: ID<Self, UUID>?

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = User
            public typealias PrimaryKey = ID<User, UUID.BytesRepresentation>
            public let id = StructuredQueriesCore._TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>>.for("id", keyPath: \QueryValue.id)
            public let referrerID = StructuredQueriesCore._TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>.for("referrerID", keyPath: \QueryValue.referrerID, default: nil)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.referrerID._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.referrerID._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.referrerID)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = User
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<ID<User, UUID.BytesRepresentation>>,
              referrerID: some StructuredQueriesCore.QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil)
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: referrerID._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = User
            @StructuredQueries._ColumnCheck(ID<User, UUID.BytesRepresentation>?.self) var id: ID<User, UUID>?
            @StructuredQueries._ColumnCheck(ID<User, UUID.BytesRepresentation>?.self) var referrerID: ID<User, UUID>?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let referrerID = StructuredQueriesCore._TableColumn<QueryValue, ID<User, UUID.BytesRepresentation>?>.for("referrerID", keyPath: \QueryValue.referrerID, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.referrerID._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.referrerID._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.referrerID)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil),
                referrerID: some StructuredQueriesCore.QueryExpression<ID<User, UUID.BytesRepresentation>?> = ID<User, UUID.BytesRepresentation>?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: referrerID._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += ID<User, UUID.BytesRepresentation>?._columnWidth
              columnWidth += ID<User, UUID.BytesRepresentation>?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += ID<User, UUID.BytesRepresentation>._columnWidth
            columnWidth += ID<User, UUID.BytesRepresentation>?._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "users"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
            self.referrerID = try decoder.decode(Self.columns.referrerID)
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.referrerID = other.referrerID
          }
        }

        nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            self.referrerID = try decoder.decode(Self.columns.referrerID)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(String.self)
          var name: String
          var computed: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = SyncUp
            public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.name)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = SyncUp
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              name: some StructuredQueriesCore.QueryExpression<String>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: name._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "syncUps"
          }
        }

        nonisolated extension SyncUp: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let name = try decoder.decode(Self.columns.name)
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
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
      } expansion: {
        #"""
        struct SyncUp {
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int
          @StructuredQueries._ColumnCheck(60 * 5)
          var seconds = 60 * 5

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = SyncUp
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let seconds = StructuredQueriesCore._TableColumn<QueryValue, _>.for("seconds", keyPath: \QueryValue.seconds, default: 60 * 5)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.seconds._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.seconds._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.seconds)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = SyncUp
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              seconds: some StructuredQueriesCore.QueryExpression
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: seconds._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = SyncUp
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            @StructuredQueries._ColumnCheck(60 * 5)
            var seconds = 60 * 5

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let seconds = StructuredQueriesCore._TableColumn<QueryValue, _>.for("seconds", keyPath: \QueryValue.seconds, default: 60 * 5)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.seconds._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.seconds._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.seconds)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                seconds: some StructuredQueriesCore.QueryExpression
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: seconds._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += StructuredQueriesCore._columnWidth(\QueryValue.seconds)
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += StructuredQueriesCore._columnWidth(\QueryValue.seconds)
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "syncUps"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
            let seconds = try decoder.decode(Self.columns.seconds)
            guard let seconds else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.seconds = seconds
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.seconds = other.seconds
          }
        }

        nonisolated extension SyncUp: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            let seconds = try decoder.decode(Self.columns.seconds)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let seconds else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.seconds = seconds
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
          @StructuredQueries._ColumnCheck(Int.self)
          var id: Int
          @StructuredQueries._ColumnCheck(Color.HexRepresentation.self)
          var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
          @StructuredQueries._ColumnCheck(Swift.String.self)
          var name = ""

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = RemindersList
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let color = StructuredQueriesCore._TableColumn<QueryValue, Color.HexRepresentation>.for("color", keyPath: \QueryValue.color, default: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255))
            public let name = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("name", keyPath: \QueryValue.name, default: "")
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.color._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.color._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.color), \(self.name)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = RemindersList
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              color: some StructuredQueriesCore.QueryExpression<Color.HexRepresentation> = Color.HexRepresentation(queryOutput: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)),
              name: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: color._allColumns)
              allColumns.append(contentsOf: name._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = RemindersList
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            @StructuredQueries._ColumnCheck(Color.HexRepresentation.self) var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
            @StructuredQueries._ColumnCheck(Swift.String.self)
            var name = ""

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let color = StructuredQueriesCore._TableColumn<QueryValue, Color.HexRepresentation>.for("color", keyPath: \QueryValue.color, default: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255))
              public let name = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("name", keyPath: \QueryValue.name, default: "")
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.color._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.color._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.color), \(self.name)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                color: some StructuredQueriesCore.QueryExpression<Color.HexRepresentation> = Color.HexRepresentation(queryOutput: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)),
                name: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: color._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += Color.HexRepresentation._columnWidth
              columnWidth += Swift.String._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += Color.HexRepresentation._columnWidth
            columnWidth += Swift.String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "remindersLists"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
            let color = try decoder.decode(Self.columns.color)
            let name = try decoder.decode(Self.columns.name)
            guard let color else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.color = color
            self.name = name
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.color = other.color
            self.name = other.name
          }
        }

        nonisolated extension RemindersList: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            let color = try decoder.decode(Self.columns.color)
            let name = try decoder.decode(Self.columns.name)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let color else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.color = color
            self.name = name
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

    @Test func `@Selection with empty struct`() {
      assertMacro {
        """
        @Selection
        struct Foo {
        }
        """
      } diagnostics: {
        """
        @Selection
        ┬─────────
        ╰─ 🛑 '@Selection' requires at least one stored column property to be defined on 'Foo'
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
        @StructuredQueries._ColumnCheck(String.self)
        var name: String {
          willSet { print(newValue) }
        }

        public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
          public typealias QueryValue = Foo
          public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
          #if compiler(>=6.4)
          @_optimize(none)
          #endif
          public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
            var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
            allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
            return allColumns
          }
          #if compiler(>=6.4)
          @_optimize(none)
          #endif
          public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
            var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
            writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
            return writableColumns
          }
          public var queryFragment: QueryFragment {
            "\(self.name)"
          }
        }

        public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
          public typealias QueryValue = Foo
          public let allColumns: [any StructuredQueriesCore.QueryExpression]
          public init(
            name: some StructuredQueriesCore.QueryExpression<String>
          ) {
            var allColumns: [any StructuredQueriesCore.QueryExpression] = []
            allColumns.append(contentsOf: name._allColumns)
            self.allColumns = allColumns
          }
        }

        public typealias QueryValue = Self

        public typealias From = Swift.Never

        public nonisolated static var columns: TableColumns {
          TableColumns()
        }

        public nonisolated static var _columnWidth: Swift.Int {
          var columnWidth = 0
          columnWidth += String._columnWidth
          return columnWidth
        }

        public nonisolated static var tableName: Swift.String {
          "foos"
        }
      }

      nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
        public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
          let name = try decoder.decode(Self.columns.name)
          guard let name else {
            throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
          }
          self.name = name
        }
      }
      """#
    }
  }

  @Test func columnsRepresentation() {
    assertMacro {
      """
      @Selection
      struct RemindersListAliasAndReminderCount {
        @Columns(as: TableAlias<RemindersList, RL>.self)
        let remindersList: RemindersList
        let remindersCount: Int
      }
      """
    } expansion: {
      #"""
      struct RemindersListAliasAndReminderCount {
        @StructuredQueries._ColumnCheck(TableAlias<RemindersList, RL>.self)
        let remindersList: RemindersList
        @StructuredQueries._ColumnCheck(Int.self)
        let remindersCount: Int

        public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
          public typealias QueryValue = RemindersListAliasAndReminderCount
          public let remindersList = StructuredQueriesCore._TableColumn<QueryValue, TableAlias<RemindersList, RL>>.for("remindersList", keyPath: \QueryValue.remindersList)
          public let remindersCount = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("remindersCount", keyPath: \QueryValue.remindersCount)
          #if compiler(>=6.4)
          @_optimize(none)
          #endif
          public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
            var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
            allColumns.append(contentsOf: QueryValue.columns.remindersList._allColumns)
            allColumns.append(contentsOf: QueryValue.columns.remindersCount._allColumns)
            return allColumns
          }
          #if compiler(>=6.4)
          @_optimize(none)
          #endif
          public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
            var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
            writableColumns.append(contentsOf: QueryValue.columns.remindersList._writableColumns)
            writableColumns.append(contentsOf: QueryValue.columns.remindersCount._writableColumns)
            return writableColumns
          }
          public var queryFragment: QueryFragment {
            "\(self.remindersList), \(self.remindersCount)"
          }
        }

        public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
          public typealias QueryValue = RemindersListAliasAndReminderCount
          public let allColumns: [any StructuredQueriesCore.QueryExpression]
          public init(
            remindersList: some StructuredQueriesCore.QueryExpression<TableAlias<RemindersList, RL>>,
            remindersCount: some StructuredQueriesCore.QueryExpression<Int>
          ) {
            var allColumns: [any StructuredQueriesCore.QueryExpression] = []
            allColumns.append(contentsOf: remindersList._allColumns)
            allColumns.append(contentsOf: remindersCount._allColumns)
            self.allColumns = allColumns
          }
        }

        public typealias QueryValue = Self

        public typealias From = Swift.Never

        public nonisolated static var columns: TableColumns {
          TableColumns()
        }

        public nonisolated static var _columnWidth: Swift.Int {
          var columnWidth = 0
          columnWidth += TableAlias<RemindersList, RL>._columnWidth
          columnWidth += Int._columnWidth
          return columnWidth
        }

        public nonisolated static var tableName: Swift.String {
          "remindersListAliasAndReminderCounts"
        }
      }

      nonisolated extension RemindersListAliasAndReminderCount: StructuredQueriesCore.Table, StructuredQueriesCore._Selection, StructuredQueriesCore.PartialSelectStatement {
        public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
          let remindersList = try decoder.decode(Self.columns.remindersList)
          let remindersCount = try decoder.decode(Self.columns.remindersCount)
          guard let remindersList else {
            throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
          }
          guard let remindersCount else {
            throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
          }
          self.remindersList = remindersList
          self.remindersCount = remindersCount
        }
      }
      """#
    }
  }

  #if CasePaths
    @Test func enumBasics() {
      assertMacro {
        """
        @Table
        enum Post {
          @Columns
          case photo(Photo)
          case note(String = "")
        }
        """
      } expansion: {
        #"""
        enum Post {
          @StructuredQueries._CaseCheck(Photo.self) @StructuredQueries._ColumnCheck(Photo.self)
          case photo(Photo)
          @StructuredQueries._CaseCheck(String.self) @StructuredQueries._ColumnCheck(String.self)
          case note(String = "")

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Post
            public let photo = StructuredQueriesCore._TableColumn<QueryValue, Photo?>.for("photo", keyPath: \QueryValue.photo)
            public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: "")
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.photo._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.photo._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.photo), \(self.note)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Post
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public static func photo(
              _ photo: some StructuredQueriesCore.QueryExpression<Photo>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: photo._allColumns)
              allColumns.append(contentsOf: String?(queryOutput: nil)._allColumns)
              return Self(allColumns: allColumns)
            }
            public static func note(
              _ note: some StructuredQueriesCore.QueryExpression<String>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: Photo?(queryOutput: nil)._allColumns)
              allColumns.append(contentsOf: note._allColumns)
              return Self(allColumns: allColumns)
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Photo._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "posts"
          }

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Post) -> CasePaths.PartialCaseKeyPath<Post> {
              if root.is(\.photo) {
                return \.photo
              }
              if root.is(\.note) {
                return \.note
              }
              return \.never
            }
            public var photo: CasePaths.AnyCasePath<Post, Photo> {
              ._$embed(Post.photo) {
                guard case let .photo(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var note: CasePaths.AnyCasePath<Post, String> {
              ._$embed(Post.note) {
                guard case let .note(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Post>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Post>] = []
              allCasePaths.append(\.photo)
              allCasePaths.append(\.note)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        nonisolated extension Post: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let photo = try decoder.decode(Self.columns.photo) ?? nil
            let note = try decoder.decode(Self.columns.note) ?? nil
            if let photo {
              self = .photo(photo)
            } else if let note {
              self = .note(note)
            } else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
          }
        }

        extension Post: CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }

    @Test func enumDiagnostic() {
      assertMacro {
        """
        @Table
        enum Post {
          case photo(Photo)
          case note(String = "")
        }
        """
      } expansion: {
        #"""
        enum Post {
          @StructuredQueries._CaseCheck(Photo.self) @StructuredQueries._ColumnCheck(Photo.self)
          case photo(Photo)
          @StructuredQueries._CaseCheck(String.self) @StructuredQueries._ColumnCheck(String.self)
          case note(String = "")

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Post
            public let photo = StructuredQueriesCore._TableColumn<QueryValue, Photo?>.for("photo", keyPath: \QueryValue.photo)
            public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: "")
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.photo._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.photo._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.photo), \(self.note)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Post
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public static func photo(
              _ photo: some StructuredQueriesCore.QueryExpression<Photo>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: photo._allColumns)
              allColumns.append(contentsOf: String?(queryOutput: nil)._allColumns)
              return Self(allColumns: allColumns)
            }
            public static func note(
              _ note: some StructuredQueriesCore.QueryExpression<String>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: Photo?(queryOutput: nil)._allColumns)
              allColumns.append(contentsOf: note._allColumns)
              return Self(allColumns: allColumns)
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Photo._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "posts"
          }

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Post) -> CasePaths.PartialCaseKeyPath<Post> {
              if root.is(\.photo) {
                return \.photo
              }
              if root.is(\.note) {
                return \.note
              }
              return \.never
            }
            public var photo: CasePaths.AnyCasePath<Post, Photo> {
              ._$embed(Post.photo) {
                guard case let .photo(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var note: CasePaths.AnyCasePath<Post, String> {
              ._$embed(Post.note) {
                guard case let .note(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Post>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Post>] = []
              allCasePaths.append(\.photo)
              allCasePaths.append(\.note)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        nonisolated extension Post: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let photo = try decoder.decode(Self.columns.photo) ?? nil
            let note = try decoder.decode(Self.columns.note) ?? nil
            if let photo {
              self = .photo(photo)
            } else if let note {
              self = .note(note)
            } else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
          }
        }

        extension Post: CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }

    @Test func enumDiagnostic_SingleLine() {
      assertMacro {
        """
        @Table enum Post {
          case photo(Photo)
          case note(String = "")
        }
        """
      } expansion: {
        #"""
        enum Post {
          @StructuredQueries._CaseCheck(Photo.self) @StructuredQueries._ColumnCheck(Photo.self)
          case photo(Photo)
          @StructuredQueries._CaseCheck(String.self) @StructuredQueries._ColumnCheck(String.self)
          case note(String = "")

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Post
            public let photo = StructuredQueriesCore._TableColumn<QueryValue, Photo?>.for("photo", keyPath: \QueryValue.photo)
            public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: "")
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.photo._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.photo._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.photo), \(self.note)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Post
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public static func photo(
              _ photo: some StructuredQueriesCore.QueryExpression<Photo>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: photo._allColumns)
              allColumns.append(contentsOf: String?(queryOutput: nil)._allColumns)
              return Self(allColumns: allColumns)
            }
            public static func note(
              _ note: some StructuredQueriesCore.QueryExpression<String>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: Photo?(queryOutput: nil)._allColumns)
              allColumns.append(contentsOf: note._allColumns)
              return Self(allColumns: allColumns)
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Photo._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "posts"
          }

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Post) -> CasePaths.PartialCaseKeyPath<Post> {
              if root.is(\.photo) {
                return \.photo
              }
              if root.is(\.note) {
                return \.note
              }
              return \.never
            }
            public var photo: CasePaths.AnyCasePath<Post, Photo> {
              ._$embed(Post.photo) {
                guard case let .photo(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var note: CasePaths.AnyCasePath<Post, String> {
              ._$embed(Post.note) {
                guard case let .note(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Post>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Post>] = []
              allCasePaths.append(\.photo)
              allCasePaths.append(\.note)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        nonisolated extension Post: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let photo = try decoder.decode(Self.columns.photo) ?? nil
            let note = try decoder.decode(Self.columns.note) ?? nil
            if let photo {
              self = .photo(photo)
            } else if let note {
              self = .note(note)
            } else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
          }
        }

        extension Post: CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }

    @Test func enumFirstNames() {
      assertMacro {
        """
        @Table
        enum Post {
          case photo(Photo)
          case note(text: String = "")
        }
        """
      } expansion: {
        #"""
        enum Post {
          @StructuredQueries._CaseCheck(Photo.self) @StructuredQueries._ColumnCheck(Photo.self)
          case photo(Photo)
          @StructuredQueries._CaseCheck(String.self) @StructuredQueries._ColumnCheck(String.self)
          case note(text: String = "")

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Post
            public let photo = StructuredQueriesCore._TableColumn<QueryValue, Photo?>.for("photo", keyPath: \QueryValue.photo)
            public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: "")
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.photo._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.photo._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.photo), \(self.note)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Post
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public static func photo(
              _ photo: some StructuredQueriesCore.QueryExpression<Photo>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: photo._allColumns)
              allColumns.append(contentsOf: String?(queryOutput: nil)._allColumns)
              return Self(allColumns: allColumns)
            }
            public static func note(
              text note: some StructuredQueriesCore.QueryExpression<String>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: Photo?(queryOutput: nil)._allColumns)
              allColumns.append(contentsOf: note._allColumns)
              return Self(allColumns: allColumns)
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Photo._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "posts"
          }

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Post) -> CasePaths.PartialCaseKeyPath<Post> {
              if root.is(\.photo) {
                return \.photo
              }
              if root.is(\.note) {
                return \.note
              }
              return \.never
            }
            public var photo: CasePaths.AnyCasePath<Post, Photo> {
              ._$embed(Post.photo) {
                guard case let .photo(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var note: CasePaths.AnyCasePath<Post, String> {
              ._$embed(Post.note) {
                guard case let .note(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Post>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Post>] = []
              allCasePaths.append(\.photo)
              allCasePaths.append(\.note)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        nonisolated extension Post: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let photo = try decoder.decode(Self.columns.photo) ?? nil
            let note = try decoder.decode(Self.columns.note) ?? nil
            if let photo {
              self = .photo(photo)
            } else if let note {
              self = .note(text: note)
            } else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
          }
        }

        extension Post: CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }

    @Test func enumCustomColumn() {
      assertMacro {
        """
        @Table
        enum Post {
          @Column("note_text")
          case note(text: String = "")
        }
        """
      } expansion: {
        #"""
        enum Post {
          @StructuredQueries._CaseCheck(String.self) @StructuredQueries._ColumnCheck(String.self)
          case note(text: String = "")

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Post
            public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note_text", keyPath: \QueryValue.note, default: "")
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.note)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Post
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public static func note(
              text note: some StructuredQueriesCore.QueryExpression<String>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: note._allColumns)
              return Self(allColumns: allColumns)
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "posts"
          }

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Post) -> CasePaths.PartialCaseKeyPath<Post> {
              if root.is(\.note) {
                return \.note
              }
              return \.never
            }
            public var note: CasePaths.AnyCasePath<Post, String> {
              ._$embed(Post.note) {
                guard case let .note(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Post>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Post>] = []
              allCasePaths.append(\.note)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        nonisolated extension Post: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let note = try decoder.decode(Self.columns.note) ?? nil
            if let note {
              self = .note(text: note)
            } else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
          }
        }

        extension Post: CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }

    @Test func enumCustomRepresentation() {
      assertMacro {
        """
        @Table
        enum Post {
          @Column(as: Date.UnixTimeRepresentation.self)
          case timestamp(Date)
        }
        """
      } expansion: {
        #"""
        enum Post {
          @StructuredQueries._CaseCheck(Date.self) @StructuredQueries._ColumnCheck(Date.UnixTimeRepresentation.self)
          case timestamp(Date)

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Post
            public let timestamp = StructuredQueriesCore._TableColumn<QueryValue, Date.UnixTimeRepresentation?>.for("timestamp", keyPath: \QueryValue.timestamp)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.timestamp._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.timestamp._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.timestamp)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Post
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public static func timestamp(
              _ timestamp: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation>
            ) -> Self {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: timestamp._allColumns)
              return Self(allColumns: allColumns)
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Date.UnixTimeRepresentation._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "posts"
          }

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Post) -> CasePaths.PartialCaseKeyPath<Post> {
              if root.is(\.timestamp) {
                return \.timestamp
              }
              return \.never
            }
            public var timestamp: CasePaths.AnyCasePath<Post, Date> {
              ._$embed(Post.timestamp) {
                guard case let .timestamp(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Post>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Post>] = []
              allCasePaths.append(\.timestamp)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        nonisolated extension Post: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let timestamp = try decoder.decode(Self.columns.timestamp) ?? nil
            if let timestamp {
              self = .timestamp(timestamp)
            } else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
          }
        }

        extension Post: CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }
  #else
    @Test func enumRequiresCasePathsTrait() {
      assertMacro {
        """
        @Table enum Post {
          case photo(String)
        }
        """
      } diagnostics: {
        """
        @Table enum Post {
               ┬───
               ╰─ 🛑 '@Table' can only be applied to enum types when the 'CasePaths' package trait is enabled
          case photo(String)
        }
        """
      }
    }

    @Test func `selection enum requires CasePaths trait`() {
      assertMacro {
        """
        @Selection enum Post {
          case photo(String)
        }
        """
      } diagnostics: {
        """
        @Selection enum Post {
                   ┬───
                   ╰─ 🛑 '@Selection' can only be applied to enum types when the 'CasePaths' package trait is enabled
          case photo(String)
        }
        """
      }
    }
  #endif

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
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Foo
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Foo
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Foo
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "foos"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
          }
        }

        nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
            @StructuredQueries._ColumnCheck(Int.self)
            let id: Int

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              return columnWidth
            }
          }
          public static let columns = Columns()
          public static let tableName = "foos"
          public init(decoder: some StructuredQueries.QueryDecoder) throws {
            self.id = try decoder.decode(Int.self)
          }
        }

        nonisolated extension Foo.Draft {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
          public nonisolated init(_ other: SourceTable) {
            self.id = other.id
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
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int
          @StructuredQueries._ColumnCheck(Swift.String.self)
          var title = ""
          @StructuredQueries._ColumnCheck(Date.UnixTimeRepresentation?.self)
          var date: Date?
          @StructuredQueries._ColumnCheck(Priority?.self)
          var priority: Priority?

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Reminder
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let title = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
            public let date = StructuredQueriesCore._TableColumn<QueryValue, Date.UnixTimeRepresentation?>.for("date", keyPath: \QueryValue.date, default: nil)
            public let priority = StructuredQueriesCore._TableColumn<QueryValue, Priority?>.for("priority", keyPath: \QueryValue.priority, default: nil)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.date._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.priority._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.title._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.date._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.priority._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.title), \(self.date), \(self.priority)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Reminder
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
              date: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation?> = Date.UnixTimeRepresentation?(queryOutput: nil),
              priority: some StructuredQueriesCore.QueryExpression<Priority?> = Priority?(queryOutput: nil)
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: title._allColumns)
              allColumns.append(contentsOf: date._allColumns)
              allColumns.append(contentsOf: priority._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Reminder
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            @StructuredQueries._ColumnCheck(Swift.String.self)
            var title = ""
            @StructuredQueries._ColumnCheck(Date.UnixTimeRepresentation?.self) var date: Date?
            @StructuredQueries._ColumnCheck(Priority?.self)
            var priority: Priority?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let title = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
              public let date = StructuredQueriesCore._TableColumn<QueryValue, Date.UnixTimeRepresentation?>.for("date", keyPath: \QueryValue.date, default: nil)
              public let priority = StructuredQueriesCore._TableColumn<QueryValue, Priority?>.for("priority", keyPath: \QueryValue.priority, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.date._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.priority._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.title._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.date._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.priority._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.title), \(self.date), \(self.priority)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
                date: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation?> = Date.UnixTimeRepresentation?(queryOutput: nil),
                priority: some StructuredQueriesCore.QueryExpression<Priority?> = Priority?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: title._allColumns)
                allColumns.append(contentsOf: date._allColumns)
                allColumns.append(contentsOf: priority._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += Swift.String._columnWidth
              columnWidth += Date.UnixTimeRepresentation?._columnWidth
              columnWidth += Priority?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += Swift.String._columnWidth
            columnWidth += Date.UnixTimeRepresentation?._columnWidth
            columnWidth += Priority?._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "reminders"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
            let title = try decoder.decode(Self.columns.title)
            self.date = try decoder.decode(Self.columns.date)
            self.priority = try decoder.decode(Self.columns.priority)
            guard let title else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.title = title
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.title = other.title
            self.date = other.date
            self.priority = other.priority
          }
        }

        nonisolated extension Reminder: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            let title = try decoder.decode(Self.columns.title)
            self.date = try decoder.decode(Self.columns.date)
            self.priority = try decoder.decode(Self.columns.priority)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let title else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.title = title
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
          @StructuredQueries._ColumnCheck(UUID.BytesRepresentation.self)
          let id: UUID

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Reminder
            public typealias PrimaryKey = UUID.BytesRepresentation
            public let id = StructuredQueriesCore._TableColumn<QueryValue, UUID.BytesRepresentation>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, UUID.BytesRepresentation>.for("id", keyPath: \QueryValue.id)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Reminder
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<UUID.BytesRepresentation>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Reminder
            @StructuredQueries._ColumnCheck(UUID.BytesRepresentation?.self) var id: UUID?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, UUID.BytesRepresentation?>.for("id", keyPath: \QueryValue.id, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<UUID.BytesRepresentation?> = UUID.BytesRepresentation?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += UUID.BytesRepresentation?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += UUID.BytesRepresentation._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "reminders"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
          }
        }

        nonisolated extension Reminder: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Reminder
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Reminder
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              self.allColumns = allColumns
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "reminders"
          }
        }

        nonisolated extension Reminder: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
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
          @StructuredQueries._ColumnCheck(Int?.self)
          let id: Int?  // TODO: Migrate to UUID
          @StructuredQueries._ColumnCheck(Swift.String.self)
          var title = ""

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Reminder
            public typealias PrimaryKey = Int?
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
            public let title = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.title._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.title)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Reminder
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
              title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: title._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Reminder
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?  // TODO: Migrate to UUID
            @StructuredQueries._ColumnCheck(Swift.String.self)
            var title = ""

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let title = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.title._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.title)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: title._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += Swift.String._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int?._columnWidth
            columnWidth += Swift.String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "reminders"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
            let title = try decoder.decode(Self.columns.title)
            guard let title else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.title = title
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.title = other.title
          }
        }

        nonisolated extension Reminder: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
            let title = try decoder.decode(Self.columns.title)
            guard let title else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.title = title
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
          @StructuredQueries._ColumnCheck(ReminderTagID.self)
          let id: ReminderTagID

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = ReminderTag
            public typealias PrimaryKey = ReminderTagID
            public let id = StructuredQueriesCore._TableColumn<QueryValue, ReminderTagID>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, ReminderTagID>.for("id", keyPath: \QueryValue.id)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = ReminderTag
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<ReminderTagID>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = ReminderTag
            @StructuredQueries._ColumnCheck(ReminderTagID?.self) var id: ReminderTagID?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, ReminderTagID?>.for("id", keyPath: \QueryValue.id, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<ReminderTagID?> = ReminderTagID?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += ReminderTagID?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += ReminderTagID._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "remindersTags"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode(Self.columns.id)
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
          }
        }

        nonisolated extension ReminderTag: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Self.columns.id)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
          }
        }
        """#
      }
    }

  }
}
