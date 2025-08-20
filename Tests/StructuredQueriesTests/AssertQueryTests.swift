import Dependencies
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite
  struct AssertQueryTests {
    @Dependency(\.defaultDatabase) var db
    @Test func assertQueryBasicType() {
      StructuredQueriesTestSupport.assertQuery(
        Reminder.all
          .select { ($0.id, $0.assignedUserID) }
          .limit(3)
          .order(by: \.id)
      ) {
        try db.execute($0)
      } sql: {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID"
        FROM "reminders"
        ORDER BY "reminders"."id"
        LIMIT 3
        """
      } results: {
        """
        ┌───┬─────┐
        │ 1 │ 1   │
        │ 2 │ nil │
        │ 3 │ nil │
        └───┴─────┘
        """
      }
    }
    @Test func assertQueryComplexType() {
      StructuredQueriesTestSupport.assertQuery(
        Reminder.where { $0.id == 1 }
      ) {
        try db.execute($0)
      } sql: {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        WHERE ("reminders"."id" = 1)
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Reminder(                                   │
        │   id: 1,                                    │
        │   assignedUserID: 1,                        │
        │   dueDate: Date(2001-01-01T00:00:00.000Z),  │
        │   isCompleted: false,                       │
        │   isFlagged: false,                         │
        │   notes: "Milk, Eggs, Apples",              │
        │   priority: nil,                            │
        │   remindersListID: 1,                       │
        │   title: "Groceries",                       │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }
    @Test func assertSelectBasicType() {
      StructuredQueriesTestSupport.assertSelect(
        Reminder.all
          .select { ($0.id, $0.assignedUserID) }
          .limit(3)
          .order(by: \.id)
      ) {
        try db.execute($0)
      } results: {
        """
        ┌───┬─────┐
        │ 1 │ 1   │
        │ 2 │ nil │
        │ 3 │ nil │
        └───┴─────┘
        """
      }
    }
    @Test func assertSelectComplexType() {
      StructuredQueriesTestSupport.assertSelect(
        Reminder.where { $0.id == 1 }
      ) {
        try db.execute($0)
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Reminder(                                   │
        │   id: 1,                                    │
        │   assignedUserID: 1,                        │
        │   dueDate: Date(2001-01-01T00:00:00.000Z),  │
        │   isCompleted: false,                       │
        │   isFlagged: false,                         │
        │   notes: "Milk, Eggs, Apples",              │
        │   priority: nil,                            │
        │   remindersListID: 1,                       │
        │   title: "Groceries",                       │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }
  }
}
