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
