import Foundation
public import StructuredQueriesCore

#if !SuppressPlatformSQLiteAvailability
  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
#endif
public struct _CodableJSONBRepresentation<QueryOutput: Codable>: Codable, QueryRepresentable {
  public var queryOutput: QueryOutput

  public init(queryOutput: QueryOutput) {
    self.queryOutput = queryOutput
  }

  public static func queryFragment(decoding queryFragment: QueryFragment) -> QueryFragment {
    "json(\(queryFragment))"
  }
}

#if !SuppressPlatformSQLiteAvailability
  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
#endif
extension _CodableJSONBRepresentation: Equatable where QueryOutput: Equatable {}

#if !SuppressPlatformSQLiteAvailability
  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
#endif
extension _CodableJSONBRepresentation: Hashable where QueryOutput: Hashable {}

#if !SuppressPlatformSQLiteAvailability
  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
#endif
extension _CodableJSONBRepresentation: Sendable where QueryOutput: Sendable {}

extension Decodable where Self: Encodable {
  /// A query expression representing codable JSONB.
  ///
  /// ```swift
  /// @Table
  /// struct Item {
  ///   @Column(as: [String].JSONBRepresentation.self)
  ///   var notes: [String] = []
  /// }
  ///
  /// Item.insert { $0.notes } values: { ["First post", "An update"] }
  /// // INSERT INTO "items" ("notes") VALUES (jsonb('["First post","An update"]'))
  ///
  /// Item.all
  /// // SELECT json("items"."notes") FROM "items"
  /// ```
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public typealias JSONBRepresentation = _CodableJSONBRepresentation<Self>
}

extension Optional where Wrapped: Codable {
  @_documentation(visibility: private)
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public typealias JSONBRepresentation = _CodableJSONBRepresentation<Wrapped>?
}

#if !SuppressPlatformSQLiteAvailability
  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
#endif
extension _CodableJSONBRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    do {
      return try .text(String(decoding: jsonEncoder.encode(queryOutput), as: UTF8.self))
    } catch {
      return .invalid(error)
    }
  }

  public var queryFragment: QueryFragment {
    "jsonb(\(queryBinding))"
  }
}

#if !SuppressPlatformSQLiteAvailability
  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
#endif
extension _CodableJSONBRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws(QueryDecodingError) {
    let json = try String(decoder: &decoder)
    do {
      self.init(queryOutput: try jsonDecoder.decode(QueryOutput.self, from: Data(json.utf8)))
    } catch {
      throw .other(error)
    }
  }
}

#if !SuppressPlatformSQLiteAvailability
  @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
#endif
extension _CodableJSONBRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity { .blob }
}
