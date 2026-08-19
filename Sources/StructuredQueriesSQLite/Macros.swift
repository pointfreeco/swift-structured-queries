public import StructuredQueriesCore
import StructuredQueriesSQLiteCore

/// Defines collating sequences with leading dot syntax.
///
/// Apply this macro to an `extension Collation where Self == CustomCollation` containing static
/// functions that implement collating sequences:
///
/// ```swift
/// @DatabaseCollations
/// extension Collation where Self == CustomCollation {
///   static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
///     CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
///   }
/// }
/// ```
///
/// For each such function, the macro generates a static property of the same name whose value can
/// be installed in a database connection and referenced from a query, both using leading dot
/// syntax:
///
/// ```swift
/// db.install(.caseInsensitive)
///
/// Reminder.order { $0.title.collate(.caseInsensitive) }
/// // SELECT … FROM "reminders"
/// // ORDER BY "reminders"."title" COLLATE "caseInsensitive"
/// ```
@attached(member, names: arbitrary)
public macro DatabaseCollations() =
  #externalMacro(
    module: "StructuredQueriesSQLiteMacros",
    type: "DatabaseCollationsMacro"
  )

/// Renames a collating sequence defined in a ``DatabaseCollations()`` extension.
///
/// By default, a collating sequence's name in SQL is the name of the Swift function that
/// implements it. Apply this attribute to the function to reference it by a different name in SQL:
///
/// ```swift
/// @DatabaseCollations
/// extension Collation where Self == CustomCollation {
///   @DatabaseCollation("case_insensitive")
///   static func caseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
///     CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
///   }
/// }
///
/// Reminder.order { $0.title.collate(.caseInsensitive) }
/// // SELECT … FROM "reminders"
/// // ORDER BY "reminders"."title" COLLATE "case_insensitive"
/// ```
///
/// - Parameters
///   - name: The collating sequence's name. Defaults to the name of the function the attribute is
///     applied to.
@attached(peer)
public macro DatabaseCollation(_ name: String) =
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
