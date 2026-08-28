public import StructuredQueriesCore

extension QueryFragment {
  /// A SQL string and associated materialized bindings, prepared from a query fragment.
  ///
  /// This type is the identity of a compiled query: two fragments that prepare to equal values
  /// describe the same statement with the same bound values, regardless of how their segments
  /// were assembled.
  public struct Prepared: Hashable, Sendable {
    /// A SQL string with bindings replaced by placeholders.
    public let sql: String

    /// The materialized bindings associated with the statement's placeholders.
    public let bindings: [SQLiteValue]

    public init(sql: String, bindings: [SQLiteValue]) {
      self.sql = sql
      self.bindings = bindings
    }
  }

  /// Returns a prepared SQL string and associated bindings for this query.
  ///
  /// - Parameter template: Prepare a template string for a binding at a given 1-based offset.
  /// - Returns: A SQL string and array of associated bindings.
  public func prepare(
    _ template: (_ offset: Int) -> String
  ) throws(QueryEncodingError) -> Prepared {
    var sql = ""
    var bindings: [SQLiteValue] = []
    var offset = 1
    for segment in segments {
      switch segment {
      case .sql(let fragment):
        sql.append(fragment)
      case .binding(let value):
        defer { offset += 1 }
        sql.append(template(offset))
        bindings.append(try value?._materializedValue ?? .null)
      case .invalid(let error):
        throw .other(error)
      case .identifier(let identifier):
        sql.append(identifier.name.quoted())
      }
    }
    return Prepared(sql: sql, bindings: bindings)
  }
}
