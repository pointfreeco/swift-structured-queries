/// A type that can convert itself into and out of an external representation.
///
/// `QueryCodable` is a type alias for the ``QueryEncodable`` and ``QueryDecodable`` protocols.
/// When you use `QueryCodable` as a type or a generic constraint, it matches any type that conforms
/// to both protocols.
public typealias QueryCodable = QueryDecodable & QueryEncodable
