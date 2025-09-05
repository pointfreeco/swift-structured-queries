extension Table {
  /// An update statement.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - updates: A closure describing column-wise updates to perform.
  /// - Returns: An update statement.
  public static func update(
    or conflictResolution: ConflictResolution,
    set updates: (inout Updates<Self>) -> Void
  ) -> UpdateOf<Self> {
    var update = Where().update(set: updates)
    update.conflictResolution = conflictResolution.queryFragment
    return update
  }
}

extension PrimaryKeyedTable {
  /// An update statement for the values of a given record.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - row: A row to update.
  /// - Returns: An update statement.
  public static func update(
    or conflictResolution: ConflictResolution,
    _ row: Self
  ) -> UpdateOf<Self> {
    var update = update(row)
    update.conflictResolution = conflictResolution.queryFragment
    return update
  }
}

extension Where {
  /// An update statement for the filtered table.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - updates: A closure describing column-wise updates to perform.
  /// - Returns: An update statement.
  public func update(
    or conflictResolution: ConflictResolution,
    set updates: (inout Updates<From>) -> Void
  ) -> UpdateOf<From> {
    var update = update(set: updates)
    update.conflictResolution = conflictResolution.queryFragment
    return update
  }
}
