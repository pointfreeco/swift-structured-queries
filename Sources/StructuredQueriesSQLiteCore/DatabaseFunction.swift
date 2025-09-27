/// A type representing a database function.
///
/// Don't conform to this protocol directly. Instead, use the `@DatabaseFunction` macro to generate
/// a conformance.
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
/// Don't conform to this protocol directly. Instead, use the `@DatabaseFunction` macro to generate
/// a conformance.
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
