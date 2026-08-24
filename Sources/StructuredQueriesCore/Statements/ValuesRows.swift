/// Rows built for an ``Insert`` statement or a `Values` statement.
///
/// This type is produced by ``InsertValuesBuilder`` and is not typically interacted with directly.
public struct ValuesRows<Value>: Sendable {
  package var rows: [[QueryFragment]]
  package var elements: [ValuesElement]

  package init(rows: [[QueryFragment]] = [], elements: [ValuesElement] = []) {
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
