import Foundation
import StructuredQueries
import StructuredQueriesSQLite

// NB: This is a compile-time test for a 'select' overload.
@Table
private struct ReminderRow {
  let reminder: Reminder
  let isPastDue: Bool
  @Column(as: [String].JSONRepresentation.self)
  let tags: [String]
}
private var remindersQuery: some Statement<ReminderRow> {
  Reminder
    .limit(1)
    .select {
      ReminderRow.Columns(
        reminder: $0,
        isPastDue: true,
        tags: #sql("[]")
      )
    }
}

@Table
private struct Foo {
  var id: Int
  var barId: Int?
}
@Table
private struct Bar {
  var id: Int
  var baz: String?
}
func dynamicMemberLookup() {
  _ = Foo.all
    .leftJoin(Bar.all) { $0.barId.eq($1.id) }
    .where { f, b in
      b.baz.is(nil)
    }
}

@Table
struct TableWithComments {
  /// The user's identifier.
  let id: /* TODO: UUID */ Int  // Primary key
  /// The user's email.
  var email: String? = ""  // TODO: Should this be non-optional?
  /// The user's age.
  var age: Int
}

@Table private struct StructTableWithManyFields {
  var a1: Foo?
  var a2: Foo?
  var a3: Foo?
  var a4: Foo?
  var a5: Foo?
  var a6: Foo?
  var a7: Foo?
  var a8: Foo?
  var a9: Foo?
  var a10: Foo?
  var a11: Foo?
  var a12: Foo?
}

@Selection private struct StructSelectionWithManyFields {
  var a1: Foo?
  var a2: Foo?
  var a3: Foo?
  var a4: Foo?
  var a5: Foo?
  var a6: Foo?
  var a7: Foo?
  var a8: Foo?
  var a9: Foo?
  var a10: Foo?
  var a11: Foo?
  var a12: Foo?
}

@DatabaseFunction
private func functionWithLotsOfArguments(
  a1: Foo?,
  a2: Foo?,
  a3: Foo?,
  a4: Foo?,
  a5: Foo?,
  a6: Foo?,
  a7: Foo?,
  a8: Foo?,
  a9: Foo?,
  a10: Foo?,
  a11: Foo?,
  a12: Foo?
) {
}

@Table
private struct TableWithNestedRepresentation {
  struct Nested: Codable, Equatable {
    var x = 0
  }

  enum Status: Int, QueryBindable {
    case active, archived
  }

  let id: Int

  @Column(as: Nested.JSONRepresentation.self)
  var nested: Nested

  @Column(as: Nested.JSONRepresentation.self)
  var nestedWithDefault = Nested(x: 1)

  var status: Status = .active
}
private func nestedRepresentationDraft() {
  _ = TableWithNestedRepresentation.Draft(nested: TableWithNestedRepresentation.Nested())
}
private enum Namespace {
  struct Sibling: Codable, Equatable {
    var y = 0
  }

  @Table
  struct TableWithSiblingRepresentation {
    let id: Int

    @Column(as: Sibling.JSONRepresentation.self)
    var sibling: Sibling
  }
}
private func siblingRepresentationDraft() {
  _ = Namespace.TableWithSiblingRepresentation.Draft(sibling: Namespace.Sibling())
}

// NB: Nested access control mismatch
@Table
private struct Item {
  @Selection
  struct Group {
    var a: Int
    var b: Int
  }
  var group: Group?
}

// NB: Witness inference must handle backticks, optional inference, and multiple columns
@Selection
private struct WitnessEdgeCases {
  var `class` = Date(timeIntervalSince1970: 0)
  var note = Optional("hi")
  var stamp = Date(timeIntervalSince1970: 1)
}
private func witnessEdgeCases() {
  _ = WitnessEdgeCases.Columns()
}

// NB: Witness defaults may reference static members of the enclosing type
@Selection
private struct WitnessSelfReference {
  static let epoch = Date(timeIntervalSince1970: 42)
  var startsAt = Self.epoch
  var title: String
}
private func witnessSelfReference() {
  _ = WitnessSelfReference.Columns(title: "ok")
}

// NB: Unannotated '@Column(as:)' primary keys must produce an optional draft column
@Table
private struct InferredRepresentationPrimaryKey {
  @Column(as: UUID.BytesRepresentation.self)
  var id = UUID()
  var title = ""
}
private func inferredRepresentationPrimaryKey() {
  let _: UUID? = InferredRepresentationPrimaryKey.Draft(title: "x").id
  _ = InferredRepresentationPrimaryKey.Draft.Columns(title: "x")
}

@Selection
private struct ReminderWithListTitle {
  let title: String
  let listTitle: String
}
private func joinedStatement<V: QueryRepresentable, From: Table, J: Table>(
  _ statement: Select<V, From, J>,
  by grouping: (From.TableColumns, J.TableColumns) -> some QueryExpression
) -> Select<V, From, J> {
  statement
}
private func joinedStatements() {
  _ = joinedStatement(
    Reminder
      .order(by: \.id)
      .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
      .select { ReminderWithListTitle.Columns(title: $0.title, listTitle: $1.title) },
    by: { $1.title }
  )
  _ = joinedStatement(
    Reminder
      .order(by: \.id)
      .leftJoin(RemindersList.all) { $0.remindersListID.eq($1.id) }
      .select { ReminderWithListTitle.Columns(title: $0.title, listTitle: $1.title ?? "") },
    by: { $1.title }
  )
  _ = joinedStatement(
    Reminder
      .order(by: \.id)
      .rightJoin(RemindersList.all) { $0.remindersListID.eq($1.id) }
      .select { ReminderWithListTitle.Columns(title: $0.title ?? "", listTitle: $1.title) },
    by: { $1.title }
  )
  _ = joinedStatement(
    Reminder
      .order(by: \.id)
      .fullJoin(RemindersList.all) { $0.remindersListID.eq($1.id) }
      .select { ReminderWithListTitle.Columns(title: $0.title ?? "", listTitle: $1.title ?? "") },
    by: { $1.title }
  )
}
