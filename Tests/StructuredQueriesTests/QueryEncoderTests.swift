import Foundation
import StructuredQueries
import StructuredQueriesCore
import Testing

@Table private struct EncodedRow {
  let id: Int
  var title = ""
  var score = 0.0
  var note: String?
}

@Selection private struct EncodedDimensions {
  var width = 0
  var height = 0
}

@Table private struct EncodedPhoto {
  let id: Int
  var dimensions: EncodedDimensions = EncodedDimensions()
  var extra: EncodedDimensions?
}

private struct ColumnRecorder: QueryEncoder {
  var names: [[String]] = []
  var leaves: [String] = []

  mutating func encode(_ value: [UInt8]) { leaves.append(String(describing: value)) }
  mutating func encode(_ value: Bool) { leaves.append(String(describing: value)) }
  mutating func encode(_ value: Date) { leaves.append(String(describing: value)) }
  mutating func encode(_ value: Double) { leaves.append(String(describing: value)) }
  mutating func encode(_ value: Int) { leaves.append(String(describing: value)) }
  mutating func encode(_ value: Int64) { leaves.append(String(describing: value)) }
  mutating func encode(_ value: String) { leaves.append(value) }
  mutating func encode(_ value: UInt64) { leaves.append(String(describing: value)) }
  mutating func encode(_ value: UUID) { leaves.append(String(describing: value)) }
  mutating func encodeNull() { leaves.append("NULL") }

  mutating func encode<Column: _TableColumnExpression>(
    _ column: @autoclosure () -> Column,
    _ value: Column.Value.QueryOutput
  ) throws(QueryEncodingError) where Column.Value: QueryEncodable {
    names.append(column()._names)
    try Column.Value(queryOutput: value).encode(to: &self)
  }
}

@Suite struct QueryEncoderTests {
  @Test func declarationOrderAndNames() throws {
    var encoder = ColumnRecorder()
    try EncodedRow(id: 1, title: "Hi", score: 0.5, note: nil).encode(to: &encoder)
    #expect(encoder.names == [["id"], ["title"], ["score"], ["note"]])
    #expect(encoder.leaves == ["1", "Hi", "0.5", "NULL"])
  }

  @Test func flattensColumnGroups() throws {
    var encoder = ColumnRecorder()
    try EncodedPhoto(
      id: 1,
      dimensions: EncodedDimensions(width: 800, height: 600),
      extra: nil
    ).encode(to: &encoder)
    #expect(
      encoder.names == [
        ["id"],
        ["width", "height"],
        ["width"],
        ["height"],
        ["width", "height"],
      ]
    )
    #expect(encoder.leaves == ["1", "800", "600", "NULL", "NULL"])
  }

  @Test func presentOptionalGroup() throws {
    var encoder = ColumnRecorder()
    try EncodedPhoto(
      id: 2,
      dimensions: EncodedDimensions(width: 1, height: 2),
      extra: EncodedDimensions(width: 3, height: 4)
    ).encode(to: &encoder)
    #expect(encoder.leaves == ["2", "1", "2", "3", "4"])
  }
}
