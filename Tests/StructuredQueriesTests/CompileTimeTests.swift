import StructuredQueries

// NB: This is a compile-time test for a 'select' overload.
@Selection
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
