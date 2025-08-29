import StructuredQueriesSQLiteCore

@attached(peer, names: overloaded, prefixed(`$`))
public macro DatabaseFunction(
  _ name: String = "",
  isDeterministic: Bool = false
) =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "DatabaseFunctionMacro"
  )
