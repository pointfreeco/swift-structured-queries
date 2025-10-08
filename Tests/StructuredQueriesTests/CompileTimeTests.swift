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
