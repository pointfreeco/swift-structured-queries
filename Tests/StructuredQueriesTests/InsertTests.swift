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
          (#sql("3"), #sql("'Schedule doctor appointment'"), #sql("0"), #sql("NULL"), #sql("2"))
        } onConflictDoUpdate: {
          $0.title += " Copy"
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("remindersListID", "title", "isCompleted", "dueDate", "priority")
        VALUES
        (1, 'Groceries', 1, '2001-01-01 00:00:00.000', 3), (2, 'Haircut', 0, '1970-01-01 00:00:00.000', 1), (3, 'Schedule doctor appointment', 0, NULL, 2)
        ON CONFLICT DO UPDATE SET "title" = ("reminders"."title") || (' Copy')
        RETURNING "id"
        """
      } results: {
        """
        ┌────┐
        │ 11 │
        │ 12 │
        │ 13 │
        └────┘
        """
      }
    }

    @Test func singleColumn() {
      assertQuery(
        Reminder
          .insert(\.remindersListID) { 1 }
          .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("remindersListID")
        VALUES
        (1)
        RETURNING "id"
        """
      } results: {
        """
        ┌────┐
        │ 11 │
        └────┘
        """
      }
    }

    @Test
    func emptyValues() {
      assertQuery(Reminder.insert { [] }) {
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
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (100, NULL, NULL, 0, 0, '', NULL, 1, 'Check email', '2040-02-14 23:31:30.000')
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
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (101, NULL, NULL, 0, 0, '', NULL, 1, 'Check voicemail', '2040-02-14 23:31:30.000')
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
        Reminder.insert {
          Reminder(id: 102, remindersListID: 1, title: "Check mailbox")
          Reminder(id: 103, remindersListID: 1, title: "Check Slack")
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (102, NULL, NULL, 0, 0, '', NULL, 1, 'Check mailbox', '2040-02-14 23:31:30.000'), (103, NULL, NULL, 0, 0, '', NULL, 1, 'Check Slack', '2040-02-14 23:31:30.000')
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
        Reminder.insert {
          Reminder(id: 104, remindersListID: 1, title: "Check pager")
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (104, NULL, NULL, 0, 0, '', NULL, 1, 'Check pager', '2040-02-14 23:31:30.000')
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

      assertQuery(
        Tag.insert {
          $0.title
        } select: {
          Values("vacation")
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "tags"
        ("title")
        SELECT 'vacation'
        RETURNING "id", "title"
        """
      } results: {
        """
        ┌─────────────────────┐
        │ Tag(                │
        │   id: 8,            │
        │   title: "vacation" │
        │ )                   │
        └─────────────────────┘
        """
      }

      assertQuery(
        Tag.insert {
          $0.title
        } select: {
          // NB: 'WHERE 1' is required to avoid a SQL syntax error.
          RemindersList.where { _ in true }.select { $0.title.lower() }
        } onConflict: {
          $0.title
        } doUpdate: {
          $0.title = $1.title + "-copy"
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "tags"
        ("title")
        SELECT lower("remindersLists"."title")
        FROM "remindersLists"
        WHERE 1
        ON CONFLICT ("title")
        DO UPDATE SET "title" = ("excluded"."title") || ('-copy')
        RETURNING "id", "title"
        """
      } results: {
        """
        ┌──────────────────────────┐
        │ Tag(                     │
        │   id: 5,                 │
        │   title: "business-copy" │
        │ )                        │
        ├──────────────────────────┤
        │ Tag(                     │
        │   id: 6,                 │
        │   title: "family-copy"   │
        │ )                        │
        ├──────────────────────────┤
        │ Tag(                     │
        │   id: 7,                 │
        │   title: "personal-copy" │
        │ )                        │
        └──────────────────────────┘
        """
      }
      assertQuery(
        Tag.insert {
          $0.title
        } select: {
          // NB: 'WHERE 1' is required to avoid a SQL syntax error.
          RemindersList.where { _ in true }.select { $0.title.lower() + "-copy" }
        } onConflict: {
          $0.title
        } doUpdate: {
          $0.title += "-2"
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "tags"
        ("title")
        SELECT (lower("remindersLists"."title")) || ('-copy')
        FROM "remindersLists"
        WHERE 1
        ON CONFLICT ("title")
        DO UPDATE SET "title" = ("tags"."title") || ('-2')
        RETURNING "id", "title"
        """
      } results: {
        """
        ┌────────────────────────────┐
        │ Tag(                       │
        │   id: 5,                   │
        │   title: "business-copy-2" │
        │ )                          │
        ├────────────────────────────┤
        │ Tag(                       │
        │   id: 6,                   │
        │   title: "family-copy-2"   │
        │ )                          │
        ├────────────────────────────┤
        │ Tag(                       │
        │   id: 7,                   │
        │   title: "personal-copy-2" │
        │ )                          │
        └────────────────────────────┘
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
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check email', '2040-02-14 23:31:30.000')
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
        Reminder.insert {
          Reminder(id: 12, remindersListID: 1, title: "Check voicemail")
          Reminder.Draft(remindersListID: 1, title: "Check pager")
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (12, NULL, NULL, 0, 0, '', NULL, 1, 'Check voicemail', '2040-02-14 23:31:30.000'), (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check pager', '2040-02-14 23:31:30.000')
        RETURNING "id"
        """
      } results: {
        """
        ┌────┐
        │ 12 │
        │ 13 │
        └────┘
        """
      }

      assertQuery(
        Reminder.insert {
          [
            Reminder.Draft(remindersListID: 1, title: "Check mailbox"),
            Reminder.Draft(remindersListID: 1, title: "Check Slack"),
          ]
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check mailbox', '2040-02-14 23:31:30.000'), (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check Slack', '2040-02-14 23:31:30.000')
        RETURNING "id"
        """
      } results: {
        """
        ┌────┐
        │ 14 │
        │ 15 │
        └────┘
        """
      }
    }

    @Test func upsertWithID() {
      assertQuery(Reminder.where { $0.id == 1 }) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        WHERE ("reminders"."id") = (1)
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
      assertQuery(
        Reminder
          .upsert { Reminder.Draft(id: 1, remindersListID: 1, title: "Cash check") }
          .returning(\.self)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (1, NULL, NULL, 0, 0, '', NULL, 1, 'Cash check', '2040-02-14 23:31:30.000')
        ON CONFLICT ("id")
        DO UPDATE SET "assignedUserID" = "excluded"."assignedUserID", "dueDate" = "excluded"."dueDate", "isCompleted" = "excluded"."isCompleted", "isFlagged" = "excluded"."isFlagged", "notes" = "excluded"."notes", "priority" = "excluded"."priority", "remindersListID" = "excluded"."remindersListID", "title" = "excluded"."title", "updatedAt" = "excluded"."updatedAt"
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt"
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Reminder(                                   │
        │   id: 1,                                    │
        │   assignedUserID: nil,                      │
        │   dueDate: nil,                             │
        │   isCompleted: false,                       │
        │   isFlagged: false,                         │
        │   notes: "",                                │
        │   priority: nil,                            │
        │   remindersListID: 1,                       │
        │   title: "Cash check",                      │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
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
        Reminder.upsert {
          Reminder.Draft(remindersListID: 1)
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, '', '2040-02-14 23:31:30.000')
        ON CONFLICT ("id")
        DO UPDATE SET "assignedUserID" = "excluded"."assignedUserID", "dueDate" = "excluded"."dueDate", "isCompleted" = "excluded"."isCompleted", "isFlagged" = "excluded"."isFlagged", "notes" = "excluded"."notes", "priority" = "excluded"."priority", "remindersListID" = "excluded"."remindersListID", "title" = "excluded"."title", "updatedAt" = "excluded"."updatedAt"
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt"
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Reminder(                                   │
        │   id: 11,                                   │
        │   assignedUserID: nil,                      │
        │   dueDate: nil,                             │
        │   isCompleted: false,                       │
        │   isFlagged: false,                         │
        │   notes: "",                                │
        │   priority: nil,                            │
        │   remindersListID: 1,                       │
        │   title: "",                                │
        │   updatedAt: Date(2040-02-14T23:31:30.000Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @Test func upsertWithoutID_OtherConflict() {
      assertQuery(
        RemindersList.upsert {
          RemindersList.Draft(title: "Personal")
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "remindersLists"
        ("id", "color", "title", "position")
        VALUES
        (NULL, 4889071, 'Personal', 0)
        ON CONFLICT ("id")
        DO UPDATE SET "color" = "excluded"."color", "title" = "excluded"."title", "position" = "excluded"."position"
        RETURNING "id", "color", "title", "position"
        """
      } results: {
        """
        UNIQUE constraint failed: remindersLists.title
        """
      }
    }

    @Test func upsertWithoutID_onConflictDoUpdate() {
      assertQuery(
        RemindersList.insert {
          RemindersList.Draft(title: "Personal")
        } onConflict: {
          $0.title
        } doUpdate: {
          $0.color = 0x00ff00
        }.returning(\.self)
      ) {
        """
        INSERT INTO "remindersLists"
        ("id", "color", "title", "position")
        VALUES
        (NULL, 4889071, 'Personal', 0)
        ON CONFLICT ("title")
        DO UPDATE SET "color" = 65280
        RETURNING "id", "color", "title", "position"
        """
      } results: {
        """
        ┌──────────────────────┐
        │ RemindersList(       │
        │   id: 1,             │
        │   color: 65280,      │
        │   title: "Personal", │
        │   position: 0        │
        │ )                    │
        └──────────────────────┘
        """
      }
    }

    @Test func upsertNonPrimaryKey_onConflictDoUpdate() {
      assertQuery(
        ReminderTag.insert {
          ReminderTag(reminderID: 1, tagID: 3)
        } onConflict: {
          ($0.reminderID, $0.tagID)
        }
        .returning(\.self)
      ) {
        """
        INSERT INTO "remindersTags"
        ("reminderID", "tagID")
        VALUES
        (1, 3)
        ON CONFLICT ("reminderID", "tagID")
        DO NOTHING
        RETURNING "reminderID", "tagID"
        """
      }
    }

    @Test func upsertRepresentation() {
      assertQuery(
        Item.insert {
          $0.notes
        } values: {
          ["Hello", "World"]
        } onConflictDoUpdate: {
          $0.notes = ["Goodnight", "Moon"]
        }
      ) {
        """
        INSERT INTO "items"
        ("notes")
        VALUES
        ('[
          "Hello",
          "World"
        ]')
        ON CONFLICT DO UPDATE SET "notes" = '[
          "Goodnight",
          "Moon"
        ]'
        """
      } results: {
        """
        no such table: items
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
        RETURNING "id", "color", "title", "position"
        """
      } results: {
        """
        ┌────────────────────┐
        │ RemindersList(     │
        │   id: 4,           │
        │   color: 4889071,  │
        │   title: "cruise", │
        │   position: 0      │
        │ )                  │
        └────────────────────┘
        """
      }
    }

    @Test func noPrimaryKey() {
      assertInlineSnapshot(
        of: Item.insert { Item() },
        as: .sql
      ) {
        """
        INSERT INTO "items"
        ("title", "quantity", "notes")
        VALUES
        ('', 0, '[

        ]')
        """
      }
    }

    @Test func selectedColumns() {
      assertInlineSnapshot(
        of: Item.insert {
          Item.Columns(
            title: #sql("'Foo'"),
            quantity: #sql("42"),
            notes: #sql("[]")
          )
        },
        as: .sql
      ) {
        """
        INSERT INTO "items"
        ("title", "quantity", "notes")
        VALUES
        ('Foo', 42, [])
        """
      }
    }

    @Test func onConflictWhereDoUpdateWhere() {
      assertQuery(
        Reminder.insert {
          Reminder.Draft(remindersListID: 1)
        } onConflict: {
          $0.id
        } where: {
          !$0.isCompleted
        } doUpdate: {
          $0.isCompleted = $1.isCompleted
        } where: {
          $0.isFlagged
        }
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, '', '2040-02-14 23:31:30.000')
        ON CONFLICT ("id")
        WHERE NOT ("reminders"."isCompleted")
        DO UPDATE SET "isCompleted" = "excluded"."isCompleted"
        WHERE "reminders"."isFlagged"
        """
      }
    }

    // NB: This currently crashes in Xcode 26.
    #if swift(<6.2)
      @Test func onConflict_invalidUpdateFilters() {
        withKnownIssue {
          assertQuery(
            Reminder.insert {
              Reminder.Draft(remindersListID: 1)
            } where: {
              $0.isFlagged
            }
          ) {
            """
            INSERT INTO "reminders"
            ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
            VALUES
            (NULL, NULL, NULL, 0, 0, '', NULL, 1, '', '2040-02-14 23:31:30.000')
            """
          }
        }
      }
    #endif

    @Test func onConflict_conditionalWhere() {
      let condition = false
      assertQuery(
        Reminder.insert {
          Reminder.Draft(remindersListID: 1)
        } where: {
          if condition {
            $0.isFlagged
          }
        }
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, '', '2040-02-14 23:31:30.000')
        """
      }
    }

    @Test func insertSelectSQL() {
      assertQuery(
        RemindersList.insert {
          $0.title
        } select: {
          Values(#sql("'Groceries'"))
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "remindersLists"
        ("title")
        SELECT 'Groceries'
        RETURNING "id"
        """
      } results: {
        """
        ┌───┐
        │ 4 │
        └───┘
        """
      }
    }
  }
}

@Table private struct Item {
  var title = ""
  var quantity = 0
  @Column(as: [String].JSONRepresentation.self)
  var notes: [String] = []
}
