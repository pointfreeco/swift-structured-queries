/// Rows built for an ``Insert`` statement or a `Values` statement.
///
/// This type is produced by ``InsertValuesBuilder`` and is not typically interacted with directly.
public struct ValuesRows<Value>: Sendable {
  package var rows: [[QueryFragment]]
  package var elements: [_ValuesElement]

  package init(rows: [[QueryFragment]] = [], elements: [_ValuesElement] = []) {
    self.rows = rows
    self.elements = elements
  }

  package mutating func append(_ other: Self) {
    rows.append(contentsOf: other.rows)
    if elements.isEmpty {
      elements = other.elements
    }
  }
}

extension ValuesRows: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: [QueryFragment]...) {
    self.init(rows: elements)
  }
}

public struct _ValuesElement: Sendable {
  package let offset: Int
  package let decodableType: (any QueryDecodable.Type)?
  package let columns: [_ValuesElementColumn]

  package init(
    offset: Int,
    decodableType: (any QueryDecodable.Type)?,
    columns: [_ValuesElementColumn]
  ) {
    self.offset = offset
    self.decodableType = decodableType
    self.columns = columns
  }
}

public struct _ValuesElementColumn: Sendable {
  package let name: String?
  package let decoding: @Sendable (QueryFragment) -> QueryFragment

  package init(name: String?, decoding: @escaping @Sendable (QueryFragment) -> QueryFragment) {
    self.name = name
    self.decoding = decoding
  }
}

// NB: Element offsets are computed with the same align-then-advance arithmetic Swift uses to lay
//     out tuples, so that they can be matched against 'MemoryLayout.offset(of:)' key path offsets
//     and used to initialize raw tuple memory when decoding.
package func _valuesElements<each V>(
  for types: repeat (each V).Type
) -> [_ValuesElement] {
  var elements: [_ValuesElement] = []
  var offset = 0
  for type in repeat each types {
    func append<T>(_: T.Type) {
      let alignment = MemoryLayout<T>.alignment
      offset = (offset + alignment - 1) / alignment * alignment
      let columns: [_ValuesElementColumn]
      if let table = T.self as? any Table.Type {
        columns = table._allValuesElementColumns
      } else {
        columns = [_ValuesElementColumn(name: nil, decoding: _valuesDecoding(T.self))]
      }
      elements.append(
        _ValuesElement(
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

package func _valuesDecoding(_ type: Any.Type) -> @Sendable (QueryFragment) -> QueryFragment {
  guard let representable = type as? any QueryRepresentable.Type else { return { $0 } }
  func open<U: QueryRepresentable>(_: U.Type) -> @Sendable (QueryFragment) -> QueryFragment {
    { U.queryFragment(decoding: $0) }
  }
  return open(representable)
}

package func _valuesElementColumn<R, V>(
  _ column: some TableColumnExpression<R, V>
) -> _ValuesElementColumn {
  _ValuesElementColumn(name: column.name, decoding: { V.queryFragment(decoding: $0) })
}

package func _valuesColumnIndex<Value>(
  of keyPath: PartialKeyPath<Value>,
  in elements: [_ValuesElement]
) -> Int? {
  if let table = Value.self as? any Table.Type,
    let index = table._columnIndex(of: keyPath)
  {
    return index
  }
  guard let target = MemoryLayout<Value>.offset(of: keyPath) else { return nil }
  var position = 0
  for element in elements {
    if element.columns.count == 1 {
      if element.offset == target {
        return position
      }
      position += 1
    } else {
      if let table = element.decodableType as? any Table.Type,
        target >= element.offset,
        let field = table._columnFieldOffsets.firstIndex(of: target - element.offset),
        field < element.columns.count
      {
        return position + field
      }
      position += element.columns.count
    }
  }
  return nil
}

extension Table {
  package static func _columnIndex(of keyPath: AnyKeyPath) -> Int? {
    TableColumns.allColumns.firstIndex { column in
      func open<R, V>(_ column: some TableColumnExpression<R, V>) -> AnyKeyPath {
        column.keyPath
      }
      return open(column) == keyPath
    }
  }

  package static var _columnFieldOffsets: [Int] {
    TableColumns.allColumns.map { column in
      func offset<C: TableColumnExpression>(_ column: C) -> Int {
        MemoryLayout<C.Root>.offset(of: column.keyPath) ?? 0
      }
      return offset(column)
    }
  }

  package static var _allValuesElementColumns: [_ValuesElementColumn] {
    TableColumns.allColumns.map { _valuesElementColumn($0) }
  }

  package static var _writableValuesElementColumns: [_ValuesElementColumn] {
    TableColumns.writableColumns.map { _valuesElementColumn($0) }
  }

  package static var _tableValuesElement: _ValuesElement {
    _ValuesElement(
      offset: 0,
      decodableType: Self.self,
      columns: _allValuesElementColumns
    )
  }

  package static var _writableTableValuesElement: _ValuesElement {
    _ValuesElement(
      offset: 0,
      decodableType: Self.self,
      columns: _writableValuesElementColumns
    )
  }
}
