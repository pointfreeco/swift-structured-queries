import IssueReporting
public import StructuredQueriesCore

/// A `VALUES` statement.
///
/// Selects one or more rows of values. The trailing closure is a result builder that will select
/// any number of rows, one after the other, and supports basic control flow statements.
///
/// ```swift
/// Values {
///   (1, "Hello")
///   (2, "Goodbye")
/// }
/// // VALUES (1, 'Hello'), (2, 'Goodbye')
/// // => (Int, String)
/// ```
///
/// While not particularly useful on its own, it can act as a helpful starting point for recursive
/// common table expressions and other subqueries.
public struct Values<QueryValue>: PartialSelectStatement {
  public typealias From = Never

  private let rows: [[QueryFragment]]
  package let _elements: [_ValuesElement]

  public init(@InsertValuesBuilder<QueryValue> _ values: () -> ValuesRows<QueryValue>) {
    let built = values()
    rows = built.rows
    _elements = built.elements
  }

  public var query: QueryFragment {
    guard !rows.isEmpty else { return "" }
    var query: QueryFragment = "VALUES "
    query.append(
      rows
        .map { "(\($0.joined(separator: ", ")))" as QueryFragment }
        .joined(separator: ", ")
    )
    return query
  }
}

extension Values {
  /// A type that describes a `VALUES` statement's automatically-named columns, `"column1"` through
  /// `"columnN"`.
  ///
  /// Columns are referred to using member syntax, _e.g._ `$0.0` refers to `"column1"` and a
  /// selection's `$0.score` refers to `"score"`.
  @dynamicMemberLookup
  public struct TableColumns: Sendable {
    let elements: [_ValuesElement]

    package init(elements: [_ValuesElement]) {
      self.elements = elements
    }

    public subscript<Member: QueryRepresentable & QueryBindable>(
      dynamicMember keyPath: KeyPath<QueryValue, Member>
    ) -> SQLQueryExpression<Member> {
      let index: Int
      if let found = _valueColumnIndex(of: keyPath, in: elements) {
        index = found
      } else {
        reportIssue("Could not determine the column for the given key path")
        index = 0
      }
      let names = elements.flatMap { $0.columns.map(\.name) }
      let name = names.indices.contains(index) ? names[index] : nil
      return SQLQueryExpression("\(quote: name ?? "column\(index + 1)")", as: Member.self)
    }
  }
}

extension Select where Joins == () {
  /// A `SELECT` statement for the rows of a ``Values`` statement.
  ///
  /// Selects each of the given statement's automatically-named columns, `"column1"` through
  /// `"columnN"`, which can be referred to in other clauses using tuple member syntax.
  ///
  /// ```swift
  /// Select(
  ///   Values {
  ///     (1, "Hello", true)
  ///     (2, "Goodbye", false)
  ///   }
  /// )
  /// .where { $0.2 }
  /// // SELECT "column1", "column2", "column3"
  /// // FROM (VALUES (1, 'Hello', 1), (2, 'Goodbye', 0))
  /// // WHERE ("column3")
  /// ```
  ///
  /// - Parameter values: A statement whose values are selected.
  public init(_ values: Values<Columns>)
  where From == Values<Columns> {
    let elements = values._elements
    var columns: [QueryFragment] = []
    var position = 0
    for element in elements {
      for column in element.columns {
        let decoded = column.decoding("\(quote: "column\(position + 1)")")
        if let name = column.name {
          columns.append("\(decoded) AS \(quote: name)")
        } else {
          columns.append(decoded)
        }
        position += 1
      }
    }
    var from = values.queryFragment
    if let table = Columns.self as? any Table.Type {
      from.append(" AS \(quote: table.tableName)")
    }
    self.init(
      _valuesColumns: columns,
      elements: elements,
      from: from,
      isEmpty: values.query.isEmpty
    )
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter keyPath: A key path from this select's values to a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`<Predicate: _OptionalPromotable<Bool?>>(
    _ keyPath: KeyPath<Columns, Predicate>
  ) -> Self
  where From == Values<Columns>, Predicate: QueryRepresentable & QueryBindable {
    _where(_valueColumn(keyPath).queryFragment)
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by from this select's columns.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`(
    @QueryFragmentBuilder<Bool>
    _ predicate: (Values<Columns>.TableColumns) -> [QueryFragment]
  ) -> Self
  where From == Values<Columns> {
    var select = self
    for fragment in predicate(Values<Columns>.TableColumns(elements: _valuesElements)) {
      select = select._where(fragment)
    }
    return select
  }

  /// Creates a new select statement from this one by appending a column to its `ORDER BY` clause.
  ///
  /// - Parameter ordering: A key path to a value to order by.
  /// - Returns: A new select statement that appends the given column to its `ORDER BY` clause.
  public func order<Member: QueryRepresentable & QueryBindable>(
    by ordering: KeyPath<Columns, Member>
  ) -> Self
  where From == Values<Columns> {
    _order(_valueColumn(ordering).queryFragment)
  }

  /// Creates a new select statement from this one by appending columns to its `ORDER BY` clause.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by from this
  ///   select's columns.
  /// - Returns: A new select statement that appends the returned columns to its `ORDER BY` clause.
  public func order(
    @QueryFragmentBuilder<()>
    by ordering: (Values<Columns>.TableColumns) -> [QueryFragment]
  ) -> Self
  where From == Values<Columns> {
    var select = self
    for fragment in ordering(Values<Columns>.TableColumns(elements: _valuesElements)) {
      select = select._order(fragment)
    }
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// The columns are passed to the closure as individual arguments.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`<each C: QueryExpression>(
    @QueryFragmentBuilder<Bool>
    _ predicate: (repeat ValuesColumns<each C>) -> [QueryFragment]
  ) -> Self
  where From == Values<(repeat each C)> {
    var select = self
    let columns: (repeat ValuesColumns<each C>) = _valueColumnNames()
    for fragment in predicate(repeat each columns) {
      select = select._where(fragment)
    }
    return select
  }

  /// Creates a new select statement from this one by appending columns to its `ORDER BY` clause.
  ///
  /// The columns are passed to the closure as individual arguments.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A new select statement that appends the returned columns to its `ORDER BY` clause.
  public func order<each C: QueryExpression>(
    @QueryFragmentBuilder<()>
    by ordering: (repeat ValuesColumns<each C>) -> [QueryFragment]
  ) -> Self
  where From == Values<(repeat each C)> {
    var select = self
    let columns: (repeat ValuesColumns<each C>) = _valueColumnNames()
    for fragment in ordering(repeat each columns) {
      select = select._order(fragment)
    }
    return select
  }

  private func _valueColumnNames<each C: QueryExpression>()
    -> (repeat ValuesColumns<each C>)
  where From == Values<(repeat each C)> {
    let names = _valuesElements.flatMap { $0.columns.map(\.name) }
    var index = 0
    func column<Value: QueryExpression>(_: Value.Type) -> ValuesColumns<Value> {
      let width = Value._columnWidth
      defer { index += width }
      return ValuesColumns(
        columns: (index..<index + width).map { position in
          let name = names.indices.contains(position) ? names[position] : nil
          return "\(quote: name ?? "column\(position + 1)")"
        }
      )
    }
    return (repeat column((each C).self))
  }

  private func _valueColumn<Member: QueryRepresentable & QueryBindable>(
    _ keyPath: KeyPath<Columns, Member>
  ) -> SQLQueryExpression<Member>
  where From == Values<Columns> {
    Values<Columns>.TableColumns(elements: _valuesElements)[dynamicMember: keyPath]
  }
}
