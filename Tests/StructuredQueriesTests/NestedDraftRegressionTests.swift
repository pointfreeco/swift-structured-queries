import StructuredQueries

@Table struct NestedReminder: Identifiable {
  let id: Int
  var priority: Priority?
  var status: Status = .incomplete
  enum Priority: Int, QueryBindable { case low, high }
  enum Status: Int, QueryBindable { case incomplete, complete }
}

@Table struct GroupKeyed: Identifiable {
  @Selection struct ID: Hashable {
    let recordKey: String
    let recordType: String
  }
  let id: ID
  @Selection struct ParentID: Hashable {
    let parentKey: String
  }
  let parentID: ParentID?
  var name: String
}

func compileChecks() {
  _ = NestedReminder.Draft(priority: .high, status: .complete)
  _ = GroupKeyed.Draft(parentID: nil, name: "x")
}
