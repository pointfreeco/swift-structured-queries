import Foundation

/// A query expression representing codable JSON.
///
/// ```swift
/// @Table
/// struct Item {
///   @Column(as: JSONRepresentation<[String]>.self)
///   var notes: [String] = []
/// }
///
/// Item.insert { $0.notes } values: { ["First post", "An update"] }
/// // INSERT INTO "items" ("notes") VALUES ('["First post","An update"]')
/// ```
public struct JSONRepresentation<QueryOutput: Codable & Sendable>: QueryRepresentable {
  public var queryOutput: QueryOutput

  public init(queryOutput: QueryOutput) {
    self.queryOutput = queryOutput
  }

  public init(decoder: inout some QueryDecoder) throws {
    self.init(
      queryOutput: try jsonDecoder.decode(
        QueryOutput.self,
        from: Data(String(decoder: &decoder).utf8)
      )
    )
  }
}

private let jsonDecoder: JSONDecoder = {
  var decoder = JSONDecoder()
  var formatter = DateFormatter.init()
  formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
  decoder.dateDecodingStrategy = .formatted(formatter)
  return decoder
}()

extension JSONRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    do {
      return try .text(String(decoding: JSONEncoder().encode(queryOutput), as: UTF8.self))
    } catch {
      return .invalid(error)
    }
  }
}

extension JSONRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}
