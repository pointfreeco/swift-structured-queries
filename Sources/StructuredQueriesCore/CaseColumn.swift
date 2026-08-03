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

  package protocol _CaseColumnExpression {
    var _base: any WritableTableColumnExpression { get }
  }

  extension CaseColumn: _CaseColumnExpression {
    package var _base: any WritableTableColumnExpression { base }
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

  extension OptionalColumnGroup {
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<
        Values.QueryOutput.TableColumns, CaseColumn<Values.QueryOutput, Member>
      >
    ) -> CaseColumn<Root, Member> {
      let column = Values.QueryOutput.columns[keyPath: keyPath].base
      return CaseColumn(
        base: TableColumn<Root, Member?>(
          column.name,
          keyPath: base.keyPath.appending(
            path: \.[flattenedMember: \Member.self, column: column.keyPath]
          )
        )
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<
        Values.QueryOutput.TableColumns, CaseColumnGroup<Values.QueryOutput, Member>
      >
    ) -> CaseColumnGroup<Root, Member> {
      let column = Values.QueryOutput.columns[keyPath: keyPath].base
      return CaseColumnGroup(
        base: ColumnGroup<Root, Member?>(
          column.name,
          keyPath: base.keyPath.appending(
            path: \.[flattenedMember: \Member.self, column: column.keyPath]
          )
        )
      )
    }
  }

  extension CaseColumnGroup {
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<
        Payload.QueryOutput.TableColumns, OptionalColumnGroup<Payload.QueryOutput, Member>
      >
    ) -> OptionalColumnGroup<Root, Member> {
      let column = Payload.QueryOutput.columns[keyPath: keyPath]
      return OptionalColumnGroup(
        base: ColumnGroup<Root, Member?>(
          column.name,
          keyPath: base.keyPath.appending(
            path: \.[flattenedMember: \Member.self, column: column.keyPath]
          )
        )
      )
    }
  }

  public enum _CaseColumn<Root: Table, Value> {
    public static func `for`(
      _ name: String,
      keyPath: KeyPath<Root, Value.QueryOutput?>,
      default defaultValue: Value.QueryOutput? = nil
    ) -> CaseColumn<Root, Value>
    where Value: QueryRepresentable & QueryBindable {
      CaseColumn(base: TableColumn(name, keyPath: keyPath, default: defaultValue))
    }

    public static func `for`(
      _ name: String,
      keyPath: KeyPath<Root, Value.QueryOutput?>,
      default defaultValue: Value.QueryOutput? = nil
    ) -> CaseColumnGroup<Root, Value>
    where Value: QueryRepresentable, Value: Table, Value.QueryOutput: Table {
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
    ) -> any QueryExpression<Payload> {
      get { SQLQueryExpression(Base.columns[keyPath: keyPath].queryFragment) }
      set {
        let group = Base.columns[keyPath: keyPath]
        let writableNames = Set(group._writableColumns.map(\.name))
        for (column, value) in zip(group._allColumns, newValue._allColumns)
        where writableNames.contains(column.name) {
          updates.append((column.name, value.queryFragment))
        }
        for other in Base.TableColumns.allColumns where !group._names.contains(other.name) {
          updates.append((other.name, "NULL"))
        }
      }
    }

    @_disfavoredOverload
    public subscript<Payload>(
      dynamicMember keyPath: KeyPath<Base.TableColumns, CaseColumnGroup<Base, Payload>>
    ) -> _CaseGroupUpdate<Payload> {
      get { _CaseGroupUpdate() }
      set {}
    }
  }

  @dynamicMemberLookup
  public struct _CaseGroupUpdate<Payload: Table> where Payload.QueryOutput: Table {
    @available(
      *,
      unavailable,
      message: "Assign the entire case, instead: '$0.enum = .case(value)'"
    )
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Payload.TableColumns, TableColumn<Payload.QueryOutput, Member>>
    ) -> any QueryExpression<Member> {
      get { fatalError() }
      set {}
    }

    @available(
      *,
      unavailable,
      message: "Assign the entire case, instead: '$0.enum = .case(value)'"
    )
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Payload.TableColumns, ColumnGroup<Payload.QueryOutput, Member>>
    ) -> _CaseGroupUpdate<Member> {
      get { fatalError() }
      set {}
    }
  }

  extension UpdatesGroup {
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Values.TableColumns, CaseColumn<Values.QueryOutput, Member>>
    ) -> any QueryExpression<Member?> {
      group[dynamicMember: keyPath]
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Values.TableColumns, CaseColumn<Values.QueryOutput, Member>>
    ) -> any QueryExpression<Member> {
      get { SQLQueryExpression(group[dynamicMember: keyPath].queryFragment) }
      set {
        let column = group[dynamicMember: keyPath]
        updates.append((column.name, newValue.queryFragment))
        for other in Values.QueryOutput.TableColumns.allColumns where other.name != column.name {
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
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Values.TableColumns, CaseColumn<Values.QueryOutput, Member>>
    ) -> Member.QueryOutput {
      get { fatalError() }
      set {}
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<
        Values.TableColumns, CaseColumnGroup<Values.QueryOutput, Member>
      >
    ) -> any QueryExpression<Member> {
      get { SQLQueryExpression(group[dynamicMember: keyPath].queryFragment) }
      set {
        let caseGroup = group[dynamicMember: keyPath]
        let writableNames = Set(caseGroup._writableColumns.map(\.name))
        for (column, value) in zip(caseGroup._allColumns, newValue._allColumns)
        where writableNames.contains(column.name) {
          updates.append((column.name, value.queryFragment))
        }
        for other in Values.QueryOutput.TableColumns.allColumns
        where !caseGroup._names.contains(other.name) {
          updates.append((other.name, "NULL"))
        }
      }
    }

    @_disfavoredOverload
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<
        Values.TableColumns, CaseColumnGroup<Values.QueryOutput, Member>
      >
    ) -> _CaseGroupUpdate<Member> {
      get { _CaseGroupUpdate() }
      set {}
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
