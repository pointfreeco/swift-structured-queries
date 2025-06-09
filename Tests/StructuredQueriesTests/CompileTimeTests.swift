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
