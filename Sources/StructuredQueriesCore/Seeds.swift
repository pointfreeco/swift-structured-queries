/// A type that can prepare statements to seed a database's initial state.
public struct Seeds: Sequence {
  let seeds: [any Table]

  /// Prepares a number of batched insert statements to be executed.
  ///
  /// ```swift
  /// Seeds {
  ///   SyncUp(id: 1, seconds: 60, theme: .appOrange, title: "Design")
  ///   SyncUp(id: 2, seconds: 60 * 10, theme: .periwinkle, title: "Engineering")
  ///   SyncUp(id: 3, seconds: 60 * 30, theme: .poppy, title: "Product")
  ///
  ///   for name in ["Blob", "Blob Jr", "Blob Sr", "Blob Esq", "Blob III", "Blob I"] {
  ///     Attendee.Draft(name: name, syncUpID: 1)
  ///   }
  ///   for name in ["Blob", "Blob Jr"] {
  ///     Attendee.Draft(name: name, syncUpID: 2)
  ///   }
  ///   for name in ["Blob Sr", "Blob Jr"] {
  ///     Attendee.Draft(name: name, syncUpID: 3)
  ///   }
  /// }
  /// // INSERT INTO "syncUps"
  /// //   ("id", "seconds", "theme", "title")
  /// // VALUES
  /// //   (1, 60, 'appOrange', 'Design'),
  /// //   (2, 600, 'periwinkle', 'Engineering'),
  /// //   (3, 1800, 'poppy', 'Product');
  /// // INSERT INTO "attendees"
  /// //   ("id", "name", "syncUpID")
  /// // VALUES
  /// //   (NULL, 'Blob', 1),
  /// //   (NULL, 'Blob Jr', 1),
  /// //   (NULL, 'Blob Sr', 1),
  /// //   (NULL, 'Blob Esq', 1),
  /// //   (NULL, 'Blob III', 1),
  /// //   (NULL, 'Blob I', 1),
  /// //   (NULL, 'Blob', 2),
  /// //   (NULL, 'Blob Jr', 2),
  /// //   (NULL, 'Blob Sr', 3),
  /// //   (NULL, 'Blob Jr', 3);
  /// ```
  ///
  /// And then you can iterate over each insert statement and execute it given a database
  /// connection. For example, using the [SQLiteData] driver:
  ///
  /// ```swift
  /// try database.write { db in
  ///   let seeds = Seeds {
  ///     // ...
  ///   }
  ///   for insert in seeds {
  ///     try db.execute(insert)
  ///   }
  /// }
  /// ```
  ///
  /// > Tip: [SQLiteData] extends GRDB's `Database` connection with a `seed` method that can build
  /// > and insert records in a single step:
  /// >
  /// > ```swift
  /// > try db.seed {
  /// >   // ...
  /// > }
  /// > ```
  ///
  /// [SQLiteData]: https://github.com/pointfreeco/sqlite-data
  ///
  /// - Parameter build: A result builder closure that prepares statements to insert every built row.
  public init(@SeedsBuilder _ build: () -> [any Table]) {
    self.seeds = build()
  }

  public func makeIterator() -> Iterator {
    Iterator(seeds: seeds)
  }

  public struct Iterator: IteratorProtocol {
    var seeds: [any Table]

    public mutating func next() -> SQLQueryExpression<Void>? {
      guard let first = seeds.first else { return nil }

      let firstType = type(of: first)

      if let firstType = firstType as? any TableDraft.Type {
        func insertBatch<T: TableDraft>(_: T.Type) -> SQLQueryExpression<Void> {
          let batch = Array(seeds.lazy.prefix { $0 is T }.compactMap { $0 as? T })
          defer { seeds.removeFirst(batch.count) }
          return SQLQueryExpression(T.PrimaryTable.insert { batch })
        }

        return insertBatch(firstType)
      } else {
        func insertBatch<T: Table>(_: T.Type) -> SQLQueryExpression<Void> {
          let batch = Array(seeds.lazy.prefix { $0 is T }.compactMap { $0 as? T })
          defer { seeds.removeFirst(batch.count) }
          return SQLQueryExpression(T.insert { batch })
        }

        return insertBatch(firstType)
      }
    }
  }
}

@resultBuilder
public enum SeedsBuilder {
  public static func buildArray(_ components: [[any Table]]) -> [any Table] {
    components.flatMap(\.self)
  }

  public static func buildBlock(_ components: [any Table]) -> [any Table] {
    components
  }

  public static func buildEither(first component: [any Table]) -> [any Table] {
    component
  }

  public static func buildEither(second component: [any Table]) -> [any Table] {
    component
  }

  public static func buildExpression(_ expression: some Table) -> [any Table] {
    [expression]
  }

  public static func buildExpression(_ expression: [any Table]) -> [any Table] {
    expression
  }

  public static func buildLimitedAvailability(_ component: [any Table]) -> [any Table] {
    component
  }

  public static func buildOptional(_ component: [any Table]?) -> [any Table] {
    component ?? []
  }

  public static func buildPartialBlock(first: [any Table]) -> [any Table] {
    first
  }

  public static func buildPartialBlock(accumulated: [any Table], next: [any Table]) -> [any Table] {
    accumulated + next
  }
}
