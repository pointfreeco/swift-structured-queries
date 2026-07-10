#if compiler(>=6.2)
  import Foundation
  public import StructuredQueriesCore

  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  public struct _CodableJSONBRepresentation<QueryOutput: Codable>: QueryRepresentable {
    public var queryOutput: QueryOutput

    public init(queryOutput: QueryOutput) {
      self.queryOutput = queryOutput
    }
  }

  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  extension _CodableJSONBRepresentation: Equatable where QueryOutput: Equatable {}

  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  extension _CodableJSONBRepresentation: Hashable where QueryOutput: Hashable {}

  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  extension _CodableJSONBRepresentation: Sendable where QueryOutput: Sendable {}

  extension Decodable where Self: Encodable {
    /// A query expression representing codable JSON stored in SQLite's binary JSONB format.
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
    /// ```
    ///
    /// Values are encoded to JSON text and passed through the `jsonb` function when they are bound
    /// to a statement, so SQLite stores its canonical binary representation in a `BLOB` column.
    /// Values are decoded directly from the binary representation, with a fallback to JSON text
    /// for columns that contain text, _e.g._ rows written before a migration from
    /// ``Swift/Decodable/JSONRepresentation``, or the text results of SQLite's `json_*` functions.
    ///
    /// > Important: The JSONB format requires SQLite 3.45.0 or higher, which is always satisfied
    /// > by the SQLite that ships with the OS versions this API is available on, but may be
    /// > relevant if you bundle your own copy of SQLite.
    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    public typealias JSONBRepresentation = _CodableJSONBRepresentation<Self>
  }

  extension Optional where Wrapped: Codable {
    @_documentation(visibility: private)
    @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
    public typealias JSONBRepresentation = _CodableJSONBRepresentation<Wrapped>?
  }

  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  extension _CodableJSONBRepresentation: QueryBindable {
    public var queryBinding: QueryBinding {
      _CodableJSONRepresentation(queryOutput: queryOutput).queryBinding
    }

    public var queryFragment: QueryFragment {
      "jsonb(\(queryBinding))"
    }
  }

  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  extension _CodableJSONBRepresentation: QueryDecodable {
    public init(decoder: inout some QueryDecoder) throws {
      guard let blob = try decoder.decode([UInt8].self)
      else { throw QueryDecodingError.missingRequiredColumn }
      let json: Data
      do {
        json = Data(try JSONB.json(from: blob.span))
      } catch {
        json = Data(blob)
      }
      self.init(queryOutput: try _CodableJSONRepresentation(json: json).queryOutput)
    }
  }

  @available(iOS 26, macOS 26, tvOS 26, visionOS 26, watchOS 26, *)
  extension _CodableJSONBRepresentation: SQLiteType {
    public static var typeAffinity: SQLiteTypeAffinity {
      .blob
    }
  }
#endif
