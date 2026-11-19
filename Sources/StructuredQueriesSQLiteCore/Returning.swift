public import StructuredQueriesCore

extension Delete {
  /// Adds a returning clause to a delete statement.
  ///
  /// ```swift
  /// Reminder.delete().returning(\.id)
  /// // DELETE FROM "reminders" RETURNING "id"
  ///
  /// Reminder.delete().returning { ($0.id, $0.title.lowercased()) }
  /// // DELETE FROM "reminders" RETURNING "id", lower("reminders"."title")
  /// ```
  ///
  /// - Parameter selection: A closure that selects the result columns to return from the deleted
  ///   rows. Result columns can be any expression of the table's columns, or `\.self` to return
  ///   entire rows.
  /// - Returns: A statement with a returning clause.
  public func returning<each ResultColumn: QueryExpression>(
    _ selection: (From.TableColumns) -> (repeat each ResultColumn)
  ) -> Delete<From, (repeat (each ResultColumn).QueryValue)>
  where repeat (each ResultColumn).QueryValue: QueryRepresentable {
    _returning(From._returning(selection))
  }
}

extension Insert {
  /// Adds a returning clause to an insert statement.
  ///
  /// - Parameter selection: A closure that selects the result columns to return from the inserted
  ///   rows. Result columns can be any expression of the table's columns, or `\.self` to return
  ///   entire rows.
  /// - Returns: A statement with a returning clause.
  public func returning<each ResultColumn: QueryExpression>(
    _ selection: (Into.TableColumns) -> (repeat each ResultColumn)
  ) -> Insert<Into, (repeat (each ResultColumn).QueryValue)>
  where repeat (each ResultColumn).QueryValue: QueryRepresentable {
    _returning(Into._returning(selection))
  }
}

extension Update {
  /// Adds a returning clause to an update statement.
  ///
  /// - Parameter selection: A closure that selects the result columns to return from the updated
  ///   rows. Result columns can be any expression of the table's columns, or `\.self` to return
  ///   entire rows.
  /// - Returns: A statement with a returning clause.
  public func returning<each ResultColumn: QueryExpression>(
    _ selection: (From.TableColumns) -> (repeat each ResultColumn)
  ) -> Update<From, (repeat (each ResultColumn).QueryValue)>
  where repeat (each ResultColumn).QueryValue: QueryRepresentable {
    _returning(From._returning(selection))
  }
}
