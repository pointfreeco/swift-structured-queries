import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @Suite
  struct TableSelectionMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @Table @Selection
        struct ReminderListWithCount {
          let reminderList: ReminderList
          let remindersCount: Int
        }
        """
      } diagnostics: {
        """
        @Table @Selection
               ┬─────────
               ╰─ ⚠️ '@Table' already contains the functionality provided by '@Selection'
                  ✏️ Remove '@Selection'
        struct ReminderListWithCount {
          let reminderList: ReminderList
          let remindersCount: Int
        }
        """
      } fixes: {
        """
        @Table 
        struct ReminderListWithCount {
          let reminderList: ReminderList
          let remindersCount: Int
        }
        """
      } expansion: {
        #"""
        struct ReminderListWithCount {
          let reminderList: ReminderList
          let remindersCount: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = ReminderListWithCount
            public let reminderList = StructuredQueriesCore._TableColumn<QueryValue, ReminderList>.for("reminderList", keyPath: \QueryValue.reminderList)
            public let remindersCount = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("remindersCount", keyPath: \QueryValue.remindersCount)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.reminderList._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.remindersCount._allColumns)
              return allColumns
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.reminderList._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.remindersCount._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.reminderList), \(self.remindersCount)"
            }
          }

          public struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = ReminderListWithCount
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              reminderList: some StructuredQueriesCore.QueryExpression<ReminderList>,
              remindersCount: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: reminderList._allColumns)
              allColumns.append(contentsOf: remindersCount._allColumns)
              self.allColumns = allColumns
            }
          }
        }

        nonisolated extension ReminderListWithCount: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var columnWidth: Int {
            [ReminderList.columnWidth, Int.columnWidth].reduce(0, +)
          }
          public nonisolated static var tableName: String {
            "reminderListWithCounts"
          }
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let reminderList = try decoder.decode(ReminderList.self)
            let remindersCount = try decoder.decode(Int.self)
            guard let reminderList else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let remindersCount else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.reminderList = reminderList
            self.remindersCount = remindersCount
          }
        }
        """#
      }
    }
  }
}
