import StructuredQueriesCore

/// A wrapper type for storing Boolean values as integers in SQLite.
///
/// SQLite does not have a native BOOLEAN type. Boolean values are typically stored
/// as INTEGER with 0 representing false and 1 representing true.
///
/// Example:
/// ```swift
/// @Table
/// struct User {
///   let id: Int
///   let name: String
///   @Column(as: BoolAsInt.self)
///   var isActive: Bool
/// }
/// ```
public struct BoolAsInt: QueryRepresentable {
  public var queryOutput: Bool
  
  public init(queryOutput: Bool) {
    self.queryOutput = queryOutput
  }
  
  public init(_ value: Bool) {
    self.queryOutput = value
  }
}

extension BoolAsInt: QueryBindable {
  public var queryBinding: some QueryBinding {
    IntBinding(Int64(queryOutput ? 1 : 0))
  }
}

extension BoolAsInt: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    let intValue = try Int(decoder: &decoder)
    self.queryOutput = intValue != 0
  }
}

extension BoolAsInt: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    Int.typeAffinity
  }
}

// Convenience extensions for working with BoolAsInt
extension BoolAsInt {
  /// Creates a BoolAsInt from an integer value.
  /// - Parameter value: An integer where 0 is false and non-zero is true.
  public init(intValue: Int) {
    self.queryOutput = intValue != 0
  }
  
  /// Returns the integer representation of the boolean value.
  public var intValue: Int {
    queryOutput ? 1 : 0
  }
}

// Optional support
extension Optional where Wrapped == Bool {
  public typealias AsInt = BoolAsInt?
}