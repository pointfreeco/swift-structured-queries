/// A type representing a database function.
///
/// Don't conform to this protocol directly. Instead, use the `@DatabaseFunction` macro to generate
/// a conformance.
public protocol DatabaseFunction {
  /// The name of the function.
  var name: String { get }

  /// The number of arguments the function accepts.
  var argumentCount: Int? { get }

  /// Whether or not the function is deterministic (or "pure" or "referentially transparent"),
  /// _i.e._ given an input it will always return the same output.
  var isDeterministic: Bool { get }
}

public protocol ScalarDatabaseFunction: DatabaseFunction {
  /// The function body. Transforms an array of bindings handed to the function into a binding
  /// returned to the query.
  ///
  /// - Parameter arguments: Arguments passed to the database function.
  /// - Returns: A value returned from the database function.
  func invoke(_ arguments: [QueryBinding]) -> QueryBinding
}
