#if CasePaths
  /// A column representing a single case of an enum table.
  ///
  /// Reading a case column produces an optional value, as the case may not be the table's active
  /// case, while writing a case column takes the case's payload and switches the table's active
  /// case.
  ///
  /// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros
  /// to generate values of this type.
  public struct CaseColumn<Root: Table, Payload: QueryRepresentable & QueryBindable>:
    WritableTableColumnExpression
  {
    public typealias QueryValue = Payload?
    public typealias Value = Payload?

    package let base: TableColumn<Root, Payload?>

    package init(base: TableColumn<Root, Payload?>) {
      self.base = base
    }

    public var name: String { base.name }

    public var defaultValue: Payload.QueryOutput?? { base.defaultValue }

    public var keyPath: KeyPath<Root, Payload.QueryOutput?> { base.keyPath }

    public var queryFragment: QueryFragment { base.queryFragment }

    public var _allColumns: [any TableColumnExpression] { [self] }

    public var _writableColumns: [any WritableTableColumnExpression] { [self] }

    public func _aliased<Name: AliasName>(
      _ alias: Name.Type
    ) -> any WritableTableColumnExpression<TableAlias<Root, Name>, Payload?> {
      base._aliased(alias)
    }
  }

  /// A group of columns representing a single case of an enum table.
  ///
  /// Don't create instances of this value directly. Instead, use the `@Table` and `@Column` macros
  /// to generate values of this type.
  @dynamicMemberLookup
  public struct CaseColumnGroup<Root: Table, Payload: Table>: _TableColumnExpression
  where Payload.QueryOutput: Table {
    public typealias QueryValue = Payload?
    public typealias Value = Payload?

    package let base: ColumnGroup<Root, Payload?>

    package init(base: ColumnGroup<Root, Payload?>) {
      self.base = base
    }

    package var name: String { base.name }

    public var _names: [String] { base._names }

    public var defaultValue: Payload.QueryOutput?? { base.defaultValue }

    public var keyPath: KeyPath<Root, Payload.QueryOutput?> { base.keyPath }

    public var queryFragment: QueryFragment { base.queryFragment }

    public var _allColumns: [any TableColumnExpression] { base._allColumns }

    public var _writableColumns: [any WritableTableColumnExpression] { base._writableColumns }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<
        Payload.QueryOutput.TableColumns, TableColumn<Payload.QueryOutput, Member>
      >
    ) -> TableColumn<Root, Member?> {
      let column = Payload.QueryOutput.columns[keyPath: keyPath]
      return TableColumn<Root, Member?>(
        column.name,
        keyPath: base.keyPath.appending(path: \.[member: \Member.self, column: column.keyPath])
      )
    }
  }

  public enum _CaseColumn<Root: Table, Value: QueryRepresentable> {
    public static func `for`(
      _ name: String,
      keyPath: KeyPath<Root, Value.QueryOutput?>,
      default defaultValue: Value.QueryOutput? = nil
    ) -> CaseColumn<Root, Value>
    where Value: QueryBindable {
      CaseColumn(base: TableColumn(name, keyPath: keyPath, default: defaultValue))
    }

    public static func `for`(
      _ name: String,
      keyPath: KeyPath<Root, Value.QueryOutput?>,
      default defaultValue: Value.QueryOutput? = nil
    ) -> CaseColumnGroup<Root, Value>
    where Value: Table, Value.QueryOutput: Table {
      CaseColumnGroup(base: ColumnGroup(name, keyPath: keyPath, default: defaultValue))
    }
  }

  extension ColumnGroup {
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Values.TableColumns, CaseColumn<Values.QueryOutput, Member>>
    ) -> CaseColumn<Root, Member> {
      let column = Values.columns[keyPath: keyPath]
      return CaseColumn(
        base: TableColumn<Root, Member?>(
          column.name,
          keyPath: self.keyPath.appending(path: column.keyPath)
        )
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<
        Values.TableColumns, CaseColumnGroup<Values.QueryOutput, Member>
      >
    ) -> CaseColumnGroup<Root, Member> {
      let column = Values.columns[keyPath: keyPath]
      return CaseColumnGroup(
        base: ColumnGroup<Root, Member?>(
          column.name,
          keyPath: self.keyPath.appending(path: column.keyPath)
        )
      )
    }
  }

  extension Updates {
    public subscript<Payload>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, CaseColumn<Base, Payload>>
    ) -> any QueryExpression<Payload?> {
      Base.columns[keyPath: keyPath]
    }

    public subscript<Payload>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, CaseColumn<Base, Payload>>
    ) -> any QueryExpression<Payload> {
      get { SQLQueryExpression(Base.columns[keyPath: keyPath].queryFragment) }
      set {
        let column = Base.columns[keyPath: keyPath]
        updates.append((column.name, newValue.queryFragment))
        for other in Base.TableColumns.allColumns where other.name != column.name {
          updates.append((other.name, "NULL"))
        }
      }
    }

    @_disfavoredOverload
    @available(
      *,
      unavailable,
      message: """
        Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
        """
    )
    public subscript<Payload>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, CaseColumn<Base, Payload>>
    ) -> Payload.QueryOutput {
      get { fatalError() }
      set {}
    }

    public subscript<Payload>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, CaseColumnGroup<Base, Payload>>
    ) -> Payload.QueryOutput {
      @available(
        *,
        unavailable,
        message: """
          Use '#bind' to explicitly wrap this value in a query expression: '$0.column = #bind(value)'
          """
      )
      get { fatalError() }
      set {
        func open<R, V>(
          _ column: some WritableTableColumnExpression<R, V>
        ) -> QueryFragment {
          V(
            queryOutput: newValue[
              keyPath: column.keyPath as! KeyPath<Payload.QueryOutput, V.QueryOutput>
            ]
          )
          .queryFragment
        }
        let group = Base.columns[keyPath: keyPath]
        updates.append(
          contentsOf: Payload.QueryOutput.TableColumns.writableColumns.map { column in
            (column.name, open(column))
          }
        )
        for other in Base.TableColumns.allColumns where !group._names.contains(other.name) {
          updates.append((other.name, "NULL"))
        }
      }
    }
  }

  extension TableAlias.TableColumns {
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, CaseColumn<Base, Member>>
    ) -> CaseColumn<TableAlias, Member> {
      let column = Base.columns[keyPath: keyPath]
      return CaseColumn(
        base: TableColumn(
          column.name,
          keyPath: \.[member: \Member?.self, column: column.keyPath]
        )
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, CaseColumnGroup<Base, Member>>
    ) -> CaseColumnGroup<TableAlias, Member> {
      let column = Base.columns[keyPath: keyPath]
      return CaseColumnGroup(
        base: ColumnGroup(
          column.name,
          keyPath: \.[member: \Member?.self, column: column.keyPath]
        )
      )
    }
  }
#endif
