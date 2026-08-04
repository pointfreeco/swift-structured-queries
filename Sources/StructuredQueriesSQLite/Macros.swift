public import StructuredQueriesCore
import StructuredQueriesSQLiteCore

/// Defines and implements a conformance to the ``/StructuredQueriesSQLiteCore/DatabaseCollation``
/// protocol.
///
/// - Parameters
///   - name: The collating sequence's name. Defaults to the name of the function the macro is
///     applied to.
@attached(peer, names: overloaded, prefixed(`$`))
public macro DatabaseCollation(_ name: String = "") =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "DatabaseCollationMacro"
  )

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
  as representableFunctionType: ((any Sequence<(repeat each T)>) -> R).Type,
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
  as representableFunctionType: ((any Sequence<(repeat each T)>) -> Void).Type,
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
///   - representableType: The function output as represented in a query.
///   - isDeterministic: Whether or not the function is deterministic (or "pure" or "referentially
///     transparent"), _i.e._ given an input it will always return the same output.
@attached(peer, names: overloaded, prefixed(`$`))
public macro DatabaseFunction<R: QueryBindable>(
  _ name: String = "",
  as representableType: R.Type,
  isDeterministic: Bool = false
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "DatabaseFunctionMacro"
  )

@_documentation(visibility: private)
@freestanding(declaration)
public macro StructuredQueriesIsolationCheck<each Input, Output>(
  collation: (repeat each Input) throws -> Output
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "IsolationCheckMacro"
  )

@_documentation(visibility: private)
@freestanding(declaration)
public macro StructuredQueriesIsolationCheck<each Input, Output>(
  collation: @MainActor (repeat each Input) throws -> Output
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "MainActorIsolationCheckMacro"
  )

@_documentation(visibility: private)
@freestanding(declaration)
public macro StructuredQueriesIsolationCheck<each Input, Output>(
  function: (repeat each Input) throws -> Output
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "IsolationCheckMacro"
  )

@_documentation(visibility: private)
@freestanding(declaration)
public macro StructuredQueriesIsolationCheck<each Input, Output>(
  function: @MainActor (repeat each Input) throws -> Output
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "MainActorIsolationCheckMacro"
  )

@_documentation(visibility: private)
@freestanding(declaration)
public macro StructuredQueriesIsolationCheck(
  property: () -> Void
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "IsolationCheckMacro"
  )

@_documentation(visibility: private)
@freestanding(declaration)
public macro StructuredQueriesIsolationCheck(
  property: @MainActor () -> Void
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "MainActorIsolationCheckMacro"
  )
