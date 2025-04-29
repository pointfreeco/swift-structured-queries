import Dependencies
import Foundation
import StructuredQueries
import StructuredQueriesSQLite

@Table
struct RemindersList: Codable, Equatable, Identifiable {
  static let withReminderCount = group(by: \.id)
    .join(Reminder.all) { $0.id.eq($1.remindersListID) }
    .select { $1.id.count() }

  let id: Int
  var color = 0x4a99ef
  var title = ""
}

@Table
struct Reminder: Codable, Equatable, Identifiable {
  static let incomplete = Self.where { !$0.isCompleted }

  let id: Int
  var assignedUserID: User.ID?
  @Column(as: Date.ISO8601Representation?.self)
  var dueDate: Date?
  var isCompleted = false
  var isFlagged = false
  var notes = ""
  var priority: Priority?
  var remindersListID: Int
  var title = ""
  static func searching(_ text: String) -> Where<Reminder> {
    Self.where {
      $0.title.collate(.nocase).contains(text)
        || $0.notes.collate(.nocase).contains(text)
    }
  }
}

@Table
struct User: Codable, Equatable, Identifiable {
  let id: Int
  var name = ""
}

enum Priority: Int, Codable, QueryBindable {
  case low = 1
  case medium
  case high
}

extension Reminder.TableColumns {
  var isPastDue: some QueryExpression<Bool> {
    !isCompleted && #sql("coalesce(\(dueDate), date('now')) < date('now')")
  }
}

@Table
struct Tag: Codable, Equatable, Identifiable {
  let id: Int
  var title = ""
}

@Table("remindersTags")
struct ReminderTag: Equatable {
  let reminderID: Int
  let tagID: Int
}

extension Database {
  static func `default`() throws -> Database {
    let db = try Database()
    try db.migrate()
    try db.createMockData()
    return db
  }

  func migrate() throws {
    try execute(
      """
      CREATE TABLE "remindersLists" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "color" INTEGER NOT NULL DEFAULT 4889071,
        "title" TEXT NOT NULL DEFAULT ''
      )
      """
    )
    try execute(
      """
      CREATE UNIQUE INDEX "remindersLists_title" ON "remindersLists"("title")
      """
    )
    try execute(
      """
      CREATE TABLE "reminders" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "assignedUserID" INTEGER,
        "dueDate" DATE,
        "isCompleted" BOOLEAN NOT NULL DEFAULT 0,
        "isFlagged" BOOLEAN NOT NULL DEFAULT 0,
        "remindersListID" INTEGER NOT NULL REFERENCES "remindersLists"("id") ON DELETE CASCADE,
        "notes" TEXT NOT NULL DEFAULT '',
        "priority" INTEGER,
        "title" TEXT NOT NULL DEFAULT ''
      )
      """
    )
    try execute(
      """
      CREATE TABLE "users" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "name" TEXT NOT NULL DEFAULT ''
      )
      """
    )
    try execute(
      """
      CREATE INDEX "index_reminders_on_remindersListID" ON "reminders"("remindersListID")
      """
    )
    try execute(
      """
      CREATE TABLE "tags" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "title" TEXT NOT NULL UNIQUE COLLATE NOCASE
      )
      """
    )
    try execute(
      """
      CREATE TABLE "remindersTags" (
        "reminderID" INTEGER NOT NULL REFERENCES "reminders"("id") ON DELETE CASCADE,
        "tagID" INTEGER NOT NULL REFERENCES "tags"("id") ON DELETE CASCADE
      )
      """
    )
    try execute(
      """
      CREATE INDEX "index_remindersTags_on_reminderID" ON "remindersTags"("reminderID")
      """
    )
    try execute(
      """
      CREATE INDEX "index_remindersTags_on_tagID" ON "remindersTags"("tagID")
      """
    )
  }

  func createMockData() throws {
    try createDebugUsers()
    try createDebugRemindersLists()
    try createDebugReminders()
    try createDebugTags()
  }

  func createDebugUsers() throws {
    try execute(
      User.insert {
        $0.name
      } values: {
        "Blob"
        "Blob Jr"
        "Blob Sr"
      }
    )
  }

  func createDebugRemindersLists() throws {
    try execute(
      RemindersList.insert {
        ($0.color, $0.title)
      } values: {
        (0x4a99ef, "Personal")
        (0xed8935, "Family")
        (0xb25dd3, "Business")
      }
    )
  }

  func createDebugReminders() throws {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    try execute(
      Reminder.insert([
        Reminder.Draft(
          assignedUserID: 1,
          dueDate: now,
          notes: """
            Milk, Eggs, Apples
            """,
          remindersListID: 1,
          title: "Groceries"
        ),
        Reminder.Draft(
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isFlagged: true,
          remindersListID: 1,
          title: "Haircut"
        ),
        Reminder.Draft(
          dueDate: now,
          notes: "Ask about diet",
          priority: .high,
          remindersListID: 1,
          title: "Doctor appointment"
        ),
        Reminder.Draft(
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 190),
          isCompleted: true,
          remindersListID: 1,
          title: "Take a walk"
        ),
        Reminder.Draft(
          remindersListID: 1,
          title: "Buy concert tickets"
        ),
        Reminder.Draft(
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 2),
          isFlagged: true,
          priority: .high,
          remindersListID: 2,
          title: "Pick up kids from school"
        ),
        Reminder.Draft(
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isCompleted: true,
          priority: .low,
          remindersListID: 2,
          title: "Get laundry"
        ),
        Reminder.Draft(
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 4),
          isCompleted: false,
          priority: .high,
          remindersListID: 2,
          title: "Take out trash"
        ),
        Reminder.Draft(
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 2),
          notes: """
            Status of tax return
            Expenses for next year
            Changing payroll company
            """,
          remindersListID: 3,
          title: "Call accountant"
        ),
        Reminder.Draft(
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isCompleted: true,
          priority: .medium,
          remindersListID: 3,
          title: "Send weekly emails"
        ),
      ])
    )
  }

  func createDebugTags() throws {
    try execute(
      Tag.insert(\.title) {
        "car"
        "kids"
        "someday"
        "optional"
      }
    )
    try execute(
      ReminderTag.insert {
        ($0.reminderID, $0.tagID)
      } values: {
        (1, 3)
        (1, 4)
        (2, 3)
        (2, 4)
        (4, 1)
        (4, 2)
      }
    )
  }
}

extension Database: @unchecked Sendable {}

private enum DefaultDatabaseKey: DependencyKey {
  static var liveValue: Database { try! .default() }
  static var testValue: Database { liveValue }
}

extension DependencyValues {
  var defaultDatabase: Database {
    get { self[DefaultDatabaseKey.self] }
    set { self[DefaultDatabaseKey.self] = newValue }
  }
}
