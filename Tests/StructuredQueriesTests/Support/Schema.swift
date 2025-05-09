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
    try db.seedDatabase()
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

  func seedDatabase() throws {
    try Seeds {
      User(id: 1, name: "Blob")
      User(id: 2, name: "Blob Jr")
      User(id: 3, name: "Blob Sr")
      RemindersList(id: 1, color: 0x4a99ef, title: "Personal")
      RemindersList(id: 2, color: 0xed8935, title: "Family")
      RemindersList(id: 3, color: 0xb25dd3, title: "Business")
      let now = Date(timeIntervalSinceReferenceDate: 0)
      Reminder(
        id: 1,
        assignedUserID: 1,
        dueDate: now,
        notes: """
          Milk, Eggs, Apples
          """,
        remindersListID: 1,
        title: "Groceries"
      )
      Reminder(
        id: 2,
        dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
        isFlagged: true,
        remindersListID: 1,
        title: "Haircut"
      )
      Reminder(
        id: 3,
        dueDate: now,
        notes: "Ask about diet",
        priority: .high,
        remindersListID: 1,
        title: "Doctor appointment"
      )
      Reminder(
        id: 4,
        dueDate: now.addingTimeInterval(-60 * 60 * 24 * 190),
        isCompleted: true,
        remindersListID: 1,
        title: "Take a walk"
      )
      Reminder(
        id: 5,
        remindersListID: 1,
        title: "Buy concert tickets"
      )
      Reminder(
        id: 6,
        dueDate: now.addingTimeInterval(60 * 60 * 24 * 2),
        isFlagged: true,
        priority: .high,
        remindersListID: 2,
        title: "Pick up kids from school"
      )
      Reminder(
        id: 7,
        dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
        isCompleted: true,
        priority: .low,
        remindersListID: 2,
        title: "Get laundry"
      )
      Reminder(
        id: 8,
        dueDate: now.addingTimeInterval(60 * 60 * 24 * 4),
        isCompleted: false,
        priority: .high,
        remindersListID: 2,
        title: "Take out trash"
      )
      Reminder(
        id: 9,
        dueDate: now.addingTimeInterval(60 * 60 * 24 * 2),
        notes: """
          Status of tax return
          Expenses for next year
          Changing payroll company
          """,
        remindersListID: 3,
        title: "Call accountant"
      )
      Reminder(
        id: 10,
        dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
        isCompleted: true,
        priority: .medium,
        remindersListID: 3,
        title: "Send weekly emails"
      )
      Tag(id: 1, title: "car")
      Tag(id: 2, title: "kids")
      Tag(id: 3, title: "someday")
      Tag(id: 4, title: "optional")
      ReminderTag(reminderID: 1, tagID: 3)
      ReminderTag(reminderID: 1, tagID: 4)
      ReminderTag(reminderID: 2, tagID: 3)
      ReminderTag(reminderID: 2, tagID: 4)
      ReminderTag(reminderID: 4, tagID: 1)
      ReminderTag(reminderID: 4, tagID: 2)
    }
    .forEach(execute)
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
