@_exported import StructuredQueriesSQLite

#if canImport(Darwin)
  @_exported import SQLite3
#else
  @_exported import _StructuredQueriesSQLite3
#endif
