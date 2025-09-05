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
