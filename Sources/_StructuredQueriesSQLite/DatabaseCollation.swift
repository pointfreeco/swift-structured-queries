import StructuredQueriesCore
public import StructuredQueriesSQLiteCore

#if canImport(Darwin)
  import SQLite3
#else
  import _StructuredQueriesSQLite3
#endif

extension DatabaseCollation {
  /// Installs the collating sequence in a database connection.
  ///
  /// - Parameter db: A database connection.
  public func install(_ db: OpaquePointer) {
    let body = Unmanaged.passRetained(DatabaseCollationDefinition(self)).toOpaque()
    sqlite3_create_collation_v2(
      db,
      name,
      SQLITE_UTF8,
      body,
      { body, lhsCount, lhs, rhsCount, rhs in
        let lhs = UnsafeRawBufferPointer(start: lhs, count: Int(lhsCount))
        let rhs = UnsafeRawBufferPointer(start: rhs, count: Int(rhsCount))
        switch Unmanaged<DatabaseCollationDefinition>
          .fromOpaque(body!)
          .takeUnretainedValue()
          .collation
          .compare(String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
        {
        case .ascending: return -1
        case .same: return 0
        case .descending: return 1
        }
      },
      { body in
        guard let body else { return }
        Unmanaged<DatabaseCollationDefinition>.fromOpaque(body).release()
      }
    )
  }
}

private final class DatabaseCollationDefinition {
  let collation: any DatabaseCollation
  init(_ collation: some DatabaseCollation) {
    self.collation = collation
  }
}
