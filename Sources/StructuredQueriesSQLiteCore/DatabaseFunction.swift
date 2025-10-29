/// A type representing a database function.
///
/// Don't conform to this protocol directly. Instead, use the
/// [`@DatabaseFunction`](<doc:CustomFunctions>) macro to generate a conformance.
public protocol DatabaseFunction<Input, Output> {
  /// A type representing the function's arguments.
  associatedtype Input

  /// A type representing the function's return value.
  associatedtype Output

  /// The name of the function.
  var name: String { get }

  /// The number of arguments the function accepts.
  var argumentCount: Int? { get }

  /// Whether or not the function is deterministic (or "pure" or "referentially transparent"),
  /// _i.e._ given an input it will always return the same output.
  var isDeterministic: Bool { get }
}

/// A type representing a scalar database function.
///
/// Don't conform to this protocol directly. Instead, use the
/// [`@DatabaseFunction`](<doc:CustomFunctions#Scalar-functions>) macro to generate a conformance.
public protocol ScalarDatabaseFunction<Input, Output>: DatabaseFunction {
  /// The function body. Uses a query decoder to process the input of a database function into a
  /// bindable value.
  ///
  /// - Parameter decoder: A query decoder.
  /// - Returns: A binding returned from the database function.
  func invoke(_ decoder: inout some QueryDecoder) throws -> QueryBinding
}

extension ScalarDatabaseFunction {
  /// A function call expression.
  ///
  /// - Parameter input: Expressions representing the arguments of the function.
  /// - Returns: An expression representing the function call.
  @_disfavoredOverload
  public func callAsFunction<each T: QueryExpression>(
    _ input: repeat each T
  ) -> some QueryExpression<Output>
  where Input == (repeat (each T).QueryValue) {
    $_isSelecting.withValue(false) {
      SQLQueryExpression(
        "\(quote: name)(\(Array(repeat each input).joined(separator: ", ")))"
      )
    }
  }
}

/// A type representing an aggregate database function.
///
/// Don't conform to this protocol directly. Instead, use the
/// [`@DatabaseFunction`](<doc:CustomFunctions#Aggregate-functions>) macro to generate a
/// conformance.
public protocol AggregateDatabaseFunction<Input, Output>: DatabaseFunction {
  /// A type representing one row of input to the aggregate function.
  associatedtype Element = Input

  /// Decodes a row into an element to aggregate a result from.
  ///
  /// - Parameter decoder: A query decoder.
  /// - Returns: An element to append to the sequence sent to the aggregate function.
  func step(_ decoder: inout some QueryDecoder) throws -> Element

  /// Aggregates elements into a bindable value.
  ///
  /// - Parameter arguments: A sequence of elements to aggregate from.
  /// - Returns: A binding returned from the aggregate function.
  func invoke(_ arguments: some Sequence<Element>) throws -> QueryBinding
}

extension AggregateDatabaseFunction {
  /// An aggregate function call expression.
  ///
  /// - Parameters
  ///   - input: Expressions representing the arguments of the function.
  ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
  ///     the aggregation.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: An expression representing the function call.
  @_disfavoredOverload
  public func callAsFunction(
    _ input: some QueryExpression<Input>,
    distinct isDistinct: Bool = false,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<Output>
  where Input: QueryBindable {
    $_isSelecting.withValue(false) {
      AggregateFunctionExpression(name, distinct: isDistinct, input, order: order, filter: filter)
    }
  }

  /// An aggregate function call expression.
  ///
  /// - Parameters
  ///   - input: Expressions representing the arguments of the function.
  ///   - order: An `ORDER BY` clause to apply to the aggregation.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: An expression representing the function call.
  @_disfavoredOverload
  public func callAsFunction<each T: QueryExpression>(
    _ input: repeat each T,
    order: (some QueryExpression)? = Bool?.none,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<Output>
  where Input == (repeat (each T).QueryValue) {
    $_isSelecting.withValue(false) {
      AggregateFunctionExpression(name, repeat each input, order: order, filter: filter)
    }
  }
}

// NB: Provides better error diagnostics for '@DatabaseFunction' macro-generated code.
//
//     - Type 'CKShare' has no member '_columnWidth'
//     + Global function '_columnWidth' requires that 'CKShare' conform to 'QueryExpression'
@_transparent
public func _columnWidth<T: QueryExpression>(_: T.Type) -> Int {
  T._columnWidth
}

// NB: Provides better error diagnostics for '@DatabaseFunction' macro-generated code.
//
//     - No exact matches in call to instance method 'decode'
//     + Global function '_requireQueryRepresentable' requires that 'CKShare' conform to 'QueryRepresentable'
@_transparent
public func _requireQueryRepresentable<T: QueryRepresentable>(_: T.Type) -> T.Type {
  T.self
}
