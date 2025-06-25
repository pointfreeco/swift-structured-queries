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
        } onConflictDoUpdate: {
          $0.title += " Copy"
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("remindersListID", "title", "isCompleted", "dueDate", "priority")
        VALUES
        (1, 'Groceries', 1, '2001-01-01 00:00:00.000', 3), (2, 'Haircut', 0, '1970-01-01 00:00:00.000', 1)
        ON CONFLICT DO UPDATE SET "title" = ("reminders"."title" || ' Copy')
        RETURNING "id"
        """
      } results: {
        """
        ┌────┐
        │ 11 │
        │ 12 │
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
          Reminder.Draft(remindersListID: 1, title: "Check voicemail")
        }
        .returning(\.id)
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (NULL, NULL, NULL, 0, 0, '', NULL, 1, 'Check voicemail', '2040-02-14 23:31:30.000')
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
        │ 13 │
        │ 14 │
        └────┘
        """
      }
    }

    @Test func upsertWithID() {
      assertQuery(Reminder.where { $0.id == 1 }) {
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

    @Test func onConflictWhereDoUpdateWhere() {
      assertQuery(
        Reminder.insert {
          Reminder.Draft(remindersListID: 1)
        } onConflict: {
          $0.id
        } where: {
          !$0.isCompleted
        } doUpdate: {
          $0.isCompleted = true
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
        DO UPDATE SET "isCompleted" = 1
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

    @Test func insertTableSelectionColumns() {
      // _ = Item(title: "Pencil Box", quantity: 100, notes: #bind([]))
      assertInlineSnapshot(
        of: Item.insert {
          Item.Columns(title: "Pencil Box", quantity: 100, notes: #bind([]))
        },
        as: .sql
      ) {
        """
        INSERT INTO "items"
        ("title", "quantity", "notes")
        VALUES
        ('Pencil Box', 100, '[

        ]')
        """
      }
    }
  }
}

extension TableSelection {
  public static func insert(
    @InsertValuesBuilder<Columns>
    _ rows: () -> [Columns]
  ) -> InsertOf<Self> {
    var values: [[QueryFragment]] = []
    for row in rows() {
      var value: [QueryFragment] = []
      defer { values.append(value) }
      for column in row.allColumns {
        value.append(column.queryFragment)
      }
    }
    return Insert(
      conflictResolution: nil,
      columnNames: TableColumns.allColumns.map(\.name),
      conflictTargetColumnNames: [],
      conflictTargetFilter: [],
      values: .values(values),
      updates: nil,
      updateFilter: [],
      returning: []
    )
  }
}

public protocol SelectionColumns<QueryValue>: QueryExpression where QueryValue: TableSelection {
  var allColumns: [any QueryExpression] { get }
}

extension SelectionColumns {
  public var queryFragment: QueryFragment {
    zip(QueryValue.TableColumns.allColumns, allColumns)
      .map { "\($1) AS \(quote: $0.name)" }.joined(separator: ", ")
  }
}

public protocol TableSelection<Columns>: Table {
  associatedtype Columns: SelectionColumns<Self>
}

private struct Item: TableSelection {
  var title = ""
  var quantity = 0
  var notes: [String] = []

  public struct Columns: SelectionColumns {
    public typealias QueryValue = Item
    public let allColumns: [any QueryExpression]
    public init(
      title: some StructuredQueriesCore.QueryExpression<Swift.String>,
      quantity: some StructuredQueriesCore.QueryExpression<Swift.Int>,
      notes: some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation>
    ) {
      self.allColumns = [title, quantity, notes]
    }
  }

  public struct TableColumns: StructuredQueriesCore.TableDefinition {
    public typealias QueryValue = Item
    public let title = StructuredQueriesCore.TableColumn<QueryValue, Swift.String>(
      "title",
      keyPath: \QueryValue.title,
      default: ""
    )
    public let quantity = StructuredQueriesCore.TableColumn<QueryValue, Swift.Int>(
      "quantity",
      keyPath: \QueryValue.quantity,
      default: 0
    )
    public let notes = StructuredQueriesCore.TableColumn<QueryValue, [String].JSONRepresentation>(
      "notes",
      keyPath: \QueryValue.notes,
      default: []
    )
    public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
      [QueryValue.columns.title, QueryValue.columns.quantity, QueryValue.columns.notes]
    }
  }
}

extension Item: StructuredQueriesCore.Table {
  public static let columns = TableColumns()
  public static let tableName = "items"
  public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
    self.title = try decoder.decode(Swift.String.self) ?? ""
    self.quantity = try decoder.decode(Swift.Int.self) ?? 0
    self.notes = try decoder.decode([String].JSONRepresentation.self) ?? []
  }

  @available(*, unavailable, message: "Use 'Item.Columns.init', instead.")
  public init(
    title: some StructuredQueriesCore.QueryExpression<Swift.String>,
    quantity: some StructuredQueriesCore.QueryExpression<Swift.Int>,
    notes: some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation>
  ) {
    fatalError()
  }
}

@Table private struct _Item {
  var title = ""
  var quantity = 0
  @Column(as: [String].JSONRepresentation.self)
  var notes: [String] = []
}
