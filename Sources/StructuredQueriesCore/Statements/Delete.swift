extension Table {
  /// A delete statement for a table.
  ///
  /// ```swift
  /// Reminder.delete()
  /// // DELETE FROM "reminders"
  /// ```
  ///
  /// - Returns: A delete statement.
  public static func delete() -> DeleteOf<Self> {
    Where().delete()
  }
}

extension PrimaryKeyedTable {
  /// A delete statement for a table row.
  ///
  /// ```swift
  /// Reminder.delete(reminder)
  /// // DELETE FROM "reminders" WHERE "reminders"."id" = 1
  /// ```
  ///
  /// - Parameter row: A row to delete.
  /// - Returns: A delete statement.
  public static func delete(_ row: Self) -> DeleteOf<Self> {
    delete()
      .where {
        $0.primaryKey.eq(PrimaryKey(queryOutput: row[keyPath: $0.primaryKey.keyPath]))
      }
  }
}

/// A `DELETE` statement.
///
/// This type of statement is constructed from ``Table/delete()`` and ``Where/delete()``.
///
/// To learn more, see <doc:DeleteStatements>.
public struct Delete<From: Table, Returning> {
  var isEmpty: Bool
  var `where`: [QueryFragment] = []
  var returning: [QueryFragment] = []

  /// Adds a condition to a delete statement.
  ///
  /// ```swift
  /// Reminder.delete().where(\.isCompleted)
  /// // DELETE FROM "reminders" WHERE "reminders"."isCompleted"
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

  /// Adds a condition to a delete statement.
  ///
  /// ```swift
  /// Reminder.delete().where(\.isCompleted)
  /// // DELETE FROM "reminders" WHERE "reminders"."isCompleted"
  /// ```
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

  /// Adds a condition to a delete statement.
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

  /// Adds a returning clause to a delete statement.
  ///
  /// ```swift
  /// Reminder.delete().returning { ($0.id, $0.title) }
  /// // DELETE FROM "reminders" RETURNING "id", "title"
  ///
  /// Reminder.delete().returning(\.self)
  /// // DELETE FROM "reminders" RETURNING …
  /// ```
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  public func returning<each QueryValue: QueryRepresentable>(
    _ selection: (From.TableColumns) -> (repeat TableColumn<From, each QueryValue>)
  ) -> Delete<From, (repeat each QueryValue)> {
    var returning: [QueryFragment] = []
    for resultColumn in repeat each selection(From.columns) {
      returning.append("\(quote: resultColumn.name)")
    }
    return Delete<From, (repeat each QueryValue)>(
      isEmpty: isEmpty,
      where: `where`,
      returning: Array(repeat each selection(From.columns))
    )
  }

  // NB: This overload allows for 'returning(\.self)'.
  /// Adds a returning clause to a delete statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  @_documentation(visibility: private)
  public func returning(
    _ selection: (From.TableColumns) -> From.TableColumns
  ) -> Delete<From, From> {
    var returning: [QueryFragment] = []
    for resultColumn in From.TableColumns.allColumns {
      returning.append("\(quote: resultColumn.name)")
    }
    return Delete<From, From>(
      isEmpty: isEmpty,
      where: `where`,
      returning: returning
    )
  }
}

/// A convenience type alias for a non-`RETURNING ``Delete``.
public typealias DeleteOf<From: Table> = Delete<From, ()>

extension Delete: Statement {
  public typealias QueryValue = Returning

  public var query: QueryFragment {
    guard !isEmpty else { return "" }
    var query: QueryFragment = "DELETE FROM "
    if let schemaName = From.schemaName {
      query.append("\(quote: schemaName).")
    }
    query.append("\(quote: From.tableName)")
    if let tableAlias = From.tableAlias {
      query.append(" AS \(quote: tableAlias)")
    }
    if !`where`.isEmpty {
      query.append("\(.newlineOrSpace)WHERE \(`where`.joined(separator: " AND "))")
    }
    if !returning.isEmpty {
      query.append("\(.newlineOrSpace)RETURNING \(returning.joined(separator: ", "))")
    }
    return query
  }
}
