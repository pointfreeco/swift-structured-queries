public protocol PartialSelectStatement<QueryValue>: Statement {}

/// A type representing a `SELECT` statement for a table.
public protocol SelectStatement<QueryValue, From, Joins>: PartialSelectStatement
where From: Table {
  /// Creates a ``Select`` statement from this statement.
  ///
  /// - Returns: A select statement.
  func asSelect() -> Select<QueryValue, From, Joins>

  var _selectClauses: _SelectClauses { get }
}

extension SelectStatement {
  public func asSelect() -> Select<QueryValue, From, Joins> {
    Select(clauses: _selectClauses)
  }

  public var _selectClauses: _SelectClauses {
    asSelect().clauses
  }

  /// Explicitly selects all columns and tables from this statement.
  ///
  /// - Returns: A select statement.
  public func selectStar<each J: Table>() -> Select<(From, repeat each J), From, Joins>
  where Joins == (repeat each J) {
    var select = Select<(From, repeat each J), From, Joins>()
    select.clauses = asSelect().clauses
    return select
  }
}

public typealias SelectStatementOf<From: Table, each Join: Table> =
  SelectStatement<(), From, (repeat each Join)>

extension SelectStatement {
  public static func `where`<From>(
    _ predicate: (From.TableColumns) -> some QueryExpression<some _OptionalPromotable<Bool?>>
  ) -> Self
  where Self == Where<From> {
    Self(predicates: [predicate(From.columns).queryFragment])
  }
}

// NB: https://sqlite.org/lang_upsert.html#parsing_ambiguity
protocol HasUpsertParsingAmbiguity {
  var hasUpsertParsingAmbiguity: Bool { get }
}

extension HasUpsertParsingAmbiguity where Self: SelectStatement {
  var hasUpsertParsingAmbiguity: Bool {
    _selectClauses.hasUpsertParsingAmbiguity
  }
}

extension Select: HasUpsertParsingAmbiguity {}
extension Where: HasUpsertParsingAmbiguity {}

extension _SelectClauses {
  var hasUpsertParsingAmbiguity: Bool {
    !isEmpty
      && joins.isEmpty
      && `where`.isEmpty
      && group.isEmpty
      && having.isEmpty
      && order.isEmpty
      && limit == nil
  }
}
