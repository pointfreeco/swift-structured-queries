import StructuredQueriesSQLiteCore

/// Defines and implements a conformance to the ``/StructuredQueriesSQLiteCore/DatabaseFunction``
/// protocol.
///
/// - Parameters
///   - name: The function's name. Defaults to the name of the function the macro is applied to.
///   - isDeterministic: Whether or not the function is deterministic (or "pure" or "referentially
///     transparent"), _i.e._ given an input it will always return the same output.
@attached(peer, names: overloaded, prefixed(`$`))
public macro DatabaseFunction(
  _ name: String = "",
  isDeterministic: Bool = false
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "DatabaseFunctionMacro"
  )

/// Defines and implements a conformance to the ``/StructuredQueriesSQLiteCore/DatabaseFunction``
/// protocol.
///
/// - Parameters
///   - name: The function's name. Defaults to the name of the function the macro is applied to.
///   - representableFunctionType: The function as represented in a query.
///   - isDeterministic: Whether or not the function is deterministic (or "pure" or "referentially
///     transparent"), _i.e._ given an input it will always return the same output.
@attached(peer, names: overloaded, prefixed(`$`))
public macro DatabaseFunction<each T: QueryRepresentable & QueryExpression, R: QueryBindable>(
  _ name: String = "",
  as representableFunctionType: ((repeat each T) -> R).Type,
  isDeterministic: Bool = false
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "DatabaseFunctionMacro"
  )

/// Defines and implements a conformance to the ``/StructuredQueriesSQLiteCore/DatabaseFunction``
/// protocol.
///
/// - Parameters
///   - name: The function's name. Defaults to the name of the function the macro is applied to.
///   - representableFunctionType: The function as represented in a query.
///   - isDeterministic: Whether or not the function is deterministic (or "pure" or "referentially
///     transparent"), _i.e._ given an input it will always return the same output.
@attached(peer, names: overloaded, prefixed(`$`))
public macro DatabaseFunction<each T: QueryRepresentable & QueryExpression>(
  _ name: String = "",
  as representableFunctionType: ((repeat each T) -> Void).Type,
  isDeterministic: Bool = false
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "DatabaseFunctionMacro"
  )
