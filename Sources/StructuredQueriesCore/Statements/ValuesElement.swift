package struct ValuesElement: Sendable {
  package let offset: Int
  package let decodableType: (any QueryDecodable.Type)?
  package let columns: [Column]

  package init(
    offset: Int,
    decodableType: (any QueryDecodable.Type)?,
    columns: [Column]
  ) {
    self.offset = offset
    self.decodableType = decodableType
    self.columns = columns
  }

  package struct Column: Sendable {
    package let name: String?
    package let decoding: @Sendable (QueryFragment) -> QueryFragment

    package init(name: String?, decoding: @escaping @Sendable (QueryFragment) -> QueryFragment) {
      self.name = name
      self.decoding = decoding
    }

    fileprivate init<R, V>(_ column: some TableColumnExpression<R, V>) {
      self.init(name: column.name, decoding: { V.queryFragment(decoding: $0) })
    }
  }

  package static func elements<each V>(
    for types: repeat (each V).Type
  ) -> [ValuesElement] {
    var elements: [ValuesElement] = []
    var offset = 0
    for type in repeat each types {
      func append<T>(_: T.Type) {
        let alignment = MemoryLayout<T>.alignment
        offset = (offset + alignment - 1) / alignment * alignment
        let columns: [Column]
        if let table = T.self as? any Table.Type {
          columns = table.allValuesElementColumns
        } else {
          columns = [Column(name: nil, decoding: decoding(T.self))]
        }
        elements.append(
          ValuesElement(
            offset: offset,
            decodableType: T.self as? any QueryDecodable.Type,
            columns: columns
          )
        )
        offset += MemoryLayout<T>.size
      }
      append(type)
    }
    return elements
  }

  private static func decoding(_ type: Any.Type) -> @Sendable (QueryFragment) -> QueryFragment {
    guard let representable = type as? any QueryRepresentable.Type else { return { $0 } }
    func open<U: QueryRepresentable>(_: U.Type) -> @Sendable (QueryFragment) -> QueryFragment {
      { U.queryFragment(decoding: $0) }
    }
    return open(representable)
  }
}

extension [ValuesElement] {
  package func columnIndex<Value>(of keyPath: PartialKeyPath<Value>) -> Int? {
    if let table = Value.self as? any Table.Type,
      let index = table.columnIndex(of: keyPath)
    {
      return index
    }
    guard let target = MemoryLayout<Value>.offset(of: keyPath) else { return nil }
    var position = 0
    for element in self {
      if element.columns.count == 1 {
        if element.offset == target {
          return position
        }
        position += 1
      } else {
        if let table = element.decodableType as? any Table.Type,
          target >= element.offset,
          let field = table.columnFieldOffsets.firstIndex(of: target - element.offset),
          field < element.columns.count
        {
          return position + field
        }
        position += element.columns.count
      }
    }
    return nil
  }
}

extension Table {
  package static var valuesElement: ValuesElement {
    ValuesElement(
      offset: 0,
      decodableType: Self.self,
      columns: allValuesElementColumns
    )
  }

  package static var writableValuesElement: ValuesElement {
    ValuesElement(
      offset: 0,
      decodableType: Self.self,
      columns: writableValuesElementColumns
    )
  }

  fileprivate static var allValuesElementColumns: [ValuesElement.Column] {
    TableColumns.allColumns.map { ValuesElement.Column($0) }
  }

  fileprivate static var writableValuesElementColumns: [ValuesElement.Column] {
    TableColumns.writableColumns.map { ValuesElement.Column($0) }
  }

  fileprivate static func columnIndex(of keyPath: AnyKeyPath) -> Int? {
    TableColumns.allColumns.firstIndex { column in
      func open<R, V>(_ column: some TableColumnExpression<R, V>) -> AnyKeyPath {
        column.keyPath
      }
      return open(column) == keyPath
    }
  }

  fileprivate static var columnFieldOffsets: [Int] {
    TableColumns.allColumns.map { column in
      func offset<C: TableColumnExpression>(_ column: C) -> Int {
        MemoryLayout<C.Root>.offset(of: column.keyPath) ?? 0
      }
      return offset(column)
    }
  }
}
