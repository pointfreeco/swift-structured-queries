/// A collection of table columns that retains the nesting of column groups while iterating over
/// their flattened leaves.
///
/// SQL addresses a column group's members as flat columns of a single row, while `Codable`
/// addresses them as a nested object. Iterating this collection yields the flat view; ``nodes``
/// yields the nested one.
public struct TableColumnList<Column> {
  /// A column, or a named group of columns.
  public enum Node {
    case column(Column)
    case group(name: String, TableColumnList<Column>)
  }

  public private(set) var nodes: [Node]

  private var flattened: [Column]

  public init() {
    self.nodes = []
    self.flattened = []
  }

  public init(nodes: [Node]) {
    self.nodes = nodes
    self.flattened = nodes.flatMap { node in
      switch node {
      case .column(let column): [column]
      case .group(_, let columns): Array(columns)
      }
    }
  }

  public mutating func append(contentsOf other: Self) {
    nodes.append(contentsOf: other.nodes)
    flattened.append(contentsOf: other.flattened)
  }

  public func transformingColumns(_ transform: (Column) -> Column) -> Self {
    Self(
      nodes: nodes.map { node in
        switch node {
        case .column(let column): .column(transform(column))
        case .group(let name, let columns): .group(name: name, columns.transformingColumns(transform))
        }
      }
    )
  }
}

extension TableColumnList: RandomAccessCollection {
  public var startIndex: Int { flattened.startIndex }

  public var endIndex: Int { flattened.endIndex }

  public subscript(position: Int) -> Column { flattened[position] }
}

extension TableColumnList: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Column...) {
    self.init(nodes: elements.map { .column($0) })
  }
}

extension TableColumnList: Sendable where Column: Sendable {}

extension TableColumnList.Node: Sendable where Column: Sendable {}
