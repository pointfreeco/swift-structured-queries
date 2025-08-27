import Foundation
import StructuredQueriesCore

// MARK: - Codable+JSON SQLiteType conformance
extension _CodableJSONRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}

// MARK: - Date+JulianDay SQLiteType conformance
extension Date.JulianDayRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    Double.typeAffinity
  }
}

// MARK: - Date+UnixTime SQLiteType conformance
extension Date.UnixTimeRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    Int.typeAffinity
  }
}

// MARK: - UUID+Bytes SQLiteType conformance
extension UUID.BytesRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    [UInt8].typeAffinity
  }
}

// MARK: - UUID+Uppercased SQLiteType conformance
extension UUID.UppercasedRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}

// MARK: - Deprecated conformances

@available(
  *,
  deprecated,
  message: "ISO-8601 text is the default representation and is no longer explicitly needed."
)
extension Date.ISO8601Representation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}

@available(
  *,
  deprecated,
  message: "Lowercased text is the default representation and is no longer explicitly needed."
)
extension UUID.LowercasedRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    String.typeAffinity
  }
}