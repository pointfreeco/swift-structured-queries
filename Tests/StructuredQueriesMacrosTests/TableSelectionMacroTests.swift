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
      } expansion: {
        #"""
        struct ReminderListWithCount {
          let reminderList: ReminderList 
          let remindersCount: Int

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = ReminderListWithCount
            public let reminderList = StructuredQueriesCore.TableColumn<QueryValue, ReminderList>("reminderList", keyPath: \QueryValue.reminderList)
            public let remindersCount = StructuredQueriesCore.TableColumn<QueryValue, Int>("remindersCount", keyPath: \QueryValue.remindersCount)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [QueryValue.columns.reminderList, QueryValue.columns.remindersCount]
            }
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              [QueryValue.columns.reminderList, QueryValue.columns.remindersCount]
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
              self.allColumns = [reminderList, remindersCount]
            }
          }

          public struct Columns: StructuredQueriesCore._SelectedColumns {
            public typealias QueryValue = ReminderListWithCount
            public let selection: [(aliasName: String, expression: StructuredQueriesCore.QueryFragment)]
            public init(
              reminderList: some StructuredQueriesCore.QueryExpression<ReminderList>,
              remindersCount: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.selection = [("reminderList", reminderList.queryFragment), ("remindersCount", remindersCount.queryFragment)]
            }
          }
        }

        nonisolated extension ReminderListWithCount: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public nonisolated static var columns: TableColumns {
            TableColumns()
          }
          public nonisolated static var tableName: String {
            "reminderListWithCounts"
          }
        }

        extension ReminderListWithCount: StructuredQueriesCore._Selection {
          public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let reminderList = try decoder.decode(ReminderList.self)
            let remindersCount = try decoder.decode(Int.self)
            guard let reminderList else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let remindersCount else {
              throw QueryDecodingError.missingRequiredColumn
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
