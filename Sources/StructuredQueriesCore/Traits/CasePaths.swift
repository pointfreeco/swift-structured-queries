#if CasePaths
  #if EXCLUDE_EXPORTS
    public import CasePaths
  #else
    @_exported import CasePaths
  #endif

  extension ColumnGroup where QueryValue: CasePathable & Table {
    /// A Boolean query expression that checks if the given enum columns will be decoded for the
    /// given case.
    ///
    /// - Parameter keyPath: A key path from enum columns to a case.
    /// - Returns: A Boolean query expression
    public func `is`<V>(
      _ keyPath: KeyPath<QueryValue.TableColumns, TableColumn<Values.QueryOutput, V>>
    ) -> some QueryExpression<Bool> {
      SQLQueryExpression(
        self[dynamicMember: keyPath]._allColumns.map {
          "(\($0.queryFragment) IS NOT NULL)"
        }
        .joined(separator: " OR ")
      )
    }

    /// A Boolean query expression that checks if the given enum columns will be decoded for the
    /// given case.
    ///
    /// - Parameter keyPath: A key path from enum columns to a case.
    /// - Returns: A Boolean query expression
    public func `is`<V>(
      _ keyPath: KeyPath<QueryValue.TableColumns, ColumnGroup<Values.QueryOutput, V>>
    ) -> some QueryExpression<Bool> {
      return SQLQueryExpression(
        self[dynamicMember: keyPath]._allColumns.map {
          "(\($0.queryFragment) IS NOT NULL)"
        }
        .joined(separator: " OR ")
      )
    }
  }
#endif
