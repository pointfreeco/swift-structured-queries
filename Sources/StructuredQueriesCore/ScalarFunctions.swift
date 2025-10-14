import Foundation

extension QueryExpression where QueryValue: Collection {
  /// Wraps this expression with the `length` function.
  ///
  /// ```swift
  /// Reminder.select { $0.title.length() }
  /// // SELECT length("reminders"."title") FROM "reminders"
  ///
  /// Asset.select { $0.bytes.length() }
  /// // SELECT length("assets"."bytes") FROM "assets
  /// ```
  ///
  /// - Returns: An integer expression of the `length` function wrapping this expression.
  public func length() -> some QueryExpression<Int> {
    QueryFunction("length", self)
  }

  @available(
    *,
    deprecated,
    message: "Use 'count()' for SQL's 'count' aggregate function, or 'length()'"
  )
  public var count: some QueryExpression<Int> {
    length()
  }
}

extension QueryExpression where QueryValue: FloatingPoint {
  /// Wraps this floating point query expression with the `round` function.
  ///
  /// ```swift
  /// Item.select { $0.price.round() }
  /// // SELECT round("items"."price") FROM "items"
  ///
  /// Item.select { $0.price.avg().round(2) }
  /// // SELECT round(avg("items"."price"), 2) FROM "items"
  /// ```
  ///
  /// - Parameter precision: The number of digits to the right of the decimal point to round to.
  /// - Returns: An expression wrapped with the `round` function.
  public func round(
    _ precision: (some QueryExpression<Int>)? = Int?.none
  ) -> some QueryExpression<QueryValue> {
    if let precision {
      return QueryFunction("round", self, precision)
    } else {
      return QueryFunction("round", self)
    }
  }
}

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped: Numeric {
  /// Wraps this numeric query expression with the `abs` function.
  ///
  /// - Returns: An expression wrapped with the `abs` function.
  public func abs() -> some QueryExpression<QueryValue> {
    QueryFunction("abs", self)
  }

  /// Wraps this numeric query expression with the `sign` function.
  ///
  /// - Returns: An expression wrapped with the `sign` function.
  public func sign() -> some QueryExpression<QueryValue> {
    QueryFunction("sign", self)
  }
}

extension QueryExpression where QueryValue: _OptionalProtocol {
  /// Wraps this optional query expression with the `ifnull` function.
  ///
  /// ```swift
  /// Reminder
  ///   .select { $0.dueDate.ifnull(#sql("date()")) }
  /// // SELECT ifnull("reminders"."dueDate", date())
  /// // FROM "reminders"
  /// ```
  ///
  /// - Returns: A non-optional expression of the `ifnull` function wrapping this expression.
  public func ifnull(
    _ other: some QueryExpression<QueryValue.Wrapped>
  ) -> some QueryExpression<QueryValue.Wrapped> {
    QueryFunction("ifnull", self, other)
  }

  /// Wraps this optional query expression with the `ifnull` function.
  ///
  /// ```swift
  /// Reminder
  ///   .select { $0.dueDate.ifnull(#sql("date()")) }
  /// // SELECT ifnull("reminders"."dueDate", date())
  /// // FROM "reminders"
  /// ```
  ///
  /// - Returns: An optional expression of the `ifnull` function wrapping this expression.
  public func ifnull(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    QueryFunction("ifnull", self, other)
  }

  /// Applies each side of the operator to the `coalesce` function
  ///
  /// ```swift
  /// Reminder.select { $0.date ?? #sql("date()") }
  /// // SELECT coalesce("reminders"."date", date()) FROM "reminders"
  /// ```
  ///
  /// > Tip: Heavily overloaded Swift operators can tax the compiler. You can use ``ifnull(_:)``,
  /// > instead, if you find a particular query builds slowly. See
  /// > <doc:CompilerPerformance#Method-operators> for more information.
  ///
  /// - Parameters:
  ///   - lhs: An optional query expression.
  ///   - rhs: A non-optional query expression
  /// - Returns: A non-optional query expression of the `coalesce` function wrapping both arguments.
  public static func ?? (
    lhs: Self,
    rhs: some QueryExpression<QueryValue.Wrapped>
  ) -> CoalesceFunction<QueryValue.Wrapped> {
    CoalesceFunction([lhs.queryFragment, rhs.queryFragment])
  }

  /// Applies each side of the operator to the `coalesce` function
  ///
  /// ```swift
  /// Reminder.select { $0.date ?? #sql("date()") }
  /// // SELECT coalesce("reminders"."date", date()) FROM "reminders"
  /// ```
  ///
  /// > Tip: Heavily overloaded Swift operators can tax the compiler. You can use ``ifnull(_:)``,
  /// > instead, if you find a particular query builds slowly. See
  /// > <doc:CompilerPerformance#Method-operators> for more information.
  ///
  /// - Parameters:
  ///   - lhs: An optional query expression.
  ///   - rhs: Another optional query expression
  /// - Returns: An optional query expression of the `coalesce` function wrapping both arguments.
  public static func ?? (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> CoalesceFunction<QueryValue> {
    CoalesceFunction([lhs.queryFragment, rhs.queryFragment])
  }

  @_documentation(visibility: private)
  @available(
    *,
    deprecated,
    message:
      "Left side of 'NULL' coalescing operator '??' has non-optional query type, so the right side is never used"
  )
  public static func ?? (
    lhs: some QueryExpression<QueryValue.Wrapped>,
    rhs: Self
  ) -> CoalesceFunction<QueryValue> {
    CoalesceFunction([lhs.queryFragment, rhs.queryFragment])
  }
}

extension QueryExpression {
  @_documentation(visibility: private)
  @available(
    *,
    deprecated,
    message:
      "Left side of 'NULL' coalescing operator '??' has non-optional query type, so the right side is never used"
  )
  public static func ?? (
    lhs: some QueryExpression<QueryValue>,
    rhs: Self
  ) -> CoalesceFunction<QueryValue> {
    CoalesceFunction([lhs.queryFragment, rhs.queryFragment])
  }
}

extension QueryExpression where QueryValue == String {
  /// Wraps this optional query expression with the `instr` function.
  ///
  /// - Returns: An integer expression of the `instr` function wrapping this expression.
  public func instr(_ occurrence: some QueryExpression<QueryValue>) -> some QueryExpression<Int> {
    QueryFunction("instr", self, occurrence)
  }
}

extension QueryExpression where QueryValue: _OptionalPromotable<String?> {
  /// Wraps this string expression with the `lower` function.
  ///
  /// - Returns: An expression wrapped with the `lower` function.
  public func lower() -> some QueryExpression<QueryValue> {
    QueryFunction("lower", self)
  }
}

extension QueryExpression where QueryValue == String {
  /// Wraps this string expression with the `ltrim` function.
  ///
  /// - Parameter characters: Characters to trim.
  /// - Returns: An expression wrapped with the `ltrim` function.
  public func ltrim(
    _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
  ) -> some QueryExpression<QueryValue> {
    if let characters {
      return QueryFunction("ltrim", self, characters)
    } else {
      return QueryFunction("ltrim", self)
    }
  }

  /// Creates an expression invoking the `octet_length` function with the given string expression.
  ///
  /// - Returns: An integer expression of the `octet_length` function wrapping the given string.
  public func octetLength() -> some QueryExpression<Int> {
    QueryFunction("octet_length", self)
  }
}

extension QueryExpression where QueryValue: _OptionalPromotable<String?> {
  /// Wraps this string expression with the `quote` function.
  ///
  /// - Returns: An expression wrapped with the `quote` function.
  public func quote() -> some QueryExpression<QueryValue> {
    QueryFunction("quote", self)
  }
}

extension QueryExpression where QueryValue == String {
  /// Creates an expression invoking the `replace` function.
  ///
  /// - Parameters:
  ///   - other: The substring to be replaced.
  ///   - replacement: The replacement string.
  /// - Returns: An expression of the `replace` function wrapping the given string, a substring to
  ///   replace, and the replacement.
  public func replace(
    _ other: some QueryExpression<QueryValue>,
    _ replacement: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    QueryFunction("replace", self, other, replacement)
  }

  /// Wraps this string expression with the `rtrim` function.
  ///
  /// - Parameter characters: Characters to trim.
  /// - Returns: An expression wrapped with the `rtrim` function.
  public func rtrim(
    _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
  ) -> some QueryExpression<QueryValue> {
    if let characters {
      return QueryFunction("rtrim", self, characters)
    } else {
      return QueryFunction("rtrim", self)
    }
  }

  /// Creates an expression invoking the `substr` function.
  ///
  /// - Parameters:
  ///   - offset: The substring to be replaced.
  ///   - length: The replacement string.
  /// - Returns: An expression of the `substr` function wrapping the given string, an offset, and
  ///   length.
  public func substr(
    _ offset: some QueryExpression<Int>,
    _ length: (some QueryExpression<Int>)? = Int?.none
  ) -> some QueryExpression<QueryValue> {
    if let length {
      return QueryFunction("substr", self, offset, length)
    } else {
      return QueryFunction("substr", self, offset)
    }
  }

  /// Wraps this string expression with the `trim` function.
  ///
  /// - Parameter characters: Characters to trim.
  /// - Returns: An expression wrapped with the `trim` function.
  public func trim(
    _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
  ) -> some QueryExpression<QueryValue> {
    if let characters {
      return QueryFunction("trim", self, characters)
    } else {
      return QueryFunction("trim", self)
    }
  }
}

extension QueryExpression where QueryValue: _OptionalPromotable<String?> {
  /// Wraps this string query expression with the `unhex` function.
  ///
  /// - Parameter characters: Non-hexadecimal characters to skip.
  /// - Returns: An optional blob expression of the `unhex` function wrapping this expression.
  public func unhex(
    _ characters: (some QueryExpression<String>)? = String?.none
  ) -> some QueryExpression<[UInt8]?> {
    if let characters {
      return QueryFunction("unhex", self, characters)
    } else {
      return QueryFunction("unhex", self)
    }
  }

  /// Wraps this string expression with the `upper` function.
  ///
  /// - Returns: An expression wrapped with the `upper` function.
  public func upper() -> some QueryExpression<QueryValue> {
    QueryFunction("upper", self)
  }
}

extension QueryExpression where QueryValue == [UInt8] {
  /// Wraps this blob query expression with the `hex` function.
  ///
  /// - Returns: A string expression of the `hex` function wrapping this expression.
  public func hex() -> some QueryExpression<String> {
    QueryFunction("hex", self)
  }
}

package struct QueryFunction<QueryValue>: QueryExpression {
  let name: QueryFragment
  let arguments: [QueryFragment]

  package init<each Argument: QueryExpression>(
    _ name: QueryFragment,
    _ arguments: repeat each Argument
  ) {
    self.name = name
    self.arguments = Array(repeat each arguments)
  }

  public var queryFragment: QueryFragment {
    "\(name)(\(arguments.joined(separator: ", ")))"
  }
}

/// A query expression of a coalesce function.
public struct CoalesceFunction<QueryValue>: QueryExpression {
  private let arguments: [QueryFragment]

  fileprivate init(_ arguments: [QueryFragment]) {
    self.arguments = arguments
  }

  public var queryFragment: QueryFragment {
    "coalesce(\(arguments.joined(separator: ", ")))"
  }

  public static func ?? <T: _OptionalProtocol<QueryValue>>(
    lhs: some QueryExpression<T>,
    rhs: Self
  ) -> CoalesceFunction<QueryValue> {
    Self([lhs.queryFragment] + rhs.arguments)
  }
}

extension CoalesceFunction where QueryValue: _OptionalProtocol {
  public static func ?? (
    lhs: some QueryExpression<QueryValue>,
    rhs: Self
  ) -> Self {
    Self([lhs.queryFragment] + rhs.arguments)
  }
}
