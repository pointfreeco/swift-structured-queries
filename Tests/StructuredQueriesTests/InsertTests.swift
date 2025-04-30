import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct InsertTests {
    @Test func basics() {
      assertQuery(
        Reminder.insert {
          ($0.remindersListID, $0.title, $0.isCompleted, $0.dueDate, $0.priority)
        } values: {
          (1, "Groceries", true, Date(timeIntervalSinceReferenceDate: 0), .high)
          (2, "Haircut", false, Date(timeIntervalSince1970: 0), .low)
        } onConflict: {
          $0.title += " Copy"
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "reminders"
        ("remindersListID", "title", "isCompleted", "dueDate", "priority")
        VALUES
        (1, 'Groceries', 1, '2001-01-01 00:00:00.000', 3), (2, 'Haircut', 0, '1970-01-01 00:00:00.000', 1)
        ON CONFLICT DO UPDATE SET "title" = ("reminders"."title" || ' Copy')
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title"
        """
      } results: {
        """
        ┌────────────────────────────────────────────┐
        │ Reminder(                                  │
        │   id: 11,                                  │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │
        │   isCompleted: true,                       │
        │   isFlagged: false,                        │
        │   notes: "",                               │
        │   priority: .high,                         │
        │   remindersListID: 1,                      │
        │   title: "Groceries"                       │
        │ )                                          │
        ├────────────────────────────────────────────┤
        │ Reminder(                                  │
        │   id: 12,                                  │
        │   assignedUserID: nil,                     │
        │   dueDate: Date(1970-01-01T00:00:00.000Z), │
        │   isCompleted: false,                      │
        │   isFlagged: false,                        │
        │   notes: "",                               │
        │   priority: .low,                          │
        │   remindersListID: 2,                      │
        │   title: "Haircut"                         │
        │ )                                          │
        └────────────────────────────────────────────┘
        """
      }
    }

    @Test func singleColumn() {
      assertQuery(
        Reminder
          .insert(\.remindersListID) { 1 }
          .returning(\.self)
      ) {
        """
        INSERT INTO "reminders"
        ("remindersListID")
        VALUES
        (1)
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title"
        """
      } results: {
        """
        ┌────────────────────────┐
        │ Reminder(              │
        │   id: 11,              │
        │   assignedUserID: nil, │
        │   dueDate: nil,        │
        │   isCompleted: false,  │
        │   isFlagged: false,    │
        │   notes: "",           │
        │   priority: nil,       │
        │   remindersListID: 1,  │
        │   title: ""            │
        │ )                      │
        └────────────────────────┘
        """
      }
    }

    @Test
    func emptyValues() {
      assertQuery(Reminder.insert([])) {
        """

        """
      }
      assertQuery(Reminder.insert(\.id) { return [] }) {
        """

        """
      }
    }

    @Test
    func records() {
      assertQuery(
        Reminder.insert {
          $0
        } values: {
          Reminder(id: 100, remindersListID: 1, title: "Check email")
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (100, NULL, NULL, 0, 0, '', NULL, 1, 'Check email')
        RETURNING "id"
        """
      } results: {
        """
        ┌─────┐
        │ 100 │
        └─────┘
        """
      }
      assertQuery(
        Reminder.insert {
          Reminder(id: 101, remindersListID: 1, title: "Check voicemail")
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (101, NULL, NULL, 0, 0, '', NULL, 1, 'Check voicemail')
        RETURNING "id"
        """
      } results: {
        """
        ┌─────┐
        │ 101 │
        └─────┘
        """
      }
      assertQuery(
        Reminder.insert([
          Reminder(id: 102, remindersListID: 1, title: "Check mailbox"),
          Reminder(id: 103, remindersListID: 1, title: "Check Slack"),
        ])
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (102, NULL, NULL, 0, 0, '', NULL, 1, 'Check mailbox'), (103, NULL, NULL, 0, 0, '', NULL, 1, 'Check Slack')
        RETURNING "id"
        """
      } results: {
        """
        ┌─────┐
        │ 102 │
        │ 103 │
        └─────┘
        """
      }
      assertQuery(
        Reminder.insert(
          Reminder(id: 104, remindersListID: 1, title: "Check pager")
        )
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (104, NULL, NULL, 0, 0, '', NULL, 1, 'Check pager')
        RETURNING "id"
        """
      } results: {
        """
        ┌─────┐
        │ 104 │
        └─────┘
        """
      }
    }

    @Test func select() {
      assertQuery(
        Tag.insert {
          $0.title
        } select: {
          RemindersList.select { $0.title.lower() }
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "tags"
        ("title")
        SELECT lower("remindersLists"."title")
        FROM "remindersLists"
        RETURNING "id", "title"
        """
      } results: {
        """
        ┌─────────────────────┐
        │ Tag(                │
        │   id: 5,            │
        │   title: "business" │
        │ )                   │
        ├─────────────────────┤
        │ Tag(                │
        │   id: 6,            │
        │   title: "family"   │
        │ )                   │
        ├─────────────────────┤
        │ Tag(                │
        │   id: 7,            │
        │   title: "personal" │
        │ )                   │
        └─────────────────────┘
        """
      }
    }

    @Test func draft() {
      assertQuery(
        Reminder.insert {
          Reminder.Draft(remindersListID: 1, title: "Check email")
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check email')
        RETURNING "id"
        """
      } results: {
        """
        ┌────┐
        │ 11 │
        └────┘
        """
      }

      assertQuery(
        Reminder.insert(
          Reminder.Draft(remindersListID: 1, title: "Check voicemail")
        )
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check voicemail')
        RETURNING "id"
        """
      } results: {
        """
        ┌────┐
        │ 12 │
        └────┘
        """
      }

      assertQuery(
        Reminder.insert(
          [
            Reminder.Draft(remindersListID: 1, title: "Check mailbox"),
            Reminder.Draft(remindersListID: 1, title: "Check Slack"),
          ]
        )
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check mailbox'), (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check Slack')
        RETURNING "id"
        """
      } results: {
        """
        ┌────┐
        │ 13 │
        │ 14 │
        └────┘
        """
      }
    }

    @Test func upsertWithID() {
      assertQuery(Reminder.where { $0.id == 1 }) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title"
        FROM "reminders"
        WHERE ("reminders"."id" = 1)
        """
      } results: {
        """
        ┌────────────────────────────────────────────┐
        │ Reminder(                                  │
        │   id: 1,                                   │
        │   assignedUserID: 1,                       │
        │   dueDate: Date(2001-01-01T00:00:00.000Z), │
        │   isCompleted: false,                      │
        │   isFlagged: false,                        │
        │   notes: "Milk, Eggs, Apples",             │
        │   priority: nil,                           │
        │   remindersListID: 1,                      │
        │   title: "Groceries"                       │
        │ )                                          │
        └────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Reminder
          .upsert(Reminder.Draft(id: 1, remindersListID: 1, title: "Cash check"))
          .returning(\.self)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (1, NULL, NULL, 0, 0, '', NULL, 1, 'Cash check')
        ON CONFLICT ("id") DO UPDATE SET "assignedUserID" = "excluded"."assignedUserID", "dueDate" = "excluded"."dueDate", "isCompleted" = "excluded"."isCompleted", "isFlagged" = "excluded"."isFlagged", "notes" = "excluded"."notes", "priority" = "excluded"."priority", "remindersListID" = "excluded"."remindersListID", "title" = "excluded"."title"
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title"
        """
      } results: {
        """
        ┌────────────────────────┐
        │ Reminder(              │
        │   id: 1,               │
        │   assignedUserID: nil, │
        │   dueDate: nil,        │
        │   isCompleted: false,  │
        │   isFlagged: false,    │
        │   notes: "",           │
        │   priority: nil,       │
        │   remindersListID: 1,  │
        │   title: "Cash check"  │
        │ )                      │
        └────────────────────────┘
        """
      }
    }

    @Test func upsertWithoutID() {
      assertQuery(Reminder.select { $0.id.max() }) {
        """
        SELECT max("reminders"."id")
        FROM "reminders"
        """
      } results: {
        """
        ┌────┐
        │ 10 │
        └────┘
        """
      }
      assertQuery(
        Reminder.upsert(Reminder.Draft(remindersListID: 1))
          .returning(\.self)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, '')
        ON CONFLICT ("id") DO UPDATE SET "assignedUserID" = "excluded"."assignedUserID", "dueDate" = "excluded"."dueDate", "isCompleted" = "excluded"."isCompleted", "isFlagged" = "excluded"."isFlagged", "notes" = "excluded"."notes", "priority" = "excluded"."priority", "remindersListID" = "excluded"."remindersListID", "title" = "excluded"."title"
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title"
        """
      } results: {
        """
        ┌────────────────────────┐
        │ Reminder(              │
        │   id: 11,              │
        │   assignedUserID: nil, │
        │   dueDate: nil,        │
        │   isCompleted: false,  │
        │   isFlagged: false,    │
        │   notes: "",           │
        │   priority: nil,       │
        │   remindersListID: 1,  │
        │   title: ""            │
        │ )                      │
        └────────────────────────┘
        """
      }
    }

    @Test func upsertWithoutID_OtherConflict() {
      assertQuery(
        RemindersList.upsert(RemindersList.Draft(title: "Personal"))
          .returning(\.self)
      ) {
        """
        INSERT INTO "remindersLists"
        ("id", "color", "title")
        VALUES
        (NULL, 4889071, 'Personal')
        ON CONFLICT ("id") DO UPDATE SET "color" = "excluded"."color", "title" = "excluded"."title"
        RETURNING "id", "color", "title"
        """
      } results: {
        """
        UNIQUE constraint failed: remindersLists.title
        """
      }
    }

    @Test func sql() {
      assertQuery(
        #sql(
          """
          INSERT INTO \(Tag.self) ("name")
          VALUES (\(bind: "office"))
          RETURNING \(Tag.columns)
          """,
          as: Tag.self
        )
      ) {
        """
        INSERT INTO "tags" ("name")
        VALUES ('office')
        RETURNING "tags"."id", "tags"."title"
        """
      } results: {
        """
        table tags has no column named name
        """
      }
    }

    @Test func aliasName() {
      enum R: AliasName {}
      assertQuery(
        RemindersList.as(R.self).insert {
          $0.title
        } values: {
          "cruise"
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "remindersLists" AS "rs"
        ("title")
        VALUES
        ('cruise')
        RETURNING "id", "color", "title"
        """
      } results: {
        """
        ┌───────────────────┐
        │ RemindersList(    │
        │   id: 4,          │
        │   color: 4889071, │
        │   title: "cruise" │
        │ )                 │
        └───────────────────┘
        """
      }
    }

    @Test func noPrimaryKey() {
      assertInlineSnapshot(
        of: Item.insert(Item()),
        as: .sql
      ) {
        """
        INSERT INTO "items"
        ("title", "quantity")
        VALUES
        ('', 0)
        """
      }
    }
  }
}

@Table private struct Item {
  var title = ""
  var quantity = 0
}
