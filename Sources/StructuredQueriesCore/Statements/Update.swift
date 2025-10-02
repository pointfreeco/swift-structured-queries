extension Table {
  /// An update statement.
  ///
  /// The trailing closure of this method allows you to set any field on the table. For example,
  /// constructing an update statement that sets the title of the reminder with "id" equal to 1:
  ///
  /// ```swift
  /// Reminder.update {
  ///   $0.title = "Get haircut"
  /// }
  /// .where { $0.id.eq(1) }
  /// // UPDATE "reminders"
  /// // SET "title" = 'Get haircut'
  /// // WHERE "id" = 1
  /// ```
  ///
  /// There is also a subset of mutations you can make to the argument of the trailing closure that
  /// is translated into the equivalent SQL. For example, to append "!" to the title of every row,
  /// one can do this:
  ///
  /// ```swift
  /// Reminder.update {
  ///   $0.title += "!"
  /// }
  /// // UPDATE "reminders"
  /// // SET "title" = "title" || 'Get haircut'
  /// ```
  ///
  /// The syntax `$0.title += "!"` is translated into the equivalent SQL of
  /// `"title" = "title" || 'Get haircut'`
  ///
  /// - Parameter updates: A closure describing column-wise updates to perform.
  /// - Returns: An update statement.
  public static func update(
    set updates: (inout Updates<Self>) -> Void
  ) -> UpdateOf<Self> {
    Where().update(set: updates)
  }
}

extension PrimaryKeyedTable {
  /// An update statement for the values of a given record.
  ///
  /// This method is defined only on ``PrimaryKeyedTable`` conformances (see
  /// <doc:PrimaryKeyedTables> for more info), and it constructs an update statement that sets
  /// every field of the row whose ID matches the "id" of the model:
  ///
  /// ```swift
  /// @Table
  /// struct Tag {
  ///   let id: Int
  ///   var name: String
  /// }
  ///
  /// Tag.update(Tag(id: 1, name: "home"))
  /// // UPDATE "tags" SET "name" = 'home' WHERE "id" = 1
  /// ```
  ///
  /// - Parameter row: A row to update.
  /// - Returns: An update statement.
  public static func update(
    _ row: Self
  ) -> UpdateOf<Self> {
    update { updates in
      for column in TableColumns.writableColumns
      where !columns.primaryKey._names.contains(column.name) {
        func open<Root, Value>(_ column: some WritableTableColumnExpression<Root, Value>) {
          updates.set(
            column,
            Value(queryOutput: (row as! Root)[keyPath: column.keyPath]).queryFragment
          )
        }
        open(column)
      }
    }
    .where {
      $0.primaryKey.eq(PrimaryKey(queryOutput: row[keyPath: $0.primaryKey.keyPath]))
    }
  }
}

/// An `UPDATE` statement.
///
/// This type of statement is constructed from ``Table/update(set:)`` and ``Where/update(set:)``.
///
/// To learn more, see <doc:UpdateStatements>.
public struct Update<From: Table, Returning> {
  var isEmpty: Bool
  package var conflictResolution: QueryFragment?
  var updates: Updates<From>
  var `where`: [QueryFragment]
  var returning: [QueryFragment]

  package init(
    isEmpty: Bool,
    conflictResolution: QueryFragment? = nil,
    updates: Updates<From>,
    where: [QueryFragment] = [],
    returning: [QueryFragment] = []
  ) {
    self.isEmpty = isEmpty
    self.conflictResolution = conflictResolution
    self.updates = updates
    self.where = `where`
    self.returning = returning
  }

  /// Adds a condition to an update statement.
  ///
  /// ```swift
  /// Reminder.update { $0.isFlagged = true }.where(\.isCompleted)
  /// // UPDATE "reminders" SET "isFlagged" = 1 WHERE "reminders"."isCompleted"
  /// ```
  ///
  /// - Parameter keyPath: A key path to a Boolean expression to filter by.
  /// - Returns: A statement with the added predicate.
  public func `where`(
    _ keyPath: KeyPath<From.TableColumns, some QueryExpression<some _OptionalPromotable<Bool?>>>
  ) -> Self {
    var update = self
    update.where.append(From.columns[keyPath: keyPath].queryFragment)
    return update
  }

  /// Adds a condition to an update statement.
  ///
  /// - Parameter predicate: A closure that returns a Boolean expression to filter by.
  /// - Returns: A statement with the added predicate.
  @_disfavoredOverload
  public func `where`(
    _ predicate: (From.TableColumns) -> some QueryExpression<some _OptionalPromotable<Bool?>>
  ) -> Self {
    var update = self
    update.where.append(predicate(From.columns).queryFragment)
    return update
  }

  /// Adds a condition to an update statement.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A statement with the added predicate.
  public func `where`(
    @QueryFragmentBuilder<Bool> _ predicate: (From.TableColumns) -> [QueryFragment]
  ) -> Self {
    var update = self
    update.where.append(contentsOf: predicate(From.columns))
    return update
  }

  /// Adds a returning clause to an update statement.
  ///
  /// ```swift
  /// Reminder.update { $0.isFlagged = true }.returning { ($0.id, $0.title) }
  /// // UPDATE "reminders" SET "isFlagged" = 1 RETURNING "id", "title"
  ///
  /// Reminder.update { $0.isFlagged = true }.returning(\.self)
  /// // UPDATE "reminders" SET "isFlagged" = 1 RETURNING …
  /// ```
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  public func returning<each QueryValue: QueryRepresentable>(
    _ selection: (From.TableColumns) -> (repeat TableColumn<From, each QueryValue>)
  ) -> Update<From, (repeat each QueryValue)> {
    var returning: [QueryFragment] = []
    for resultColumn in repeat each selection(From.columns) {
      returning.append("\(quote: resultColumn.name)")
    }
    return Update<From, (repeat each QueryValue)>(
      isEmpty: false,
      conflictResolution: conflictResolution,
      updates: updates,
      where: `where`,
      returning: returning
    )
  }

  // NB: This overload allows for 'returning(\.self)'.
  /// Adds a returning clause to an update statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  @_documentation(visibility: private)
  public func returning(
    _ selection: (From.TableColumns) -> From.TableColumns
  ) -> Update<From, From> {
    var returning: [QueryFragment] = []
    for resultColumn in From.TableColumns.allColumns {
      returning.append("\(quote: resultColumn.name)")
    }
    return Update<From, From>(
      isEmpty: isEmpty,
      conflictResolution: conflictResolution,
      updates: updates,
      where: `where`,
      returning: returning
    )
  }
}

/// A convenience type alias for a non-`RETURNING ``Update``.
public typealias UpdateOf<Base: Table> = Update<Base, ()>

extension Update: Statement {
  public typealias QueryValue = Returning

  public var query: QueryFragment {
    guard !isEmpty, !updates.isEmpty
    else { return "" }

    var query: QueryFragment = "UPDATE "
    if let conflictResolution {
      query.append("OR \(conflictResolution) ")
    }
    if let schemaName = From.schemaName {
      query.append("\(quote: schemaName).")
    }
    query.append("\(quote: From.tableName)")
    if let tableAlias = From.tableAlias {
      query.append(" AS \(quote: tableAlias)")
    }
    query.append("\(.newlineOrSpace)\(updates)")
    if !`where`.isEmpty {
      query.append("\(.newlineOrSpace)WHERE \(`where`.joined(separator: " AND "))")
    }
    if !returning.isEmpty {
      query.append("\(.newlineOrSpace)RETURNING \(returning.joined(separator: ", "))")
    }
    return query
  }
}
