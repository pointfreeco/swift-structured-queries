public import StructuredQueriesCore

extension QueryExpression where QueryValue == Bool {
  /// Wraps this expression with the `likelihood` function given a probability.
  ///
  /// ```swift
  /// Reminder.where { ($0.probability == .high).likelihood(0.75) }
  /// // SELECT … FROM "reminders"
  /// // WHERE likelihood("reminders"."probability" = 3, 0.75)
  /// ```
  ///
  /// - Parameter probability: A probability hint for the given expression.
  /// - Returns: A predicate expression of the given likelihood.
  public func likelihood(
    _ probability: some QueryExpression<some FloatingPoint>
  ) -> some QueryExpression<QueryValue> {
    QueryFunction("likelihood", self, probability)
  }

  /// Wraps this expression with the `likely` function.
  ///
  /// ```swift
  /// Reminder.where { ($0.probability == .high).likely() }
  /// // SELECT … FROM "reminders"
  /// // WHERE likely("reminders"."probability" = 3)
  /// ```
  ///
  /// - Returns: A likely predicate expression.
  public func likely() -> some QueryExpression<QueryValue> {
    QueryFunction("likely", self)
  }

  /// Wraps this expression with the `unlikely` function.
  ///
  /// ```swift
  /// Reminder.where { ($0.probability == .high).unlikely() }
  /// // SELECT … FROM "reminders"
  /// // WHERE unlikely("reminders"."probability" = 3)
  /// ```
  ///
  /// - Returns: An unlikely predicate expression.
  public func unlikely() -> some QueryExpression<QueryValue> {
    QueryFunction("unlikely", self)
  }
}

extension QueryExpression where QueryValue: BinaryInteger {
  /// Creates an expression invoking the `randomblob` function with the given integer expression.
  ///
  /// ```swift
  /// Asset.insert { $0.bytes } values: { 1_024.randomblob() }
  /// // INSERT INTO "assets" ("bytes") VALUES (randomblob(1024))
  /// ```
  ///
  /// - Returns: A blob expression of the `randomblob` function wrapping the given integer.
  public func randomblob() -> some QueryExpression<[UInt8]> {
    QueryFunction("randomblob", self)
  }

  /// Creates an expression invoking the `zeroblob` function with the given integer expression.
  ///
  /// ```swift
  /// Asset.insert { $0.bytes } values: { 1_024.zeroblob() }
  /// // INSERT INTO "assets" ("bytes") VALUES (zeroblob(1024))
  /// ```
  ///
  /// - Returns: A blob expression of the `zeroblob` function wrapping the given integer.
  public func zeroblob() -> some QueryExpression<[UInt8]> {
    QueryFunction("zeroblob", self)
  }
}

extension QueryExpression where QueryValue: _OptionalPromotable<String?> {
  /// Wraps this string query expression with the `unicode` function.
  ///
  /// - Returns: An optional integer expression of the `unicode` function wrapping this expression.
  public func unicode() -> some QueryExpression<Int?> {
    QueryFunction("unicode", self)
  }
}

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped: Numeric {
  /// Wraps this numeric query expression with the `sign` function.
  ///
  /// - Returns: An expression wrapped with the `sign` function.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  #endif
  public func sign() -> some QueryExpression<QueryValue> {
    QueryFunction("sign", self)
  }
}

extension QueryExpression where QueryValue == String {
  /// Creates an expression invoking the `octet_length` function with the given string expression.
  ///
  /// - Returns: An integer expression of the `octet_length` function wrapping the given string.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  #endif
  public func octetLength() -> some QueryExpression<Int> {
    QueryFunction("octet_length", self)
  }
}

extension QueryExpression where QueryValue: _OptionalPromotable<String?> {
  /// Wraps this string query expression with the `unhex` function.
  ///
  /// - Parameter characters: Non-hexadecimal characters to skip.
  /// - Returns: An optional blob expression of the `unhex` function wrapping this expression.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  #endif
  public func unhex(
    _ characters: (some QueryExpression<String>)? = String?.none
  ) -> some QueryExpression<[UInt8]?> {
    if let characters {
      return QueryFunction("unhex", self, characters)
    } else {
      return QueryFunction("unhex", self)
    }
  }
}
