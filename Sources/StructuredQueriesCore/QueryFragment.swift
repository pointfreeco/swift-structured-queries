import StructuredQueriesSupport

/// A type representing a SQL string and its bindings.
///
/// You will typically create instances of this type using string literals, where bindings are
/// directly interpolated into the string. This most commonly occurs when using the `#sql` macro,
/// which takes values of this type.
public struct QueryFragment: Hashable, Sendable, CustomDebugStringConvertible {
  #if DEBUG
    /// The underlying SQL string.
    public var string: String
  #else
    /// The underlying SQL string.
    public package(set) var string: String
  #endif

  #if DEBUG
    /// An array of parameterized statement bindings.
    public var bindings: [QueryBinding]
  #else
    /// An array of parameterized statement bindings.
    public package(set) var bindings: [QueryBinding]
  #endif

  init(_ string: String = "", _ bindings: [QueryBinding] = []) {
    self.string = string
    self.bindings = bindings
  }

  /// A Boolean value indicating whether the query fragment is empty.
  public var isEmpty: Bool {
    return string.isEmpty && bindings.isEmpty
  }

  /// Appends the given fragment to this query fragment.
  ///
  /// - Parameter other: Another query fragment.
  public mutating func append(_ other: Self) {
    string.append(other.string)
    bindings.append(contentsOf: other.bindings)
  }

  /// Appends a given query fragment to another fragment.
  public static func += (lhs: inout Self, rhs: Self) {
    lhs.append(rhs)
  }

  /// Creates a new query fragment by concatenating two fragments.
  public static func + (lhs: Self, rhs: Self) -> Self {
    var query = lhs
    query += rhs
    return query
  }

  public var debugDescription: String {
    var compiled = ""
    var bindings = bindings
    var currentDelimiter: Character?
    compiled.reserveCapacity(string.count)
    let delimiters: [Character: Character] = [
      #"""#: #"""#,
      "'": "'",
      "`": "`",
      "[": "]",
    ]
    for character in string {
      if let delimiter = currentDelimiter {
        if delimiter == character,
          compiled.last != character || compiled.last == delimiters[delimiter]
        {
          currentDelimiter = nil
        }
        compiled.append(character)
      } else if delimiters.keys.contains(character) {
        currentDelimiter = character
        compiled.append(character)
      } else if character == "?" {
        compiled.append(bindings.removeFirst().debugDescription)
      } else {
        compiled.append(character)
      }
    }
    return compiled
  }
}

extension [QueryFragment] {
  /// Returns a new query fragment by concatenating the elements of the sequence, adding the given
  /// separator between each element.
  ///
  /// - Parameter separator: A query fragment to insert between each of the elements in this
  ///   sequence. The default separator is an empty fragment.
  /// - Returns: A single, concatenated fragment.
  public func joined(separator: QueryFragment = "") -> QueryFragment {
    guard var joined = first else { return QueryFragment() }
    for fragment in dropFirst() {
      joined.append(separator)
      joined.append(fragment)
    }
    return joined
  }
}

extension QueryFragment: ExpressibleByStringInterpolation {
  public init(stringInterpolation: StringInterpolation) {
    self.init(stringInterpolation.string, stringInterpolation.bindings)
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }

  /// Creates a query fragment by quoting the given SQL string.
  ///
  /// ```swift
  /// QueryFragment(quote: "myTable")
  /// // "myTable"
  ///
  /// QueryFragment(quote: #"The "best" table"#)
  /// // "The ""best"" table"
  /// ```
  ///
  /// - Parameters:
  ///   - sql: A query string to be quoted.
  ///   - delimiter: The delimiter used for quoting. Defaults to `.identifier`, which uses `"` for
  ///     quoting.
  public init(
    quote sql: String,
    delimiter: QuoteDelimiter = .identifier
  ) {
    self.init(sql.quoted(delimiter))
  }

  public struct StringInterpolation: StringInterpolationProtocol {
    public var string = ""
    public var bindings: [QueryBinding] = []

    public init(literalCapacity: Int, interpolationCount: Int) {
      string.reserveCapacity(literalCapacity)
      bindings.reserveCapacity(interpolationCount)
    }

    public mutating func appendLiteral(_ literal: String) {
      string.append(literal)
    }

    /// Append a quoted fragment to the interpolation.
    ///
    /// ```swift
    /// #sql("SELECT \(quote: "id") FROM \(quote: "reminders")", as: Reminder.self)
    /// // SELECT "id" FROM "reminders"
    ///
    /// #sql("CREATE TABLE t (c TEXT DEFAULT \(quote: "Blob's world", delimiter: .text))")
    /// // SELECT TABLE t (c TEXT DEFAULT 'Blob''s world')
    /// ```
    ///
    /// - Parameters:
    ///   - sql: A query string to be quoted.
    ///   - delimiter: The delimiter used for quoting. Defaults to `.identifier`, which uses `"` for
    ///     quoting.
    public mutating func appendInterpolation(
      quote sql: String,
      delimiter: QuoteDelimiter = .identifier
    ) {
      string.append(sql.quoted(delimiter))
    }

    /// Append a raw SQL string to the interpolation.
    ///
    /// > Warning: Avoid using this API as much as possible as it naively interpolates the raw
    /// > string into your SQL statements, leaving you open to SQL injection attacks. Instead,
    /// > use the other interpolation methods available to you, such as ``appendInterpolation(_:)``
    /// > or ``appendInterpolation(bind:)``.
    ///
    /// - Parameter sql: A raw query string.
    public mutating func appendInterpolation(raw sql: String) {
      string.append(sql)
    }

    /// Append a raw lossless string to the interpolation.
    ///
    /// This can be used to interpolate values into statements in which they cannot be bound.
    ///
    /// ```swift
    /// #sql("CREATE TABLE t (c INTEGER DEFAULT \(raw: 0))")
    /// // CREATE TABLE t (c INTEGER DEFAULT 0)
    /// ```
    ///
    /// > Warning: Avoid introducing raw SQL and potential injection attacks. Instead, append
    /// > query fragments that safely bind data _via_ interpolation.
    ///
    /// - Parameter sql: A raw query string.
    public mutating func appendInterpolation(raw sql: some LosslessStringConvertible) {
      string.append(sql.description)
    }

    /// Append a query binding to the interpolation.
    ///
    /// - Parameter binding: A query binding.
    public mutating func appendInterpolation(_ binding: QueryBinding) {
      string.append("?")
      bindings.append(binding)
    }

    /// Append a query fragment to the interpolation.
    ///
    /// - Parameter fragment: A query fragment.
    public mutating func appendInterpolation(_ fragment: QueryFragment) {
      string.append(fragment.string)
      bindings.append(contentsOf: fragment.bindings)
    }

    /// Append a query expression to the interpolation.
    ///
    /// - Parameter expression: A query expression.
    public mutating func appendInterpolation(bind expression: some QueryExpression) {
      appendInterpolation(expression.queryFragment)
    }

    /// Append a query expression to the interpolation.
    ///
    /// - Parameter expression: A query expression.
    public mutating func appendInterpolation(_ expression: some QueryExpression) {
      appendInterpolation(expression.queryFragment)
    }

    /// Append a statement to the interpolation.
    ///
    /// The statement is directly interpolated into the query fragment, without parentheses. When
    /// introducing a statement into a query fragment as a subquery, be sure to explicitly
    /// parenthesize the interpolation:
    ///
    /// ```swift
    /// let averagePriority = Reminder.select { $0.priority.avg() }
    ///
    /// #sql(
    ///   """
    ///   SELECT title FROM reminders
    ///   WHERE priority > (\(averagePriority))
    ///   """,
    ///   as: String.self
    /// )
    /// // SELECT title FROM reminders
    /// // WHERE priority > (SELECT avg("reminders"."priority) FROM "reminders")
    /// ```
    ///
    /// - Parameter statement: A statement.
    public mutating func appendInterpolation(_ statement: some PartialSelectStatement) {
      appendInterpolation(statement.query)
    }

    /// Append a table's alias or name to the interpolation.
    ///
    /// ```swift
    /// #sql("SELECT title FROM \(Reminder.self)), as: String.self)
    /// // SELECT title FROM "reminders"
    ///
    /// enum R: AliasName {}
    /// #sql("SELECT title FROM \(Reminder.as(R.self))", as: String.self)
    /// // SELECT title FROM "rs"
    /// ```
    ///
    /// - Parameter table: A table.
    public mutating func appendInterpolation<T: Table>(_ table: T.Type) {
      if let schemaName = table.schemaName {
        appendInterpolation(quote: schemaName)
        appendLiteral(".")
      }
      appendInterpolation(quote: table.tableAlias ?? table.tableName)
    }

    @available(
      *,
      deprecated,
      renamed: "appendInterpolation(bind:)",
      message: """
        String interpolation produces a bind for a string value; did you mean to make this explicit? To append raw SQL, use "\\(raw: sqlString)".
        """
    )
    public mutating func appendInterpolation(_ expression: String) {
      appendInterpolation(bind: expression)
    }
  }
}
