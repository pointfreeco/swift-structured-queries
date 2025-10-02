extension QueryExpression where QueryValue: QueryRepresentable {
  /// A predicate expression indicating whether two query expressions are equal.
  ///
  /// ```swift
  /// Reminder.where { $0.title == "Buy milk" }
  /// // SELECT … FROM "reminders" WHERE "reminders"."title" = 'Buy milk'
  /// ```
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``eq(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: An expression to compare.
  ///   - rhs: Another expression to compare.
  /// - Returns: A predicate expression.
  public static func == (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    lhs.eq(rhs)
  }

  /// A predicate expression indicating whether two query expressions are not equal.
  ///
  /// ```swift
  /// Reminder.where { $0.title != "Buy milk" }
  /// // SELECT … FROM "reminders" WHERE "reminders"."title" <> 'Buy milk'
  /// ```
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``neq(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: An expression to compare.
  ///   - rhs: Another expression to compare.
  /// - Returns: A predicate expression.
  public static func != (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    lhs.neq(rhs)
  }

  /// Returns a predicate expression indicating whether two query expressions are equal.
  ///
  /// ```swift
  /// Reminder.where { $0.title.eq("Buy milk") }
  /// // SELECT … FROM "reminders" WHERE "reminders"."title" = 'Buy milk'
  /// ```
  ///
  /// - Parameter other: An expression to compare this one to.
  /// - Returns: A predicate expression.
  public func eq(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "=", rhs: other)
  }

  /// Returns a predicate expression indicating whether two query expressions are not equal.
  ///
  /// ```swift
  /// Reminder.where { $0.title.neq("Buy milk") }
  /// // SELECT … FROM "reminders" WHERE "reminders"."title" <> 'Buy milk'
  /// ```
  ///
  /// - Parameter other: An expression to compare this one to.
  /// - Returns: A predicate expression.
  public func neq(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "<>", rhs: other)
  }

  /// Returns a predicate expression indicating whether two query expressions are equal (or are
  /// equal to `NULL`).
  ///
  /// ```swift
  /// Reminder.where { $0.priority.is(nil) }
  /// // SELECT … FROM "reminders" WHERE "reminders"."priority" IS NULL
  /// ```
  ///
  /// - Parameter other: An expression to compare this one to.
  /// - Returns: A predicate expression.
  public func `is`<Other: QueryRepresentable>(
    _ other: some QueryExpression<Other>
  ) -> some QueryExpression<Bool>
  where QueryValue._Optionalized.Wrapped == Other._Optionalized.Wrapped {
    BinaryOperator(lhs: self, operator: "IS", rhs: other)
  }

  /// Returns a predicate expression indicating whether two query expressions are not equal (or are
  /// not equal to `NULL`).
  ///
  /// ```swift
  /// Reminder.where { $0.priority.isNot(nil) }
  /// // SELECT … FROM "reminders" WHERE "reminders"."priority" IS NOT NULL
  /// ```
  ///
  /// - Parameter other: An expression to compare this one to.
  /// - Returns: A predicate expression.
  public func isNot<Other: QueryRepresentable>(
    _ other: some QueryExpression<QueryValue._Optionalized>
  ) -> some QueryExpression<Bool>
  where QueryValue._Optionalized.Wrapped == Other._Optionalized.Wrapped {
    BinaryOperator(lhs: self, operator: "IS NOT", rhs: other)
  }
}

private func isNull<Value>(_ expression: some QueryExpression<Value>) -> Bool {
  (expression as? any _OptionalProtocol).map { $0._wrapped == nil } ?? false
}

extension QueryExpression where QueryValue: QueryRepresentable & QueryExpression {
  @_documentation(visibility: private)
  public func `is`(
    _ other: _Null<QueryValue>
  ) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "IS", rhs: other)
  }

  @_documentation(visibility: private)
  public func isNot(
    _ other: _Null<QueryValue>
  ) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "IS NOT", rhs: other)
  }
}

public struct _Null<Wrapped: QueryExpression>: QueryExpression {
  public typealias QueryValue = Wrapped?
  public var queryFragment: QueryFragment {
    Wrapped?.none.queryFragment
  }
}

extension _Null: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {}
}

// TODO: Remove this when we correctly unwrap `TableColumns` in `join` conditions.
extension QueryExpression where QueryValue: QueryRepresentable & _OptionalProtocol {
  @_documentation(visibility: private)
  public func eq(_ other: some QueryExpression<QueryValue.Wrapped>) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "=", rhs: other)
  }

  @_documentation(visibility: private)
  public func neq(_ other: some QueryExpression<QueryValue.Wrapped>) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "<>", rhs: other)
  }

  @_documentation(visibility: private)
  public func eq(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "=", rhs: other)
  }

  @_documentation(visibility: private)
  public func neq(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "<>", rhs: other)
  }

  @_documentation(visibility: private)
  public func `is`(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "IS", rhs: other)
  }

  @_documentation(visibility: private)
  public func isNot(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "IS NOT", rhs: other)
  }
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_disfavoredOverload
@_documentation(visibility: private)
public func == <QueryValue>(
  lhs: any QueryExpression<QueryValue>,
  rhs: some QueryExpression<QueryValue?>
) -> some QueryExpression<Bool> {
  BinaryOperator(lhs: lhs, operator: isNull(rhs) ? "IS" : "=", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_disfavoredOverload
@_documentation(visibility: private)
public func != <QueryValue>(
  lhs: any QueryExpression<QueryValue>,
  rhs: some QueryExpression<QueryValue?>
) -> some QueryExpression<Bool> {
  BinaryOperator(lhs: lhs, operator: isNull(rhs) ? "IS NOT" : "<>", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
@_disfavoredOverload
public func == <QueryValue: _OptionalProtocol>(
  lhs: any QueryExpression<QueryValue>,
  rhs: some QueryExpression<QueryValue.Wrapped>
) -> some QueryExpression<Bool> {
  BinaryOperator(lhs: lhs, operator: "IS", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
@_disfavoredOverload
public func != <QueryValue: _OptionalProtocol>(
  lhs: any QueryExpression<QueryValue>,
  rhs: some QueryExpression<QueryValue.Wrapped>
) -> some QueryExpression<Bool> {
  BinaryOperator(lhs: lhs, operator: "IS NOT", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
public func == <QueryValue: _OptionalProtocol>(
  lhs: any QueryExpression<QueryValue>,
  rhs: some QueryExpression<QueryValue>
) -> some QueryExpression<Bool> {
  BinaryOperator(lhs: lhs, operator: "IS", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
public func != <QueryValue: _OptionalProtocol>(
  lhs: any QueryExpression<QueryValue>,
  rhs: some QueryExpression<QueryValue>
) -> some QueryExpression<Bool> {
  BinaryOperator(lhs: lhs, operator: "IS NOT", rhs: rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
public func == <QueryValue: QueryBindable>(
  lhs: any QueryExpression<QueryValue>,
  rhs: _Null<QueryValue>
) -> some QueryExpression<Bool> {
  SQLQueryExpression(lhs).is(rhs)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
public func != <QueryValue: QueryBindable>(
  lhs: any QueryExpression<QueryValue>,
  rhs: _Null<QueryValue>
) -> some QueryExpression<Bool> {
  SQLQueryExpression(lhs).isNot(rhs)
}

extension QueryExpression where QueryValue: _OptionalPromotable {
  /// Returns a predicate expression indicating whether the value of the first expression is less
  /// than that of the second expression.
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``lt(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: An expression to compare.
  ///   - rhs: Another expression to compare.
  /// - Returns: A predicate expression.
  public static func < (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    lhs.lt(rhs)
  }

  /// Returns a predicate expression indicating whether the value of the first expression is greater
  /// than that of the second expression.
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``gt(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: An expression to compare.
  ///   - rhs: Another expression to compare.
  /// - Returns: A predicate expression.
  public static func > (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    lhs.gt(rhs)
  }

  /// Returns a predicate expression indicating whether the value of the first expression is less
  /// than or equal to that of the second expression.
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``lte(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: An expression to compare.
  ///   - rhs: Another expression to compare.
  /// - Returns: A predicate expression.
  public static func <= (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    lhs.lte(rhs)
  }

  /// Returns a predicate expression indicating whether the value of the first expression is greater
  /// than or equal to that of the second expression.
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``gte(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: An expression to compare.
  ///   - rhs: Another expression to compare.
  /// - Returns: A predicate expression.
  public static func >= (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    lhs.gte(rhs)
  }

  /// Returns a predicate expression indicating whether the value of the first expression is less
  /// than that of the second expression.
  ///
  /// - Parameter other: An expression to compare this one to.
  /// - Returns: A predicate expression.
  public func lt(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "<", rhs: other)
  }

  /// Returns a predicate expression indicating whether the value of the first expression is greater
  /// than that of the second expression.
  ///
  /// - Parameter other: An expression to compare this one to.
  /// - Returns: A predicate expression.
  public func gt(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: ">", rhs: other)
  }

  /// Returns a predicate expression indicating whether the value of the first expression is less
  /// than or equal to that of the second expression.
  ///
  /// - Parameter other: An expression to compare this one to.
  /// - Returns: A predicate expression.
  public func lte(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "<=", rhs: other)
  }

  /// Returns a predicate expression indicating whether the value of the first expression is greater
  /// than or equal to that of the second expression.
  ///
  /// - Parameter other: An expression to compare this one to.
  /// - Returns: A predicate expression.
  public func gte(
    _ other: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: ">=", rhs: other)
  }
}

extension QueryExpression where QueryValue == Bool {
  /// Returns a logical AND operation on two predicate expressions.
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``and(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side of the operation.
  ///   - rhs: The right-hand side of the operation.
  /// - Returns: A predicate expression.
  public static func && (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    lhs.and(rhs)
  }

  /// Returns a logical OR operation on two predicate expressions.
  ///
  /// > Important: Overloaded operators can strain the Swift compiler's type checking ability.
  /// > Consider using ``or(_:)``, instead.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side of the operation.
  ///   - rhs: The right-hand side of the operation.
  /// - Returns: A predicate expression.
  public static func || (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    lhs.or(rhs)
  }

  /// Returns a logical NOT operation on a predicate expression.
  ///
  /// - Parameter expression: The predicate expression to negate.
  /// - Returns: A negated predicate expression.
  public static prefix func ! (expression: Self) -> some QueryExpression<QueryValue> {
    expression.not()
  }

  /// Returns a logical AND operation on two predicate expressions.
  ///
  /// - Parameter other: The right-hand side of the operation to this predicate's left-hand side.
  /// - Returns: A predicate expression.
  public func and(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: self, operator: "AND", rhs: other)
  }

  /// Returns a logical OR operation on two predicate expressions.
  ///
  /// - Parameter other: The right-hand side of the operation to this predicate's left-hand side.
  /// - Returns: A predicate expression.
  public func or(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: self, operator: "OR", rhs: other)
  }

  /// Returns a logical NOT operation on this predicate expression.
  ///
  /// - Returns: This predicate expression, negated.
  public func not() -> some QueryExpression<QueryValue> {
    UnaryOperator(operator: "NOT", base: self)
  }
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
public prefix func ! (
  expression: any QueryExpression<Bool>
) -> some QueryExpression<Bool> {
  func open(_ expression: some QueryExpression<Bool>) -> SQLQueryExpression<Bool> {
    SQLQueryExpression(expression.not())
  }
  return open(expression)
}

extension SQLQueryExpression<Bool> {
  public mutating func toggle() {
    self = Self(not())
  }
}

extension QueryExpression where QueryValue: Numeric {
  /// Returns a sum expression that adds two expressions.
  ///
  /// - Parameters:
  ///   - lhs: The first expression to add.
  ///   - rhs: The second expression to add.
  /// - Returns: A sum expression.
  public static func + (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "+", rhs: rhs)
  }

  /// Returns a difference expression that subtracts two expressions.
  ///
  /// - Parameters:
  ///   - lhs: The first expression to subtract.
  ///   - rhs: The second expression to subtract.
  /// - Returns: A difference expression.
  public static func - (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "-", rhs: rhs)
  }

  /// Returns a product expression that multiplies two expressions.
  ///
  /// - Parameters:
  ///   - lhs: The first expression to multiply.
  ///   - rhs: The second expression to multiply.
  /// - Returns: A product expression.
  public static func * (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "*", rhs: rhs)
  }

  /// Returns a quotient expression that divides two expressions.
  ///
  /// - Parameters:
  ///   - lhs: The first expression to divide.
  ///   - rhs: The second expression to divide.
  /// - Returns: A quotient expression.
  public static func / (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "/", rhs: rhs)
  }

  /// Returns the additive inverse of the specified expression.
  ///
  /// - Parameter expression: A numeric expression.
  /// - Returns: the additive inverse of this expression
  public static prefix func - (expression: Self) -> some QueryExpression<QueryValue> {
    UnaryOperator(operator: "-", base: expression, separator: "")
  }

  /// Returns the additive equivalent to the specified expression.
  ///
  /// - Parameter expression: A numeric expression.
  /// - Returns: the additive equivalent to this expression
  public static prefix func + (expression: Self) -> some QueryExpression<QueryValue> {
    UnaryOperator(operator: "+", base: expression, separator: "")
  }
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
public prefix func - <QueryValue: Numeric>(
  expression: any QueryExpression<QueryValue>
) -> some QueryExpression<QueryValue> {
  func open(_ expression: some QueryExpression<QueryValue>) -> SQLQueryExpression<QueryValue> {
    SQLQueryExpression(UnaryOperator(operator: "-", base: expression, separator: ""))
  }
  return open(expression)
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
public prefix func + <QueryValue: Numeric>(
  expression: any QueryExpression<QueryValue>
) -> some QueryExpression<QueryValue> {
  func open(_ expression: some QueryExpression<QueryValue>) -> SQLQueryExpression<QueryValue> {
    SQLQueryExpression(UnaryOperator(operator: "+", base: expression, separator: ""))
  }
  return open(expression)
}

extension SQLQueryExpression where QueryValue: Numeric {
  /// Adds to a numeric expression in an update clause.
  ///
  /// - Parameters:
  ///   - lhs: The column to add to.
  ///   - rhs: The expression to add.
  public static func += (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
    lhs = Self(lhs + rhs)
  }

  /// Subtracts from a numeric expression in an update clause.
  ///
  /// - Parameters:
  ///   - lhs: The column to subtract from.
  ///   - rhs: The expression to subtract.
  public static func -= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
    lhs = Self(lhs - rhs)
  }

  /// Multiplies a numeric expression in an update clause.
  ///
  /// - Parameters:
  ///   - lhs: The column to multiply.
  ///   - rhs: The expression multiplier.
  public static func *= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
    lhs = Self(lhs * rhs)
  }

  /// Divides a numeric expression in an update clause.
  ///
  /// - Parameters:
  ///   - lhs: The column to divide.
  ///   - rhs: The expression divisor.
  public static func /= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
    lhs = Self(lhs / rhs)
  }

  /// Negates a numeric expression in an update clause.
  public mutating func negate() {
    self = Self(-self)
  }
}

extension QueryExpression where QueryValue: BinaryInteger {
  /// Returns the remainder expression of dividing the first expression by the second.
  ///
  /// - Parameters:
  ///   - lhs: The expression to divide.
  ///   - rhs: The value to divide `lhs` by.
  /// - Returns: An expression representing the remainder, or `NULL` if `rhs` is zero.
  public static func % (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue?> {
    BinaryOperator(lhs: lhs, operator: "%", rhs: rhs)
  }

  /// Returns the expression of performing a bitwise AND operation on the two given expressions.
  ///
  /// - Parameters:
  ///   - lhs: An integer expression.
  ///   - rhs: Another integer expression.
  /// - Returns: An expression representing a bitwise AND operation on the two given expressions.
  public static func & (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "&", rhs: rhs)
  }

  /// Returns the expression of performing a bitwise OR operation on the two given expressions.
  ///
  /// - Parameters:
  ///   - lhs: An integer expression.
  ///   - rhs: Another integer expression.
  /// - Returns: An expression representing a bitwise OR operation on the two given expressions.
  public static func | (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "|", rhs: rhs)
  }

  /// Returns an expression representing the result of shifting an expression's binary
  /// representation the specified expression of digits to the left.
  ///
  /// - Parameters:
  ///   - lhs: An integer expression.
  ///   - rhs: Another integer expression.
  /// - Returns: An expression representing a left bitshift operation on the two given expressions.
  public static func << (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "<<", rhs: rhs)
  }

  /// Returns an expression representing the result of shifting an expression's binary
  /// representation the specified expression of digits to the right.
  ///
  /// - Parameters:
  ///   - lhs: An integer expression.
  ///   - rhs: Another integer expression.
  /// - Returns: An expression representing a right bitshift operation on the two given expressions.
  public static func >> (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: ">>", rhs: rhs)
  }

  /// Returns the inverse expression of the bits set in the argument.
  ///
  /// - Parameter expression: An integer expression.
  /// - Returns: An expression representing the inverse bits of the given expression.
  public static prefix func ~ (expression: Self) -> some QueryExpression<QueryValue> {
    UnaryOperator(operator: "~", base: expression, separator: "")
  }
}

// NB: This overload is required due to an overload resolution bug of 'Updates[dynamicMember:]'.
@_documentation(visibility: private)
public prefix func ~ <QueryValue: BinaryInteger>(
  expression: any QueryExpression<QueryValue>
) -> some QueryExpression<QueryValue> {
  func open(_ expression: some QueryExpression<QueryValue>) -> SQLQueryExpression<QueryValue> {
    SQLQueryExpression(UnaryOperator(operator: "~", base: expression, separator: ""))
  }
  return open(expression)
}

extension SQLQueryExpression where QueryValue: BinaryInteger {
  public static func &= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
    lhs = Self(lhs & rhs)
  }

  public static func |= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
    lhs = Self(lhs | rhs)
  }

  public static func <<= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
    lhs = Self(lhs << rhs)
  }

  public static func >>= (lhs: inout Self, rhs: some QueryExpression<QueryValue>) {
    lhs = Self(lhs >> rhs)
  }
}

extension QueryExpression where QueryValue == String {
  /// Returns an expression that concatenates two string expressions.
  ///
  /// - Parameters:
  ///   - lhs: The first string expression.
  ///   - rhs: The second string expression.
  /// - Returns: An expression concatenating the first expression with the second.
  public static func + (
    lhs: Self,
    rhs: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    BinaryOperator(lhs: lhs, operator: "||", rhs: rhs)
  }

  /// Returns an expression of this expression that is compared using the given collating sequence.
  ///
  /// - Parameter collation: A collating sequence name.
  /// - Returns: An expression that is compared using the given collating sequence.
  public func collate(_ collation: Collation) -> some QueryExpression<QueryValue> {
    SQLQueryExpression("\(self) COLLATE \(collation)")
  }

  /// A predicate expression from this string expression matched against another _via_ the `GLOB`
  /// operator.
  ///
  /// ```swift
  /// Asset.where { $0.path.glob("Resources/*.png") }
  /// // SELECT … FROM "assets" WHERE ("assets"."path" GLOB 'Resources/*.png')
  /// ```
  ///
  /// - Parameter pattern: A string expression describing the `GLOB` pattern.
  /// - Returns: A predicate expression.
  public func glob(_ pattern: some StringProtocol) -> some QueryExpression<Bool> {
    BinaryOperator(lhs: self, operator: "GLOB", rhs: "\(pattern)")
  }

  /// A predicate expression from this string expression matched against another _via_ the `LIKE`
  /// operator.
  ///
  /// ```swift
  /// Reminder.where { $0.title.like("%get%") }
  /// // SELECT … FROM "reminders" WHERE ("reminders"."title" LIKE '%get%')
  /// ```
  ///
  /// - Parameters
  ///   - pattern: A string expression describing the `LIKE` pattern.
  ///   - escape: An optional character for the `ESCAPE` clause.
  /// - Returns: A predicate expression.
  public func like(
    _ pattern: some StringProtocol,
    escape: Character? = nil
  ) -> some QueryExpression<Bool> {
    LikeOperator(string: self, pattern: "\(pattern)", escape: escape)
  }

  /// A predicate expression from this string expression matched against another _via_ the `LIKE`
  /// operator given a prefix.
  ///
  /// ```swift
  /// Reminder.where { $0.title.hasPrefix("get") }
  /// // SELECT … FROM "reminders" WHERE ("reminders"."title" LIKE 'get%')
  /// ```
  ///
  /// - Parameter other: A string expression describing the prefix.
  /// - Returns: A predicate expression.
  public func hasPrefix(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    like("\(other)%")
  }

  /// A predicate expression from this string expression matched against another _via_ the `LIKE`
  /// operator given a suffix.
  ///
  /// ```swift
  /// Reminder.where { $0.title.hasSuffix("get") }
  /// // SELECT … FROM "reminders" WHERE ("reminders"."title" LIKE '%get')
  /// ```
  ///
  /// - Parameter other: A string expression describing the suffix.
  /// - Returns: A predicate expression.
  public func hasSuffix(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    like("%\(other)")
  }

  /// A predicate expression from this string expression matched against another _via_ the `LIKE`
  /// operator given an infix.
  ///
  /// ```swift
  /// Reminder.where { $0.title.contains("get") }
  /// // SELECT … FROM "reminders" WHERE ("reminders"."title" LIKE '%get%')
  /// ```
  ///
  /// - Parameter other: A string expression describing the infix.
  /// - Returns: A predicate expression.
  @_disfavoredOverload
  public func contains(_ other: some StringProtocol) -> some QueryExpression<Bool> {
    like("%\(other)%")
  }
}

extension SQLQueryExpression<String> {
  /// Appends a string expression in an update clause.
  ///
  /// Can be used in an `UPDATE` clause to append an existing column:
  ///
  /// ```swift
  /// Reminder.update { $0.title += " 2" }
  /// // UPDATE "reminders" SET "title" = ("reminders"."title" || " 2")
  /// ```
  ///
  /// - Parameters:
  ///   - lhs: The column to append.
  ///   - rhs: The appended text.
  public static func += (
    lhs: inout Self,
    rhs: some QueryExpression<QueryValue>
  ) {
    lhs = Self(lhs + rhs)
  }

  /// Appends this string expression in an update clause.
  ///
  /// An alias for ``+=(_:_:)``.
  ///
  /// - Parameters other: The text to append.
  public mutating func append(_ other: some QueryExpression<QueryValue>) {
    self += other
  }

  /// Appends this string expression in an update clause.
  ///
  /// An alias for ``+=(_:_:)``.
  ///
  /// - Parameters other: The text to append.
  public mutating func append(contentsOf other: some QueryExpression<QueryValue>) {
    self += other
  }
}

extension QueryExpression where QueryValue: QueryExpression {
  /// Returns a predicate expression indicating whether the expression is in a sequence.
  ///
  /// - Parameter expression: A sequence of expressions.
  /// - Returns: A predicate expression indicating whether this expression is in the given sequence
  public func `in`<S: Sequence>(_ expression: S) -> some QueryExpression<Bool>
  where S.Element: QueryExpression<QueryValue> {
    BinaryOperator(lhs: self, operator: "IN", rhs: S.Expression(elements: expression))
  }

  /// Returns a predicate expression indicating whether the expression is in a subquery.
  ///
  /// - Parameter query: A subquery.
  /// - Returns: A predicate expression indicating whether this expression is in the given subquery.
  public func `in`(_ query: some Statement<QueryValue>) -> some QueryExpression<Bool> {
    BinaryOperator(
      lhs: self,
      operator: "IN",
      rhs: SQLQueryExpression("(\(query.query))", as: Void.self)
    )
  }

  /// Returns a predicate expression indicating whether the expression is between a lower and upper
  /// bound.
  ///
  /// - Parameters:
  ///   - lowerBound: An expression representing the lower bound.
  ///   - upperBound: An expression representing the upper bound.
  /// - Returns: A predicate expression indicating whether this expression is between the given
  ///   bounds.
  public func between(
    _ lowerBound: some QueryExpression<QueryValue>,
    and upperBound: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    SQLQueryExpression("\(self) BETWEEN \(lowerBound) AND \(upperBound)")
  }
}

extension Sequence where Element: QueryBindable {
  /// Returns a predicate expression indicating whether the sequence contains the given expression.
  ///
  /// An alias for ``QueryExpression/in(_:)``, flipped.
  ///
  /// - Parameter element: An element.
  /// - Returns: A predicate expression indicating whether the expression is in this sequence
  public func contains(
    _ element: some QueryExpression<Element.QueryValue>
  ) -> some QueryExpression<Bool> {
    element.in(self)
  }
}

extension ClosedRange where Bound: QueryBindable {
  /// Returns a predicate expression indicating whether the given expression is contained within
  /// this range.
  ///
  /// An alias for ``QueryExpression/between(_:and:)``, flipped.
  ///
  /// - Parameter element: An element.
  /// - Returns: A predicate expression indicating whether the given element is between this range's
  ///   bounds.
  public func contains(
    _ element: some QueryExpression<Bound.QueryValue>
  ) -> some QueryExpression<Bool> {
    element.between(lowerBound, and: upperBound)
  }
}

extension Statement where QueryValue: QueryBindable {
  /// Returns a predicate expression indicating whether this subquery contains the given element.
  ///
  /// An alias for ``QueryExpression/in(_:)``, flipped.
  ///
  /// - Parameter element: An element.
  /// - Returns: A predicate expression indicating whether this expression is in the given subquery.
  public func contains(
    _ element: some QueryExpression<QueryValue>
  ) -> some QueryExpression<Bool> {
    element.in(self)
  }
}

extension PartialSelectStatement {
  /// Returns a predicate expression indicating whether this subquery contains any element.
  ///
  /// - Returns: A predicate expression indicating whether this subquery contains any element.
  public func exists() -> some QueryExpression<Bool> {
    SQLQueryExpression("EXISTS \(self.queryFragment)")
  }
}

extension Table {
  /// Returns a predicate expression indicating whether this table contains any element.
  ///
  /// - Returns: A predicate expression indicating whether this subquery contains any element.
  public static func exists() -> some QueryExpression<Bool> {
    all.exists()
  }
}

private struct UnaryOperator<QueryValue>: QueryExpression {
  let `operator`: QueryFragment
  let base: QueryFragment
  let separator: QueryFragment

  init(operator: QueryFragment, base: some QueryExpression, separator: QueryFragment = " ") {
    self.operator = `operator`
    self.base = base.queryFragment
    self.separator = separator
  }

  var queryFragment: QueryFragment {
    "\(`operator`)\(separator)(\(base))"
  }
}

struct BinaryOperator<QueryValue>: QueryExpression {
  let lhs: QueryFragment
  let `operator`: QueryFragment
  let rhs: QueryFragment

  init(
    lhs: some QueryExpression,
    operator: QueryFragment,
    rhs: some QueryExpression
  ) {
    self.lhs = lhs.queryFragment
    self.operator = `operator`
    self.rhs = rhs.queryFragment
  }

  var queryFragment: QueryFragment {
    "(\(lhs)) \(`operator`) (\(rhs))"
  }
}

private struct LikeOperator<
  LHS: QueryExpression<String>,
  RHS: QueryExpression<String>
>: QueryExpression {
  typealias QueryValue = Bool

  let string: LHS
  let pattern: RHS
  let escape: Character?

  var queryFragment: QueryFragment {
    var query: QueryFragment = "(\(string.queryFragment) LIKE \(pattern.queryFragment)"
    if let escape {
      query.append(" ESCAPE \(bind: String(escape))")
    }
    query.append(")")
    return query
  }
}

extension Sequence where Element: QueryExpression, Element.QueryValue: QueryExpression {
  fileprivate typealias Expression = _SequenceExpression<Self>
}

private struct _SequenceExpression<S: Sequence>: QueryExpression
where S.Element: QueryExpression, S.Element.QueryValue: QueryExpression {
  typealias QueryValue = S
  let queryFragment: QueryFragment
  init(elements: S) {
    queryFragment = elements.map { "(\($0.queryFragment))" }.joined(separator: ", ")
  }
}
