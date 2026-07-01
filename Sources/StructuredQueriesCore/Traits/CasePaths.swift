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
      _ keyPath: KeyPath<Values.TableColumns, TableColumn<Values.QueryOutput, V>>
    ) -> some QueryExpression<Bool> {
      self[dynamicMember: keyPath].isNot(nil)
    }

    /// A Boolean query expression that checks if the given enum columns will be decoded for the
    /// given case.
    ///
    /// - Parameter keyPath: A key path from enum columns to a case.
    /// - Returns: A Boolean query expression
    public func `is`<V>(
      _ keyPath: KeyPath<Values.TableColumns, ColumnGroup<Values.QueryOutput, V>>
    ) -> some QueryExpression<Bool> {
      self[dynamicMember: keyPath].isNot(nil)
    }
  }
#endif
