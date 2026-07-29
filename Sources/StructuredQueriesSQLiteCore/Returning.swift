public import StructuredQueriesCore

extension Delete {
  /// Adds a returning clause to a delete statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  #endif
  public func returning<each QueryValue: QueryRepresentable>(
    _ selection: (From.TableColumns) -> (repeat TableColumn<From, each QueryValue>)
  ) -> Delete<From, (repeat each QueryValue)> {
    var returning: [QueryFragment] = []
    for resultColumn in repeat each selection(From.columns) {
      returning.append(resultColumn.returningFragment)
    }
    return _returning(returning)
  }

  // NB: This overload allows for 'returning(\.self)'.
  /// Adds a returning clause to a delete statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  @_documentation(visibility: private)
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  #endif
  public func returning(
    _ selection: (From.TableColumns) -> From.TableColumns
  ) -> Delete<From, From> {
    var returning: [QueryFragment] = []
    for resultColumn in From.TableColumns.allColumns {
      returning.append(resultColumn.returningFragment)
    }
    return _returning(returning)
  }
}

extension Insert {
  /// Adds a returning clause to an insert statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  #endif
  public func returning<each QueryValue: QueryRepresentable>(
    _ selection: (Into.TableColumns) -> (repeat TableColumn<Into, each QueryValue>)
  ) -> Insert<Into, (repeat each QueryValue)> {
    var returning: [QueryFragment] = []
    for resultColumn in repeat each selection(Into.columns) {
      returning.append(resultColumn.returningFragment)
    }
    return _returning(returning)
  }

  // NB: This overload allows for 'returning(\.self)'.
  /// Adds a returning clause to an insert statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  @_documentation(visibility: private)
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  #endif
  public func returning(
    _ selection: (Into.TableColumns) -> Into.TableColumns
  ) -> Insert<Into, Into> {
    var returning: [QueryFragment] = []
    for resultColumn in Into.TableColumns.allColumns {
      returning.append(resultColumn.returningFragment)
    }
    return _returning(returning)
  }
}

extension Update {
  /// Adds a returning clause to an update statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  #endif
  public func returning<each QueryValue: QueryRepresentable>(
    _ selection: (From.TableColumns) -> (repeat TableColumn<From, each QueryValue>)
  ) -> Update<From, (repeat each QueryValue)> {
    var returning: [QueryFragment] = []
    for resultColumn in repeat each selection(From.columns) {
      returning.append(resultColumn.returningFragment)
    }
    return _returning(returning)
  }

  // NB: This overload allows for 'returning(\.self)'.
  /// Adds a returning clause to an update statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  @_documentation(visibility: private)
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  #endif
  public func returning(
    _ selection: (From.TableColumns) -> From.TableColumns
  ) -> Update<From, From> {
    var returning: [QueryFragment] = []
    for resultColumn in From.TableColumns.allColumns {
      returning.append(resultColumn.returningFragment)
    }
    return _returning(returning)
  }
}
