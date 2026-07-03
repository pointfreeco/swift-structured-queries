import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct LazyInitializableTests {
    @Test func explicitLazyInitializable() {
      assertMacro {
        """
        @Table
        struct Place {
          let id: Int
          @Column(lazyInitializable: true)
          var latitude: Double
          @Column(lazyInitializable: true)
          var longitude: Double
        }
        """
      } expansion: {
        #"""
        struct Place {
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int
          var latitude: Double
          var longitude: Double

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Place
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let latitude = StructuredQueriesCore.TableColumn<QueryValue, Double>("latitude", keyPath: \QueryValue.latitude)
            public let longitude = StructuredQueriesCore.TableColumn<QueryValue, Double>("longitude", keyPath: \QueryValue.longitude)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.longitude._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.longitude._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.latitude), \(self.longitude)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Place
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              latitude: some StructuredQueriesCore.QueryExpression<Double>,
              longitude: some StructuredQueriesCore.QueryExpression<Double>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: latitude._allColumns)
              allColumns.append(contentsOf: longitude._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Place
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            var latitude: Double?
            var longitude: Double?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let latitude = StructuredQueriesCore.TableColumn<QueryValue, Double?>("latitude", keyPath: \QueryValue.latitude, default: nil)
              public let longitude = StructuredQueriesCore.TableColumn<QueryValue, Double?>("longitude", keyPath: \QueryValue.longitude, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.longitude._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.longitude._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.latitude), \(self.longitude)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                latitude: some StructuredQueriesCore.QueryExpression<Double?> = Double?(queryOutput: nil),
                longitude: some StructuredQueriesCore.QueryExpression<Double?> = Double?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: latitude._allColumns)
                allColumns.append(contentsOf: longitude._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += Double?._columnWidth
              columnWidth += Double?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += Double._columnWidth
            columnWidth += Double._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "places"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode() ?? nil
            self.latitude = try decoder.decode() ?? nil
            self.longitude = try decoder.decode() ?? nil
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.latitude = other.latitude
            self.longitude = other.longitude
          }
        }

        nonisolated extension Place: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(\QueryValue.id)
            let latitude = try decoder.decode(\QueryValue.latitude)
            let longitude = try decoder.decode(\QueryValue.longitude)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let latitude else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let longitude else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.latitude = latitude
            self.longitude = longitude
          }
        }
        """#
      }
    }

    @Test func explicitLazyInitializableFalse() {
      assertMacro {
        """
        @Table
        struct Place {
          let id: Int
          @Column(lazyInitializable: false)
          var latitude: Double
        }
        """
      } expansion: {
        #"""
        struct Place {
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int
          var latitude: Double

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Place
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let latitude = StructuredQueriesCore.TableColumn<QueryValue, Double>("latitude", keyPath: \QueryValue.latitude)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.latitude)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Place
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              latitude: some StructuredQueriesCore.QueryExpression<Double>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: latitude._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Place
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            var latitude: Double

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let latitude = StructuredQueriesCore.TableColumn<QueryValue, Double>("latitude", keyPath: \QueryValue.latitude)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.latitude)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                latitude: some StructuredQueriesCore.QueryExpression<Double>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: latitude._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += Double._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += Double._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "places"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode() ?? nil
            let latitude = try decoder.decode(\QueryValue.latitude)
            guard let latitude else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.latitude = latitude
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.latitude = other.latitude
          }
        }

        nonisolated extension Place: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(\QueryValue.id)
            let latitude = try decoder.decode(\QueryValue.latitude)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let latitude else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.latitude = latitude
          }
        }
        """#
      }
    }

    @Test func lazyInitializableWithRepresentation() {
      assertMacro {
        """
        @Table
        struct Event {
          let id: Int
          @Column(as: Date.ISO8601Representation.self, lazyInitializable: true)
          var startsAt: Date
        }
        """
      } expansion: {
        #"""
        struct Event {
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int
          var startsAt: Date

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Event
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let startsAt = StructuredQueriesCore.TableColumn<QueryValue, Date.ISO8601Representation>("startsAt", keyPath: \QueryValue.startsAt)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.startsAt._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.startsAt._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.startsAt)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Event
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              startsAt: some StructuredQueriesCore.QueryExpression<Date.ISO8601Representation>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: startsAt._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Event
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            var startsAt: Date?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let startsAt = StructuredQueriesCore.TableColumn<QueryValue, Date.ISO8601Representation?>("startsAt", keyPath: \QueryValue.startsAt, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.startsAt._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.startsAt._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.startsAt)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                startsAt: some StructuredQueriesCore.QueryExpression<Date.ISO8601Representation?> = Date.ISO8601Representation?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: startsAt._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += Date.ISO8601Representation?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += Date.ISO8601Representation._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "events"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode() ?? nil
            self.startsAt = try decoder.decode(Date.ISO8601Representation.self) ?? nil
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.startsAt = other.startsAt
          }
        }

        nonisolated extension Event: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(\QueryValue.id)
            let startsAt = try decoder.decode(Date.ISO8601Representation.self)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let startsAt else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.startsAt = startsAt
          }
        }
        """#
      }
    }

    @Test func explicitLazyInitializableColumnGroup() {
      assertMacro {
        """
        @Table
        struct Place {
          let id: Int
          @Columns(lazyInitializable: true)
          var coordinate: Coordinate
        }
        """
      } expansion: {
        #"""
        struct Place {
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int
          var coordinate: Coordinate

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Place
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let coordinate = StructuredQueriesCore.ColumnGroup<QueryValue, Coordinate>(keyPath: \QueryValue.coordinate)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.coordinate._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.coordinate._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.coordinate)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Place
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              coordinate: some StructuredQueriesCore.QueryExpression<Coordinate>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: coordinate._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Place
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            var coordinate: Coordinate?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let coordinate = StructuredQueriesCore.ColumnGroup<QueryValue, Coordinate?>(keyPath: \QueryValue.coordinate)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.coordinate._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.coordinate._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.coordinate)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                coordinate: some StructuredQueriesCore.QueryExpression<Coordinate?> = Coordinate?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: coordinate._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += Coordinate?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += Coordinate._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "places"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode() ?? nil
            self.coordinate = try decoder.decode() ?? nil
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.coordinate = other.coordinate
          }
        }

        nonisolated extension Place: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(\QueryValue.id)
            let coordinate = try decoder.decode(\QueryValue.coordinate)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let coordinate else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.coordinate = coordinate
          }
        }
        """#
      }
    }

    @Test func doesNotDoubleOptionalizeOptionalRepresentationColumns() {
      assertMacro {
        """
        @Table
        struct Record {
          let id: Int
          @Column(as: CKRecord?.SystemFieldsRepresentation.self)
          var systemFields: CKRecord?
        }
        """
      } expansion: {
        #"""
        struct Record {
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int
          var systemFields: CKRecord?

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Record
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let systemFields = StructuredQueriesCore.TableColumn<QueryValue, CKRecord?.SystemFieldsRepresentation>("systemFields", keyPath: \QueryValue.systemFields)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.systemFields._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.systemFields._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.systemFields)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Record
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              systemFields: some StructuredQueriesCore.QueryExpression<CKRecord?.SystemFieldsRepresentation>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: systemFields._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Record
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            var systemFields: CKRecord?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let systemFields = StructuredQueriesCore.TableColumn<QueryValue, CKRecord?.SystemFieldsRepresentation>("systemFields", keyPath: \QueryValue.systemFields)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.systemFields._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.systemFields._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.systemFields)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                systemFields: some StructuredQueriesCore.QueryExpression<CKRecord?.SystemFieldsRepresentation>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: systemFields._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += CKRecord?.SystemFieldsRepresentation._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += CKRecord?.SystemFieldsRepresentation._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "records"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode() ?? nil
            let systemFields = try decoder.decode(CKRecord?.SystemFieldsRepresentation.self)
            guard let systemFields else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.systemFields = systemFields
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.systemFields = other.systemFields
          }
        }

        nonisolated extension Record: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(\QueryValue.id)
            let systemFields = try decoder.decode(CKRecord?.SystemFieldsRepresentation.self)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let systemFields else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.systemFields = systemFields
          }
        }
        """#
      }
    }

    @Test func lazyInitializableOnOptionalColumnWarns() {
      assertMacro {
        """
        @Table
        struct Record {
          let id: Int
          @Column(lazyInitializable: true)
          var a: String?
          @Column(lazyInitializable: false)
          var b: Int?
          @Column(lazyInitializable: true)
          var c: Double
        }
        """
      } diagnostics: {
        """
        @Table
        struct Record {
          let id: Int
          @Column(lazyInitializable: true)
                  ┬──────────────────────
                  ╰─ ⚠️ Argument 'lazyInitializable' has no effect on optional column 'a'
                     ✏️ Remove 'lazyInitializable'
          var a: String?
          @Column(lazyInitializable: false)
                  ┬───────────────────────
                  ╰─ ⚠️ Argument 'lazyInitializable' has no effect on optional column 'b'
                     ✏️ Remove 'lazyInitializable'
          var b: Int?
          @Column(lazyInitializable: true)
          var c: Double
        }
        """
      } fixes: {
        """
        @Table
        struct Record {
          let id: Int
          @Column
          var a: String?
          @Column
          var b: Int?
          @Column(lazyInitializable: true)
          var c: Double
        }
        """
      } expansion: {
        #"""
        struct Record {
          @StructuredQueries._ColumnCheck(Int.self)
          let id: Int
          var a: String?
          var b: Int?
          var c: Double

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
            public typealias QueryValue = Record
            public typealias PrimaryKey = Int
            public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
            public let a = StructuredQueriesCore.TableColumn<QueryValue, String?>("a", keyPath: \QueryValue.a, default: nil)
            public let b = StructuredQueriesCore.TableColumn<QueryValue, Int?>("b", keyPath: \QueryValue.b, default: nil)
            public let c = StructuredQueriesCore.TableColumn<QueryValue, Double>("c", keyPath: \QueryValue.c)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.a._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.b._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.c._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.a._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.b._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.c._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.id), \(self.a), \(self.b), \(self.c)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Record
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              id: some StructuredQueriesCore.QueryExpression<Int>,
              a: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil),
              b: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
              c: some StructuredQueriesCore.QueryExpression<Double>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: id._allColumns)
              allColumns.append(contentsOf: a._allColumns)
              allColumns.append(contentsOf: b._allColumns)
              allColumns.append(contentsOf: c._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Record
            @StructuredQueries._ColumnCheck(Int?.self)
            var id: Int?
            var a: String?
            var b: Int?
            var c: Double?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
              public let a = StructuredQueriesCore.TableColumn<QueryValue, String?>("a", keyPath: \QueryValue.a, default: nil)
              public let b = StructuredQueriesCore.TableColumn<QueryValue, Int?>("b", keyPath: \QueryValue.b, default: nil)
              public let c = StructuredQueriesCore.TableColumn<QueryValue, Double?>("c", keyPath: \QueryValue.c, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.a._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.b._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.c._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.a._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.b._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.c._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.a), \(self.b), \(self.c)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                a: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil),
                b: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                c: some StructuredQueriesCore.QueryExpression<Double?> = Double?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: a._allColumns)
                allColumns.append(contentsOf: b._allColumns)
                allColumns.append(contentsOf: c._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int?._columnWidth
              columnWidth += String?._columnWidth
              columnWidth += Int?._columnWidth
              columnWidth += Double?._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Int._columnWidth
            columnWidth += String?._columnWidth
            columnWidth += Int?._columnWidth
            columnWidth += Double._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "records"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.id = try decoder.decode() ?? nil
            self.a = try decoder.decode() ?? nil
            self.b = try decoder.decode() ?? nil
            self.c = try decoder.decode() ?? nil
          }
          nonisolated init(_ other: SourceTable) {
            self.id = other.id
            self.a = other.a
            self.b = other.b
            self.c = other.c
          }
        }

        nonisolated extension Record: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let id = try decoder.decode(\QueryValue.id)
            self.a = try decoder.decode() ?? nil
            self.b = try decoder.decode() ?? nil
            let c = try decoder.decode(\QueryValue.c)
            guard let id else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let c else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.id = id
            self.c = c
          }
        }
        """#
      }
    }

    @Test func nonPrimaryKeyedTableWithLazyColumnGeneratesDraft() {
      assertMacro {
        """
        @Table
        struct Location {
          @Column(lazyInitializable: true)
          var latitude: Double
          @Column(lazyInitializable: true)
          var longitude: Double
          var name: String
        }
        """
      } expansion: {
        #"""
        struct Location {
          var latitude: Double
          var longitude: Double
          @StructuredQueries._ColumnCheck(String.self)
          var name: String

          public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
            public typealias QueryValue = Location
            public let latitude = StructuredQueriesCore.TableColumn<QueryValue, Double>("latitude", keyPath: \QueryValue.latitude)
            public let longitude = StructuredQueriesCore.TableColumn<QueryValue, Double>("longitude", keyPath: \QueryValue.longitude)
            public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
              var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
              allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.longitude._allColumns)
              allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
              return allColumns
            }
            #if compiler(>=6.4)
            @_optimize(none)
            #endif
            public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
              var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
              writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.longitude._writableColumns)
              writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
              return writableColumns
            }
            public var queryFragment: QueryFragment {
              "\(self.latitude), \(self.longitude), \(self.name)"
            }
          }

          public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
            public typealias QueryValue = Location
            public let allColumns: [any StructuredQueriesCore.QueryExpression]
            public init(
              latitude: some StructuredQueriesCore.QueryExpression<Double>,
              longitude: some StructuredQueriesCore.QueryExpression<Double>,
              name: some StructuredQueriesCore.QueryExpression<String>
            ) {
              var allColumns: [any StructuredQueriesCore.QueryExpression] = []
              allColumns.append(contentsOf: latitude._allColumns)
              allColumns.append(contentsOf: longitude._allColumns)
              allColumns.append(contentsOf: name._allColumns)
              self.allColumns = allColumns
            }
          }
          struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
            public typealias SourceTable = Location
            var latitude: Double?
            var longitude: Double?
            @StructuredQueries._ColumnCheck(String.self)
            var name: String

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
              public typealias QueryValue = Draft
              public let latitude = StructuredQueriesCore.TableColumn<QueryValue, Double?>("latitude", keyPath: \QueryValue.latitude, default: nil)
              public let longitude = StructuredQueriesCore.TableColumn<QueryValue, Double?>("longitude", keyPath: \QueryValue.longitude, default: nil)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.longitude._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.longitude._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.latitude), \(self.longitude), \(self.name)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Draft
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                latitude: some StructuredQueriesCore.QueryExpression<Double?> = Double?(queryOutput: nil),
                longitude: some StructuredQueriesCore.QueryExpression<Double?> = Double?(queryOutput: nil),
                name: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: latitude._allColumns)
                allColumns.append(contentsOf: longitude._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                self.allColumns = allColumns
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Double?._columnWidth
              columnWidth += Double?._columnWidth
              columnWidth += String._columnWidth
              return columnWidth
            }
          }

          public typealias QueryValue = Self

          public typealias From = Swift.Never

          public nonisolated static var columns: TableColumns {
            TableColumns()
          }

          public nonisolated static var _columnWidth: Swift.Int {
            var columnWidth = 0
            columnWidth += Double._columnWidth
            columnWidth += Double._columnWidth
            columnWidth += String._columnWidth
            return columnWidth
          }

          public nonisolated static var tableName: Swift.String {
            "locations"
          }
        }

        nonisolated extension Draft {
          nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            self.latitude = try decoder.decode() ?? nil
            self.longitude = try decoder.decode() ?? nil
            let name = try decoder.decode(\QueryValue.name)
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.name = name
          }
          nonisolated init(_ other: SourceTable) {
            self.latitude = other.latitude
            self.longitude = other.longitude
            self.name = other.name
          }
        }

        nonisolated extension Location: StructuredQueriesCore.Table, StructuredQueriesCore.PartialSelectStatement {
          public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let latitude = try decoder.decode(\QueryValue.latitude)
            let longitude = try decoder.decode(\QueryValue.longitude)
            let name = try decoder.decode(\QueryValue.name)
            guard let latitude else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let longitude else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            guard let name else {
              throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
            }
            self.latitude = latitude
            self.longitude = longitude
            self.name = name
          }
        }
        """#
      }
    }

    #if LazyInitializableByDefault
      @Test func lazyInitializableHint() {
        assertMacro([
          "Table": TableMacro.self,
          "_Draft": TableMacro.self,
        ]) {
          """
          @Table
          struct Place {
            let id: Int
            var latitude: Double
            var name = ""
            var note: String?
          }
          """
        } expansion: {
          #"""
          struct Place {
            @Column("id", primaryKey: true) @StructuredQueries._ColumnCheck(Int.self)
            let id: Int
            @Column("latitude", lazyInitializable: true) @StructuredQueries._ColumnCheck(Double.self)
            var latitude: Double
            @Column("name") @StructuredQueries._ColumnCheck(Swift.String.self)
            var name = ""
            @Column("note") @StructuredQueries._ColumnCheck(String?.self)
            var note: String?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Place
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let latitude = StructuredQueriesCore._TableColumn<QueryValue, Double>.for("latitude", keyPath: \QueryValue.latitude)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("name", keyPath: \QueryValue.name, default: "")
              public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.latitude), \(self.name), \(self.note)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Place
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                latitude: some StructuredQueriesCore.QueryExpression<Double>,
                name: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
                note: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: latitude._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                allColumns.append(contentsOf: note._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Place
              @Column("id", primaryKey: true) @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @Column("latitude") @StructuredQueries._ColumnCheck(Double?.self)
              var latitude: Double?
              @Column("name") @StructuredQueries._ColumnCheck(Swift.String.self)
              var name = ""
              @Column("note") @StructuredQueries._ColumnCheck(String?.self)
              var note: String?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let latitude = StructuredQueriesCore._TableColumn<QueryValue, Double?>.for("latitude", keyPath: \QueryValue.latitude, default: nil)
                public let name = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("name", keyPath: \QueryValue.name, default: "")
                public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.latitude), \(self.name), \(self.note)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  latitude: some StructuredQueriesCore.QueryExpression<Double?> = Double?(queryOutput: nil),
                  name: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
                  note: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: latitude._allColumns)
                  allColumns.append(contentsOf: name._allColumns)
                  allColumns.append(contentsOf: note._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += Double?._columnWidth
                columnWidth += Swift.String._columnWidth
                columnWidth += String?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.latitude = try decoder.decode() ?? nil
              self.name = try decoder.decode() ?? ""
              self.note = try decoder.decode() ?? nil
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.latitude = other.latitude
              self.name = other.name
              self.note = other.note
            }
          }

          nonisolated extension Place: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += Double._columnWidth
              columnWidth += Swift.String._columnWidth
              columnWidth += String?._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "places"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let latitude = try decoder.decode(\QueryValue.latitude)
              self.name = try decoder.decode() ?? ""
              self.note = try decoder.decode() ?? nil
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let latitude else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.latitude = latitude
            }
          }
          """#
        }
      }

      @Test func doesNotDoubleOptionalizeOptionalColumns() {
        assertMacro {
          """
          @Table
          struct Item {
            let id: Int
            var quantity: Int
            var note: String?
          }
          """
        } expansion: {
          #"""
          struct Item {
            @StructuredQueries._ColumnCheck(Int.self)
            let id: Int
            @StructuredQueries._ColumnCheck(Int.self)
            var quantity: Int
            @StructuredQueries._ColumnCheck(String?.self)
            var note: String?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Item
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let quantity = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("quantity", keyPath: \QueryValue.quantity)
              public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.quantity._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.quantity._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.quantity), \(self.note)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Item
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                quantity: some StructuredQueriesCore.QueryExpression<Int>,
                note: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: quantity._allColumns)
                allColumns.append(contentsOf: note._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Item
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @StructuredQueries._ColumnCheck(Int?.self)
              var quantity: Int?
              @StructuredQueries._ColumnCheck(String?.self)
              var note: String?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let quantity = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("quantity", keyPath: \QueryValue.quantity, default: nil)
                public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.quantity._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.quantity._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.quantity), \(self.note)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  quantity: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  note: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: quantity._allColumns)
                  allColumns.append(contentsOf: note._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += Int?._columnWidth
                columnWidth += String?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.quantity = try decoder.decode() ?? nil
              self.note = try decoder.decode() ?? nil
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.quantity = other.quantity
              self.note = other.note
            }
          }

          nonisolated extension Item: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += Int._columnWidth
              columnWidth += String?._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "items"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let quantity = try decoder.decode(\QueryValue.quantity)
              self.note = try decoder.decode() ?? nil
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let quantity else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.quantity = quantity
            }
          }
          """#
        }
      }

      @Test func comment() {
        assertMacro {
          """
          @Table
          struct User {
            /// The user's identifier.
            let id: /* TODO: UUID */Int // Primary key
            /// The user's email.
            var email: String? = ""  // TODO: Should this be non-optional?
            /// The user's age.
            var age: Int
          }
          """
        } expansion: {
          #"""
          struct User {
            @StructuredQueries._ColumnCheck(Int.self)
            /// The user's identifier.
            let id: /* TODO: UUID */Int // Primary key
            @StructuredQueries._ColumnCheck(String?.self)
            /// The user's email.
            var email: String? = ""  // TODO: Should this be non-optional?
            @StructuredQueries._ColumnCheck(Int.self)
            /// The user's age.
            var age: Int

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = User
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let email = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("email", keyPath: \QueryValue.email, default: "")
              public let age = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("age", keyPath: \QueryValue.age)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.age._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.age._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.email), \(self.age)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = User
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                email: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: ""),
                age: some StructuredQueriesCore.QueryExpression<Int>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: email._allColumns)
                allColumns.append(contentsOf: age._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = User
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: /* TODO: UUID */ Int? // Primary key
              @StructuredQueries._ColumnCheck(String?.self)
              var email: String? = ""
              @StructuredQueries._ColumnCheck(Int?.self)
              var age: Int?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let email = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("email", keyPath: \QueryValue.email, default: "")
                public let age = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("age", keyPath: \QueryValue.age, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.age._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.age._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.email), \(self.age)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  email: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: ""),
                  age: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: email._allColumns)
                  allColumns.append(contentsOf: age._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += String?._columnWidth
                columnWidth += Int?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.email = try decoder.decode() ?? ""
              self.age = try decoder.decode() ?? nil
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.email = other.email
              self.age = other.age
            }
          }

          nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += String?._columnWidth
              columnWidth += Int._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "users"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              self.email = try decoder.decode() ?? ""  // TODO: Should this be non-optional?
              let age = try decoder.decode(\QueryValue.age)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let age else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.age = age
            }
          }
          """#
        }
      }

      @Test func columnGeneratedPrimaryKeyedTable() throws {
        assertMacro {
          """
          @Table struct User {
            let id: Int
            var name: String
            @Column(generated: .stored)
            let generated: Int
          }
          """
        } expansion: {
          #"""
          struct User {
            @StructuredQueries._ColumnCheck(Int.self)
            let id: Int
            @StructuredQueries._ColumnCheck(String.self)
            var name: String
            let generated: Int

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = User
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              public let generated = StructuredQueriesCore.GeneratedColumn<QueryValue, Int>("generated", keyPath: \QueryValue.generated)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.generated._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name), \(self.generated)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = User
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                name: some StructuredQueriesCore.QueryExpression<String>,
                generated: some StructuredQueriesCore.QueryExpression<Int>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                allColumns.append(contentsOf: generated._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = User
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @StructuredQueries._ColumnCheck(String?.self)
              var name: String?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let name = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("name", keyPath: \QueryValue.name, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.name)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  name: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: name._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += String?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.name = try decoder.decode() ?? nil
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.name = other.name
            }
          }

          nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += String._columnWidth
              columnWidth += Int._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "users"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let name = try decoder.decode(\QueryValue.name)
              let generated = try decoder.decode(\QueryValue.generated)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let generated else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.name = name
              self.generated = generated
            }
          }
          """#
        }
      }

      @Test func ephemeralFieldPrimaryKeyedTable() {
        assertMacro {
          """
          @Table struct SyncUp {
            let id: Int
            var name: String
            @Ephemeral
            var computed: Int
          }
          """
        } expansion: {
          #"""
          struct SyncUp {
            @StructuredQueries._ColumnCheck(Int.self)
            let id: Int
            @StructuredQueries._ColumnCheck(String.self)
            var name: String
            var computed: Int

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = SyncUp
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = SyncUp
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                name: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = SyncUp
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @StructuredQueries._ColumnCheck(String?.self)
              var name: String?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let name = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("name", keyPath: \QueryValue.name, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.name)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  name: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: name._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += String?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.name = try decoder.decode() ?? nil
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.name = other.name
            }
          }

          nonisolated extension SyncUp: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += String._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "syncUps"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let name = try decoder.decode(\QueryValue.name)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.name = name
            }
          }
          """#
        }
      }

      @Test func willSet() {
        assertMacro {
          """
          @Table
          struct Foo {
            var id: Int {
              willSet { print(newValue) }
            }
            var name: String {
              willSet { print(newValue) }
            }
          }
          """
        } expansion: {
          #"""
          struct Foo {
            @StructuredQueries._ColumnCheck(Int.self)
            var id: Int {
              willSet { print(newValue) }
            }
            @StructuredQueries._ColumnCheck(String.self)
            var name: String {
              willSet { print(newValue) }
            }

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Foo
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Foo
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                name: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Foo
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @StructuredQueries._ColumnCheck(String?.self)
              var name: String?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let name = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("name", keyPath: \QueryValue.name, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.name)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  name: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: name._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += String?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.name = try decoder.decode() ?? nil
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.name = other.name
            }
          }

          nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += String._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "foos"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let name = try decoder.decode(\QueryValue.name)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.name = name
            }
          }
          """#
        }
      }

      @Test func customPrimaryKey() {
        assertMacro {
          """
          @Table
          private struct ReminderWithList {
            @Column(primaryKey: true)
            let reminderID: Reminder.ID
            let reminderTitle: String
            let remindersListTitle: String
          }
          """
        } expansion: {
          #"""
          private struct ReminderWithList {
            let reminderID: Reminder.ID
            @StructuredQueries._ColumnCheck(String.self)
            let reminderTitle: String
            @StructuredQueries._ColumnCheck(String.self)
            let remindersListTitle: String

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = ReminderWithList
              public typealias PrimaryKey = Reminder.ID
              public let reminderID = StructuredQueriesCore.TableColumn<QueryValue, Reminder.ID>("reminderID", keyPath: \QueryValue.reminderID)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore.TableColumn<QueryValue, Reminder.ID>("reminderID", keyPath: \QueryValue.reminderID)
              public let reminderTitle = StructuredQueriesCore._TableColumn<QueryValue, String>.for("reminderTitle", keyPath: \QueryValue.reminderTitle)
              public let remindersListTitle = StructuredQueriesCore._TableColumn<QueryValue, String>.for("remindersListTitle", keyPath: \QueryValue.remindersListTitle)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.reminderID._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.reminderTitle._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.remindersListTitle._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.reminderID._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.reminderTitle._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.remindersListTitle._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.reminderID), \(self.reminderTitle), \(self.remindersListTitle)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = ReminderWithList
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                reminderID: some StructuredQueriesCore.QueryExpression<Reminder.ID>,
                reminderTitle: some StructuredQueriesCore.QueryExpression<String>,
                remindersListTitle: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: reminderID._allColumns)
                allColumns.append(contentsOf: reminderTitle._allColumns)
                allColumns.append(contentsOf: remindersListTitle._allColumns)
                self.allColumns = allColumns
              }
            }
            fileprivate struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = ReminderWithList
              var reminderID: Reminder.ID?
              @StructuredQueries._ColumnCheck(String?.self)
              var reminderTitle: String?
              @StructuredQueries._ColumnCheck(String?.self)
              var remindersListTitle: String?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let reminderID = StructuredQueriesCore.TableColumn<QueryValue, Reminder.ID?>("reminderID", keyPath: \QueryValue.reminderID, default: nil)
                public let reminderTitle = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("reminderTitle", keyPath: \QueryValue.reminderTitle, default: nil)
                public let remindersListTitle = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("remindersListTitle", keyPath: \QueryValue.remindersListTitle, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.reminderID._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.reminderTitle._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.remindersListTitle._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.reminderID._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.reminderTitle._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.remindersListTitle._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.reminderID), \(self.reminderTitle), \(self.remindersListTitle)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  reminderID: some StructuredQueriesCore.QueryExpression<Reminder.ID?> = Reminder.ID?(queryOutput: nil),
                  reminderTitle: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil),
                  remindersListTitle: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: reminderID._allColumns)
                  allColumns.append(contentsOf: reminderTitle._allColumns)
                  allColumns.append(contentsOf: remindersListTitle._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Reminder.ID?._columnWidth
                columnWidth += String?._columnWidth
                columnWidth += String?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            fileprivate nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.reminderID = try decoder.decode() ?? nil
              self.reminderTitle = try decoder.decode() ?? nil
              self.remindersListTitle = try decoder.decode() ?? nil
            }
            fileprivate nonisolated init(_ other: SourceTable) {
              self.reminderID = other.reminderID
              self.reminderTitle = other.reminderTitle
              self.remindersListTitle = other.remindersListTitle
            }
          }

          nonisolated extension ReminderWithList: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += Reminder.ID._columnWidth
              columnWidth += String._columnWidth
              columnWidth += String._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "reminderWithLists"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let reminderID = try decoder.decode(\QueryValue.reminderID)
              let reminderTitle = try decoder.decode(\QueryValue.reminderTitle)
              let remindersListTitle = try decoder.decode(\QueryValue.remindersListTitle)
              guard let reminderID else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let reminderTitle else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let remindersListTitle else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.reminderID = reminderID
              self.reminderTitle = reminderTitle
              self.remindersListTitle = remindersListTitle
            }
          }
          """#
        }
      }

      @Test func composite() {
        assertMacro {
          """
          @Table
          private struct Metadata: Identifiable {
            let id: MetadataID
            var userModificationDate: Date
          }
          """
        } expansion: {
          #"""
          private struct Metadata: Identifiable {
            @StructuredQueries._ColumnCheck(MetadataID.self)
            let id: MetadataID
            @StructuredQueries._ColumnCheck(Date.self)
            var userModificationDate: Date

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Metadata
              public typealias PrimaryKey = MetadataID
              public let id = StructuredQueriesCore._TableColumn<QueryValue, MetadataID>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, MetadataID>.for("id", keyPath: \QueryValue.id)
              public let userModificationDate = StructuredQueriesCore._TableColumn<QueryValue, Date>.for("userModificationDate", keyPath: \QueryValue.userModificationDate)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.userModificationDate._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.userModificationDate._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.userModificationDate)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Metadata
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<MetadataID>,
                userModificationDate: some StructuredQueriesCore.QueryExpression<Date>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: userModificationDate._allColumns)
                self.allColumns = allColumns
              }
            }
            fileprivate struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Metadata
              @StructuredQueries._ColumnCheck(MetadataID?.self)
              var id: MetadataID?
              @StructuredQueries._ColumnCheck(Date?.self)
              var userModificationDate: Date?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, MetadataID?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let userModificationDate = StructuredQueriesCore._TableColumn<QueryValue, Date?>.for("userModificationDate", keyPath: \QueryValue.userModificationDate, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.userModificationDate._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.userModificationDate._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.userModificationDate)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<MetadataID?> = MetadataID?(queryOutput: nil),
                  userModificationDate: some StructuredQueriesCore.QueryExpression<Date?> = Date?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: userModificationDate._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += MetadataID?._columnWidth
                columnWidth += Date?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            fileprivate nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.userModificationDate = try decoder.decode() ?? nil
            }
            fileprivate nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.userModificationDate = other.userModificationDate
            }
          }

          nonisolated extension Metadata: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += MetadataID._columnWidth
              columnWidth += Date._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "metadatas"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let userModificationDate = try decoder.decode(\QueryValue.userModificationDate)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let userModificationDate else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.userModificationDate = userModificationDate
            }
          }
          """#
        }
      }
      @Test func nested() {
        assertMacro {
          """
          @Table
          private struct Row {
            let id: UUID
            @Columns
            var timestamps: Timestamps
          }
          """
        } expansion: {
          #"""
          private struct Row {
            @StructuredQueries._ColumnCheck(UUID.self)
            let id: UUID
            var timestamps: Timestamps

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Row
              public typealias PrimaryKey = UUID
              public let id = StructuredQueriesCore._TableColumn<QueryValue, UUID>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, UUID>.for("id", keyPath: \QueryValue.id)
              public let timestamps = StructuredQueriesCore.ColumnGroup<QueryValue, Timestamps>(keyPath: \QueryValue.timestamps)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.timestamps._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.timestamps._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.timestamps)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Row
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<UUID>,
                timestamps: some StructuredQueriesCore.QueryExpression<Timestamps>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: timestamps._allColumns)
                self.allColumns = allColumns
              }
            }
            fileprivate struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Row
              @StructuredQueries._ColumnCheck(UUID?.self)
              var id: UUID?
              var timestamps: Timestamps?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, UUID?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let timestamps = StructuredQueriesCore.ColumnGroup<QueryValue, Timestamps?>(keyPath: \QueryValue.timestamps)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.timestamps._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.timestamps._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.timestamps)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<UUID?> = UUID?(queryOutput: nil),
                  timestamps: some StructuredQueriesCore.QueryExpression<Timestamps?> = Timestamps?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: timestamps._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += UUID?._columnWidth
                columnWidth += Timestamps?._columnWidth
                return columnWidth
              }
            }
          }

          nonisolated extension Draft {
            fileprivate nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.timestamps = try decoder.decode() ?? nil
            }
            fileprivate nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.timestamps = other.timestamps
            }
          }

          nonisolated extension Row: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public typealias QueryValue = Self
            public typealias From = Swift.Never
            public nonisolated static var columns: TableColumns {
              TableColumns()
            }
            public nonisolated static var _columnWidth: Int {
              var columnWidth = 0
              columnWidth += UUID._columnWidth
              columnWidth += Timestamps._columnWidth
              return columnWidth
            }
            public nonisolated static var tableName: String {
              "rows"
            }
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let timestamps = try decoder.decode(\QueryValue.timestamps)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let timestamps else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.timestamps = timestamps
            }
          }
          """#
        }
      }
    #else
      @Test func lazyInitializableHint() {
        assertMacro([
          "Table": TableMacro.self,
          "_Draft": TableMacro.self,
        ]) {
          """
          @Table
          struct Place {
            let id: Int
            var latitude: Double
            var name = ""
            var note: String?
          }
          """
        } expansion: {
          #"""
          struct Place {
            @Column("id", primaryKey: true) @StructuredQueries._ColumnCheck(Int.self)
            let id: Int
            @Column("latitude") @StructuredQueries._ColumnCheck(Double.self)
            var latitude: Double
            @Column("name") @StructuredQueries._ColumnCheck(Swift.String.self)
            var name = ""
            @Column("note") @StructuredQueries._ColumnCheck(String?.self)
            var note: String?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Place
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let latitude = StructuredQueriesCore._TableColumn<QueryValue, Double>.for("latitude", keyPath: \QueryValue.latitude)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("name", keyPath: \QueryValue.name, default: "")
              public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.latitude), \(self.name), \(self.note)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Place
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                latitude: some StructuredQueriesCore.QueryExpression<Double>,
                name: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
                note: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: latitude._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                allColumns.append(contentsOf: note._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Place
              @Column("id", primaryKey: true) @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @Column("latitude") @StructuredQueries._ColumnCheck(Double.self)
              var latitude: Double
              @Column("name") @StructuredQueries._ColumnCheck(Swift.String.self)
              var name = ""
              @Column("note") @StructuredQueries._ColumnCheck(String?.self)
              var note: String?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let latitude = StructuredQueriesCore._TableColumn<QueryValue, Double>.for("latitude", keyPath: \QueryValue.latitude)
                public let name = StructuredQueriesCore._TableColumn<QueryValue, Swift.String>.for("name", keyPath: \QueryValue.name, default: "")
                public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.latitude._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.latitude._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.latitude), \(self.name), \(self.note)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  latitude: some StructuredQueriesCore.QueryExpression<Double>,
                  name: some StructuredQueriesCore.QueryExpression<Swift.String> = Swift.String(queryOutput: ""),
                  note: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: latitude._allColumns)
                  allColumns.append(contentsOf: name._allColumns)
                  allColumns.append(contentsOf: note._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += Double._columnWidth
                columnWidth += Swift.String._columnWidth
                columnWidth += String?._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += Double._columnWidth
              columnWidth += Swift.String._columnWidth
              columnWidth += String?._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "places"
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              let latitude = try decoder.decode(\QueryValue.latitude)
              self.name = try decoder.decode() ?? ""
              self.note = try decoder.decode() ?? nil
              guard let latitude else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.latitude = latitude
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.latitude = other.latitude
              self.name = other.name
              self.note = other.note
            }
          }

          nonisolated extension Place: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let latitude = try decoder.decode(\QueryValue.latitude)
              self.name = try decoder.decode() ?? ""
              self.note = try decoder.decode() ?? nil
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let latitude else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.latitude = latitude
            }
          }
          """#
        }
      }

      @Test func doesNotDoubleOptionalizeOptionalColumns() {
        assertMacro {
          """
          @Table
          struct Item {
            let id: Int
            var quantity: Int
            var note: String?
          }
          """
        } expansion: {
          #"""
          struct Item {
            @StructuredQueries._ColumnCheck(Int.self)
            let id: Int
            @StructuredQueries._ColumnCheck(Int.self)
            var quantity: Int
            @StructuredQueries._ColumnCheck(String?.self)
            var note: String?

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Item
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let quantity = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("quantity", keyPath: \QueryValue.quantity)
              public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: nil)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.quantity._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.quantity._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.quantity), \(self.note)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Item
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                quantity: some StructuredQueriesCore.QueryExpression<Int>,
                note: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: quantity._allColumns)
                allColumns.append(contentsOf: note._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Item
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @StructuredQueries._ColumnCheck(Int.self)
              var quantity: Int
              @StructuredQueries._ColumnCheck(String?.self)
              var note: String?

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let quantity = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("quantity", keyPath: \QueryValue.quantity)
                public let note = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("note", keyPath: \QueryValue.note, default: nil)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.quantity._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.note._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.quantity._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.note._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.quantity), \(self.note)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  quantity: some StructuredQueriesCore.QueryExpression<Int>,
                  note: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: nil)
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: quantity._allColumns)
                  allColumns.append(contentsOf: note._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += Int._columnWidth
                columnWidth += String?._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += Int._columnWidth
              columnWidth += String?._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "items"
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              let quantity = try decoder.decode(\QueryValue.quantity)
              self.note = try decoder.decode() ?? nil
              guard let quantity else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.quantity = quantity
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.quantity = other.quantity
              self.note = other.note
            }
          }

          nonisolated extension Item: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let quantity = try decoder.decode(\QueryValue.quantity)
              self.note = try decoder.decode() ?? nil
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let quantity else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.quantity = quantity
            }
          }
          """#
        }
      }

      @Test func comment() {
        assertMacro {
          """
          @Table
          struct User {
            /// The user's identifier.
            let id: /* TODO: UUID */Int // Primary key
            /// The user's email.
            var email: String? = ""  // TODO: Should this be non-optional?
            /// The user's age.
            var age: Int
          }
          """
        } expansion: {
          #"""
          struct User {
            @StructuredQueries._ColumnCheck(Int.self)
            /// The user's identifier.
            let id: /* TODO: UUID */Int // Primary key
            @StructuredQueries._ColumnCheck(String?.self)
            /// The user's email.
            var email: String? = ""  // TODO: Should this be non-optional?
            @StructuredQueries._ColumnCheck(Int.self)
            /// The user's age.
            var age: Int

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = User
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let email = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("email", keyPath: \QueryValue.email, default: "")
              public let age = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("age", keyPath: \QueryValue.age)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.age._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.age._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.email), \(self.age)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = User
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                email: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: ""),
                age: some StructuredQueriesCore.QueryExpression<Int>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: email._allColumns)
                allColumns.append(contentsOf: age._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = User
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: /* TODO: UUID */ Int? // Primary key
              @StructuredQueries._ColumnCheck(String?.self)
              var email: String? = ""
              @StructuredQueries._ColumnCheck(Int.self)
              var age: Int

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let email = StructuredQueriesCore._TableColumn<QueryValue, String?>.for("email", keyPath: \QueryValue.email, default: "")
                public let age = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("age", keyPath: \QueryValue.age)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.email._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.age._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.email._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.age._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.email), \(self.age)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  email: some StructuredQueriesCore.QueryExpression<String?> = String?(queryOutput: ""),
                  age: some StructuredQueriesCore.QueryExpression<Int>
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: email._allColumns)
                  allColumns.append(contentsOf: age._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += String?._columnWidth
                columnWidth += Int._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += String?._columnWidth
              columnWidth += Int._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "users"
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              self.email = try decoder.decode() ?? ""
              let age = try decoder.decode(\QueryValue.age)
              guard let age else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.age = age
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.email = other.email
              self.age = other.age
            }
          }

          nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              self.email = try decoder.decode() ?? ""  // TODO: Should this be non-optional?
              let age = try decoder.decode(\QueryValue.age)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let age else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.age = age
            }
          }
          """#
        }
      }

      @Test func columnGeneratedPrimaryKeyedTable() throws {
        assertMacro {
          """
          @Table struct User {
            let id: Int
            var name: String
            @Column(generated: .stored)
            let generated: Int
          }
          """
        } expansion: {
          #"""
          struct User {
            @StructuredQueries._ColumnCheck(Int.self)
            let id: Int
            @StructuredQueries._ColumnCheck(String.self)
            var name: String
            let generated: Int

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = User
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              public let generated = StructuredQueriesCore.GeneratedColumn<QueryValue, Int>("generated", keyPath: \QueryValue.generated)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.generated._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name), \(self.generated)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = User
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                name: some StructuredQueriesCore.QueryExpression<String>,
                generated: some StructuredQueriesCore.QueryExpression<Int>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                allColumns.append(contentsOf: generated._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = User
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @StructuredQueries._ColumnCheck(String.self)
              var name: String

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.name)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  name: some StructuredQueriesCore.QueryExpression<String>
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: name._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += String._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += String._columnWidth
              columnWidth += Int._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "users"
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              let name = try decoder.decode(\QueryValue.name)
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.name = name
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.name = other.name
            }
          }

          nonisolated extension User: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let name = try decoder.decode(\QueryValue.name)
              let generated = try decoder.decode(\QueryValue.generated)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let generated else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.name = name
              self.generated = generated
            }
          }
          """#
        }
      }

      @Test func ephemeralFieldPrimaryKeyedTable() {
        assertMacro {
          """
          @Table struct SyncUp {
            let id: Int
            var name: String
            @Ephemeral
            var computed: Int
          }
          """
        } expansion: {
          #"""
          struct SyncUp {
            @StructuredQueries._ColumnCheck(Int.self)
            let id: Int
            @StructuredQueries._ColumnCheck(String.self)
            var name: String
            var computed: Int

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = SyncUp
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = SyncUp
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                name: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = SyncUp
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @StructuredQueries._ColumnCheck(String.self)
              var name: String

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.name)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  name: some StructuredQueriesCore.QueryExpression<String>
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: name._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += String._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += String._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "syncUps"
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              let name = try decoder.decode(\QueryValue.name)
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.name = name
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.name = other.name
            }
          }

          nonisolated extension SyncUp: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let name = try decoder.decode(\QueryValue.name)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.name = name
            }
          }
          """#
        }
      }

      @Test func willSet() {
        assertMacro {
          """
          @Table
          struct Foo {
            var id: Int {
              willSet { print(newValue) }
            }
            var name: String {
              willSet { print(newValue) }
            }
          }
          """
        } expansion: {
          #"""
          struct Foo {
            @StructuredQueries._ColumnCheck(Int.self)
            var id: Int {
              willSet { print(newValue) }
            }
            @StructuredQueries._ColumnCheck(String.self)
            var name: String {
              willSet { print(newValue) }
            }

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Foo
              public typealias PrimaryKey = Int
              public let id = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, Int>.for("id", keyPath: \QueryValue.id)
              public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.name)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Foo
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<Int>,
                name: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: name._allColumns)
                self.allColumns = allColumns
              }
            }
            struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Foo
              @StructuredQueries._ColumnCheck(Int?.self)
              var id: Int?
              @StructuredQueries._ColumnCheck(String.self)
              var name: String

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, Int?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let name = StructuredQueriesCore._TableColumn<QueryValue, String>.for("name", keyPath: \QueryValue.name)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.name._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.name._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.name)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<Int?> = Int?(queryOutput: nil),
                  name: some StructuredQueriesCore.QueryExpression<String>
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: name._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Int?._columnWidth
                columnWidth += String._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Int._columnWidth
              columnWidth += String._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "foos"
            }
          }

          nonisolated extension Draft {
            nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              let name = try decoder.decode(\QueryValue.name)
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.name = name
            }
            nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.name = other.name
            }
          }

          nonisolated extension Foo: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let name = try decoder.decode(\QueryValue.name)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let name else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.name = name
            }
          }
          """#
        }
      }

      @Test func customPrimaryKey() {
        assertMacro {
          """
          @Table
          private struct ReminderWithList {
            @Column(primaryKey: true)
            let reminderID: Reminder.ID
            let reminderTitle: String
            let remindersListTitle: String
          }
          """
        } expansion: {
          #"""
          private struct ReminderWithList {
            let reminderID: Reminder.ID
            @StructuredQueries._ColumnCheck(String.self)
            let reminderTitle: String
            @StructuredQueries._ColumnCheck(String.self)
            let remindersListTitle: String

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = ReminderWithList
              public typealias PrimaryKey = Reminder.ID
              public let reminderID = StructuredQueriesCore.TableColumn<QueryValue, Reminder.ID>("reminderID", keyPath: \QueryValue.reminderID)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore.TableColumn<QueryValue, Reminder.ID>("reminderID", keyPath: \QueryValue.reminderID)
              public let reminderTitle = StructuredQueriesCore._TableColumn<QueryValue, String>.for("reminderTitle", keyPath: \QueryValue.reminderTitle)
              public let remindersListTitle = StructuredQueriesCore._TableColumn<QueryValue, String>.for("remindersListTitle", keyPath: \QueryValue.remindersListTitle)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.reminderID._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.reminderTitle._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.remindersListTitle._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.reminderID._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.reminderTitle._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.remindersListTitle._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.reminderID), \(self.reminderTitle), \(self.remindersListTitle)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = ReminderWithList
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                reminderID: some StructuredQueriesCore.QueryExpression<Reminder.ID>,
                reminderTitle: some StructuredQueriesCore.QueryExpression<String>,
                remindersListTitle: some StructuredQueriesCore.QueryExpression<String>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: reminderID._allColumns)
                allColumns.append(contentsOf: reminderTitle._allColumns)
                allColumns.append(contentsOf: remindersListTitle._allColumns)
                self.allColumns = allColumns
              }
            }
            fileprivate struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = ReminderWithList
              var reminderID: Reminder.ID?
              @StructuredQueries._ColumnCheck(String.self)
              let reminderTitle: String
              @StructuredQueries._ColumnCheck(String.self)
              let remindersListTitle: String

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let reminderID = StructuredQueriesCore.TableColumn<QueryValue, Reminder.ID?>("reminderID", keyPath: \QueryValue.reminderID, default: nil)
                public let reminderTitle = StructuredQueriesCore._TableColumn<QueryValue, String>.for("reminderTitle", keyPath: \QueryValue.reminderTitle)
                public let remindersListTitle = StructuredQueriesCore._TableColumn<QueryValue, String>.for("remindersListTitle", keyPath: \QueryValue.remindersListTitle)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.reminderID._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.reminderTitle._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.remindersListTitle._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.reminderID._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.reminderTitle._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.remindersListTitle._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.reminderID), \(self.reminderTitle), \(self.remindersListTitle)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  reminderID: some StructuredQueriesCore.QueryExpression<Reminder.ID?> = Reminder.ID?(queryOutput: nil),
                  reminderTitle: some StructuredQueriesCore.QueryExpression<String>,
                  remindersListTitle: some StructuredQueriesCore.QueryExpression<String>
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: reminderID._allColumns)
                  allColumns.append(contentsOf: reminderTitle._allColumns)
                  allColumns.append(contentsOf: remindersListTitle._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += Reminder.ID?._columnWidth
                columnWidth += String._columnWidth
                columnWidth += String._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += Reminder.ID._columnWidth
              columnWidth += String._columnWidth
              columnWidth += String._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "reminderWithLists"
            }
          }

          nonisolated extension Draft {
            fileprivate nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.reminderID = try decoder.decode() ?? nil
              let reminderTitle = try decoder.decode(\QueryValue.reminderTitle)
              let remindersListTitle = try decoder.decode(\QueryValue.remindersListTitle)
              guard let reminderTitle else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let remindersListTitle else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.reminderTitle = reminderTitle
              self.remindersListTitle = remindersListTitle
            }
            fileprivate nonisolated init(_ other: SourceTable) {
              self.reminderID = other.reminderID
              self.reminderTitle = other.reminderTitle
              self.remindersListTitle = other.remindersListTitle
            }
          }

          nonisolated extension ReminderWithList: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let reminderID = try decoder.decode(\QueryValue.reminderID)
              let reminderTitle = try decoder.decode(\QueryValue.reminderTitle)
              let remindersListTitle = try decoder.decode(\QueryValue.remindersListTitle)
              guard let reminderID else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let reminderTitle else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let remindersListTitle else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.reminderID = reminderID
              self.reminderTitle = reminderTitle
              self.remindersListTitle = remindersListTitle
            }
          }
          """#
        }
      }

      @Test func composite() {
        assertMacro {
          """
          @Table
          private struct Metadata: Identifiable {
            let id: MetadataID
            var userModificationDate: Date
          }
          """
        } expansion: {
          #"""
          private struct Metadata: Identifiable {
            @StructuredQueries._ColumnCheck(MetadataID.self)
            let id: MetadataID
            @StructuredQueries._ColumnCheck(Date.self)
            var userModificationDate: Date

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Metadata
              public typealias PrimaryKey = MetadataID
              public let id = StructuredQueriesCore._TableColumn<QueryValue, MetadataID>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, MetadataID>.for("id", keyPath: \QueryValue.id)
              public let userModificationDate = StructuredQueriesCore._TableColumn<QueryValue, Date>.for("userModificationDate", keyPath: \QueryValue.userModificationDate)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.userModificationDate._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.userModificationDate._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.userModificationDate)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Metadata
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<MetadataID>,
                userModificationDate: some StructuredQueriesCore.QueryExpression<Date>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: userModificationDate._allColumns)
                self.allColumns = allColumns
              }
            }
            fileprivate struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Metadata
              @StructuredQueries._ColumnCheck(MetadataID?.self)
              var id: MetadataID?
              @StructuredQueries._ColumnCheck(Date.self)
              var userModificationDate: Date

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, MetadataID?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let userModificationDate = StructuredQueriesCore._TableColumn<QueryValue, Date>.for("userModificationDate", keyPath: \QueryValue.userModificationDate)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.userModificationDate._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.userModificationDate._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.userModificationDate)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<MetadataID?> = MetadataID?(queryOutput: nil),
                  userModificationDate: some StructuredQueriesCore.QueryExpression<Date>
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: userModificationDate._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += MetadataID?._columnWidth
                columnWidth += Date._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += MetadataID._columnWidth
              columnWidth += Date._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "metadatas"
            }
          }

          nonisolated extension Draft {
            fileprivate nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              let userModificationDate = try decoder.decode(\QueryValue.userModificationDate)
              guard let userModificationDate else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.userModificationDate = userModificationDate
            }
            fileprivate nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.userModificationDate = other.userModificationDate
            }
          }

          nonisolated extension Metadata: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let userModificationDate = try decoder.decode(\QueryValue.userModificationDate)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let userModificationDate else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.userModificationDate = userModificationDate
            }
          }
          """#
        }
      }
      @Test func nested() {
        assertMacro {
          """
          @Table
          private struct Row {
            let id: UUID
            @Columns
            var timestamps: Timestamps
          }
          """
        } expansion: {
          #"""
          private struct Row {
            @StructuredQueries._ColumnCheck(UUID.self)
            let id: UUID
            var timestamps: Timestamps

            public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition, StructuredQueriesCore.PrimaryKeyedTableDefinition {
              public typealias QueryValue = Row
              public typealias PrimaryKey = UUID
              public let id = StructuredQueriesCore._TableColumn<QueryValue, UUID>.for("id", keyPath: \QueryValue.id)
              @StructuredQueries._PrimaryKeyDefault public var primaryKey = StructuredQueriesCore._TableColumn<QueryValue, UUID>.for("id", keyPath: \QueryValue.id)
              public let timestamps = StructuredQueriesCore.ColumnGroup<QueryValue, Timestamps>(keyPath: \QueryValue.timestamps)
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                allColumns.append(contentsOf: QueryValue.columns.timestamps._allColumns)
                return allColumns
              }
              #if compiler(>=6.4)
              @_optimize(none)
              #endif
              public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                writableColumns.append(contentsOf: QueryValue.columns.timestamps._writableColumns)
                return writableColumns
              }
              public var queryFragment: QueryFragment {
                "\(self.id), \(self.timestamps)"
              }
            }

            public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
              public typealias QueryValue = Row
              public let allColumns: [any StructuredQueriesCore.QueryExpression]
              public init(
                id: some StructuredQueriesCore.QueryExpression<UUID>,
                timestamps: some StructuredQueriesCore.QueryExpression<Timestamps>
              ) {
                var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                allColumns.append(contentsOf: id._allColumns)
                allColumns.append(contentsOf: timestamps._allColumns)
                self.allColumns = allColumns
              }
            }
            fileprivate struct Draft: StructuredQueriesCore.TableDraft, StructuredQueriesCore.PartialSelectStatement {
              public typealias SourceTable = Row
              @StructuredQueries._ColumnCheck(UUID?.self)
              var id: UUID?
              var timestamps: Timestamps

              public nonisolated struct TableColumns: StructuredQueriesCore.TableDefinition {
                public typealias QueryValue = Draft
                public let id = StructuredQueriesCore._TableColumn<QueryValue, UUID?>.for("id", keyPath: \QueryValue.id, default: nil)
                public let timestamps = StructuredQueriesCore.ColumnGroup<QueryValue, Timestamps>(keyPath: \QueryValue.timestamps)
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var allColumns: [any StructuredQueriesCore.TableColumnExpression] {
                  var allColumns: [any StructuredQueriesCore.TableColumnExpression] = []
                  allColumns.append(contentsOf: QueryValue.columns.id._allColumns)
                  allColumns.append(contentsOf: QueryValue.columns.timestamps._allColumns)
                  return allColumns
                }
                #if compiler(>=6.4)
                @_optimize(none)
                #endif
                public static var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] {
                  var writableColumns: [any StructuredQueriesCore.WritableTableColumnExpression] = []
                  writableColumns.append(contentsOf: QueryValue.columns.id._writableColumns)
                  writableColumns.append(contentsOf: QueryValue.columns.timestamps._writableColumns)
                  return writableColumns
                }
                public var queryFragment: QueryFragment {
                  "\(self.id), \(self.timestamps)"
                }
              }

              public nonisolated struct Selection: StructuredQueriesCore.TableExpression {
                public typealias QueryValue = Draft
                public let allColumns: [any StructuredQueriesCore.QueryExpression]
                public init(
                  id: some StructuredQueriesCore.QueryExpression<UUID?> = UUID?(queryOutput: nil),
                  timestamps: some StructuredQueriesCore.QueryExpression<Timestamps>
                ) {
                  var allColumns: [any StructuredQueriesCore.QueryExpression] = []
                  allColumns.append(contentsOf: id._allColumns)
                  allColumns.append(contentsOf: timestamps._allColumns)
                  self.allColumns = allColumns
                }
              }

              public typealias QueryValue = Self

              public typealias From = Swift.Never

              public nonisolated static var columns: TableColumns {
                TableColumns()
              }

              public nonisolated static var _columnWidth: Swift.Int {
                var columnWidth = 0
                columnWidth += UUID?._columnWidth
                columnWidth += Timestamps._columnWidth
                return columnWidth
              }
            }

            public typealias QueryValue = Self

            public typealias From = Swift.Never

            public nonisolated static var columns: TableColumns {
              TableColumns()
            }

            public nonisolated static var _columnWidth: Swift.Int {
              var columnWidth = 0
              columnWidth += UUID._columnWidth
              columnWidth += Timestamps._columnWidth
              return columnWidth
            }

            public nonisolated static var tableName: Swift.String {
              "rows"
            }
          }

          nonisolated extension Draft {
            fileprivate nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              self.id = try decoder.decode() ?? nil
              let timestamps = try decoder.decode(\QueryValue.timestamps)
              guard let timestamps else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.timestamps = timestamps
            }
            fileprivate nonisolated init(_ other: SourceTable) {
              self.id = other.id
              self.timestamps = other.timestamps
            }
          }

          nonisolated extension Row: StructuredQueriesCore.Table, StructuredQueriesCore.PrimaryKeyedTable, StructuredQueriesCore.PartialSelectStatement {
            public nonisolated init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
              let id = try decoder.decode(\QueryValue.id)
              let timestamps = try decoder.decode(\QueryValue.timestamps)
              guard let id else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              guard let timestamps else {
                throw StructuredQueriesCore.QueryDecodingError.missingRequiredColumn
              }
              self.id = id
              self.timestamps = timestamps
            }
          }
          """#
        }
      }
    #endif
  }
}
