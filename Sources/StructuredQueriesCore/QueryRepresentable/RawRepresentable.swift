/// A query expression that represents a `RawRepresentable` type by its `RawValue`.
///
/// Simple data types conforming to `RawRepresentable`, like enums with a raw value, can be stored
/// in a table by conforming the type to ``QueryBindable``. If you would rather not add a
/// conformance to the type itself, you can use this representation to store it as its raw value:
///
/// ```swift
/// @Table
/// struct Reminder {
///   @Column(as: Priority.RawRepresentation.self)
///   var priority: Priority
/// }
/// enum Priority: Int {
///   case low, medium, high
/// }
/// ```
public struct _RawRepresentableRawRepresentation<QueryOutput: RawRepresentable>:
  QueryRepresentable
where QueryOutput.RawValue: QueryBindable {
  public var queryOutput: QueryOutput

  public init(queryOutput: QueryOutput) {
    self.queryOutput = queryOutput
  }
}

extension _RawRepresentableRawRepresentation: Equatable where QueryOutput: Equatable {}
extension _RawRepresentableRawRepresentation: Hashable where QueryOutput: Hashable {}
extension _RawRepresentableRawRepresentation: Sendable where QueryOutput: Sendable {}

extension RawRepresentable where RawValue: QueryBindable {
  /// A query expression representing this type by its `RawValue`.
  ///
  /// ```swift
  /// @Table
  /// struct Reminder {
  ///   @Column(as: Priority.RawRepresentation.self)
  ///   var priority: Priority
  /// }
  /// enum Priority: Int {
  ///   case low, medium, high
  /// }
  /// ```
  public typealias RawRepresentation = _RawRepresentableRawRepresentation<Self>
}

extension Optional where Wrapped: RawRepresentable, Wrapped.RawValue: QueryBindable {
  @_documentation(visibility: private)
  public typealias RawRepresentation = _RawRepresentableRawRepresentation<Wrapped>?
}

extension _RawRepresentableRawRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    queryOutput.rawValue.queryBinding
  }
}

extension _RawRepresentableRawRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    let rawValue = try QueryOutput.RawValue(decoder: &decoder)
    guard let queryOutput = QueryOutput(rawValue: rawValue)
    else { throw DataCorruptedError() }
    self.init(queryOutput: queryOutput)
  }
}
