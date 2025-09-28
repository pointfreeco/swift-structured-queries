import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @Suite struct SelectionMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @Selection
        struct PlayerAndTeam {
          let player: Player
          let team: Team
        }
        """
      } diagnostics: {
        """
        @Selection
        ┬─────────
        ╰─ ⚠️ '@Selection' is deprecated: apply the '@Table' macro, instead
           ✏️ Use '@Table' instead
        struct PlayerAndTeam {
          let player: Player
          let team: Team
        }
        """
      } fixes: {
        """
        @Table
        struct PlayerAndTeam {
          let player: Player
          let team: Team
        }
        """
      } expansion: {
        #"""
        struct PlayerAndTeam {
          let player: Player
          let team: Team

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = PlayerAndTeam
            public let player = StructuredQueriesCore._TableColumn<QueryValue, Player>.for("player", keyPath: \QueryValue.player)
            public let team = StructuredQueriesCore._TableColumn<QueryValue, Team>.for("team", keyPath: \QueryValue.team)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.player._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.team._allColumns)
              return allColumns
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.player._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.team._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.player), \(self.team)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = PlayerAndTeam
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              player: some StructuredQueriesCore.QueryExpression<Player>,
              team: some StructuredQueriesCore.QueryExpression<Team>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: player._allColumns)
              allColumns.append(contentsOf: team._allColumns)
              self.allColumns = allColumns
            }
          }
        }

        nonisolated extension PlayerAndTeam: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var columnWidth: Int {
            [Player.columnWidth, Team.columnWidth].reduce(0, +)
          }
          public nonisolated static var tableName: String {
            "playerAndTeams"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let player = try decoder.decode(Player.self)
            let team = try decoder.decode(Team.self)
            guard let player else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let team else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.player = player
            self.team = team
          }
        }
        """#
      }
    }

    @Test func `enum`() {
      assertMacro {
        """
        @Selection
        public enum S {}
        """
      } diagnostics: {
        """
        @Selection
        public enum S {}
               ┬───
               ╰─ 🛑 '@Selection' can only be applied to struct types
        """
      }
    }

    @Test func optionalField() {
      assertMacro {
        """
        @Selection 
        struct ReminderTitleAndListTitle {
          var reminderTitle: String 
          var listTitle: String?
        }
        """
      } diagnostics: {
        """
        @Selection 
        ┬─────────
        ╰─ ⚠️ '@Selection' is deprecated: apply the '@Table' macro, instead
           ✏️ Use '@Table' instead
        struct ReminderTitleAndListTitle {
          var reminderTitle: String 
          var listTitle: String?
        }
        """
      } fixes: {
        """
        @Table
        struct ReminderTitleAndListTitle {
          var reminderTitle: String 
          var listTitle: String?
        }
        """
      } expansion: {
        #"""
        struct ReminderTitleAndListTitle {
          var reminderTitle: String 
          var listTitle: String?

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = ReminderTitleAndListTitle
            public let reminderTitle = StructuredQueriesCore._TableColumn<QueryValue, String>.for("reminderTitle", keyPath: \QueryValue.reminderTitle)
            public let listTitle = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("listTitle", keyPath: \QueryValue.listTitle, default: nil)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.reminderTitle._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.listTitle._allColumns)
              return allColumns
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.reminderTitle._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.listTitle._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.reminderTitle), \(self.listTitle)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = ReminderTitleAndListTitle
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              reminderTitle: some StructuredQueriesCore.QueryExpression<String>,
              listTitle: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: reminderTitle._allColumns)
              allColumns.append(contentsOf: listTitle._allColumns)
              self.allColumns = allColumns
            }
          }
        }

        nonisolated extension ReminderTitleAndListTitle: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var columnWidth: Int {
            [String.columnWidth, String?.columnWidth].reduce(0, +)
          }
          public nonisolated static var tableName: String {
            "reminderTitleAndListTitles"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let reminderTitle = try decoder.decode(String.self)
            self.listTitle = try decoder.decode(String.self) ?? nil
            guard let reminderTitle else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.reminderTitle = reminderTitle
          }
        }
        """#
      }
    }

    @Test func date() {
      assertMacro {
        """
        @Selection struct ReminderDate {
          @Column(as: Date.UnixTimeRepresentation.self)
          var date: Date
        }
        """
      } diagnostics: {
        """
        @Selection struct ReminderDate {
        ┬─────────
        ╰─ ⚠️ '@Selection' is deprecated: apply the '@Table' macro, instead
           ✏️ Use '@Table' instead
          @Column(as: Date.UnixTimeRepresentation.self)
          var date: Date
        }
        """
      } fixes: {
        """
        @Tablestruct ReminderDate {
          @Column(as: Date.UnixTimeRepresentation.self)
          var date: Date
        }
        """
      } expansion: {
        """
        @Tablestruct ReminderDate {
          var date: Date
        }
        """
      }
    }

    @Test func defaults() {
      assertMacro {
        """
        @Selection struct Row {
          var title = ""
          @Column(as: [String].JSONRepresentation.self)
          var notes: [String] = []
        }
        """
      } diagnostics: {
        """
        @Selection struct Row {
        ┬─────────
        ╰─ ⚠️ '@Selection' is deprecated: apply the '@Table' macro, instead
           ✏️ Use '@Table' instead
          var title = ""
          @Column(as: [String].JSONRepresentation.self)
          var notes: [String] = []
        }
        """
      } fixes: {
        """
        @Tablestruct Row {
          var title = ""
          @Column(as: [String].JSONRepresentation.self)
          var notes: [String] = []
        }
        """
      } expansion: {
        """
        @Tablestruct Row {
          var title = ""
          var notes: [String] = []
        }
        """
      }
    }

    @Test func primaryKey() {
      assertMacro {
        """
        @Selection struct Row {
          @Column(primaryKey: true)
          let id: Int
          var title = ""
        }
        """
      } diagnostics: {
        """
        @Selection struct Row {
        ┬─────────
        ╰─ ⚠️ '@Selection' is deprecated: apply the '@Table' macro, instead
           ✏️ Use '@Table' instead
          @Column(primaryKey: true)
                  ┬─────────
                  ╰─ 🛑 '@Selection' primary keys are not supported
                     ✏️ Remove 'primaryKey: true'
          let id: Int
          var title = ""
        }
        """
      } fixes: {
        """
        @Tablestruct Row {
          @Column()
          let id: Int
          var title = ""
        }
        """
      } expansion: {
        """
        @Tablestruct Row {
          let id: Int
          var title = ""
        }
        """
      }
    }

    @Test func tableSelectionPrimaryKey() {
      assertMacro {
        """
        @Table @Selection struct Row {
          @Column(primaryKey: true)
          let id: Int
          var title = ""
        }
        """
      } diagnostics: {
        """
        @Table @Selection struct Row {
               ┬─────────
               ╰─ ⚠️ '@Table' already contains the functionality provided by '@Selection'
                  ✏️ Remove '@Selection'
          @Column(primaryKey: true)
          let id: Int
          var title = ""
        }
        """
      } fixes: {
        """
        @Table struct Row {
          @Column(primaryKey: true)
          let id: Int
          var title = ""
        }
        """
      } expansion: {
        #"""
        struct Row {
          let id: Int
          var title = ""

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Row
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore.TableColumn<QueryValue, Int>("id", keyPath: \QueryValue.id)
            public let title = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
            public var primaryKey: StructuredQueriesCore.TableColumn<QueryValue, Int> {
              self.id
            }
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
              return allColumns
            }
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

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Row
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              title: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: "")
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: title._allColumns)
              self.allColumns = allColumns
            }
          }

          public struct Draft: StructuredQueriesCore.TableDraft {
            public typealias PrimaryTable = Row
            let id: Int?
            var title = ""
            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore.TableColumn<QueryValue, Int?>("id", keyPath: \QueryValue.id, default: nil)
              public let title = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("title", keyPath: \QueryValue.title, default: "")
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.title._allColumns)
                return allColumns
              }
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
            public struct Selection: StructuredQueriesCore.TableExpression {
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

            public nonisolated static var columnWidth: Int {
              [Int?.columnWidth, Swift.String.columnWidth].reduce(0, +)
            }

            public nonisolated static var tableName: String {
              Row.tableName
            }

            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode(Int.self) ?? nil
              self.title = try decoder.decode(Swift.String.self) ?? ""
            }

            public nonisolated init(_ other: Row) {
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

        nonisolated extension Row: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var columnWidth: Int {
            [Int.columnWidth, Swift.String.columnWidth].reduce(0, +)
          }
          public nonisolated static var tableName: String {
            "rows"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(Int.self)
            self.title = try decoder.decode(Swift.String.self) ?? ""
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
