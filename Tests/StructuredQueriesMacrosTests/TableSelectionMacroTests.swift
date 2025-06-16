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

          public struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = ReminderListWithCount
            public let reminderList = StructuredQueriesCore.TableColumn<QueryValue, ReminderList>("reminderList", keyPath: \QueryValue.reminderList)
            public let remindersCount = StructuredQueriesCore.TableColumn<QueryValue, Int>("remindersCount", keyPath: \QueryValue.remindersCount)
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              [QueryValue.columns.reminderList, QueryValue.columns.remindersCount]
            }
          }

          public struct Columns: StructuredQueriesCore.QueryExpression {
            public typealias QueryValue = ReminderListWithCount
            public let queryFragment: StructuredQueriesCore.QueryFragment
            public init(
              reminderList: some StructuredQueriesCore.QueryExpression<ReminderList>,
              remindersCount: some StructuredQueriesCore.QueryExpression<Int>
            ) {
              self.queryFragment = """
              \(reminderList.queryFragment) AS "reminderList", \(remindersCount.queryFragment) AS "remindersCount"
              """
            }
          }
        }

        extension ReminderListWithCount: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public typealias QueryValue = Self
          public typealias From = Swift.Never
          public static let columns = TableColumns()
          public static let tableName = "reminderListWithCounts"
        }

        extension ReminderListWithCount: StructuredQueriesCore.QueryRepresentable {
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
