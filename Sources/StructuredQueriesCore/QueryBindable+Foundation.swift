import Foundation

extension Data: QueryBindable {
  public var queryBinding: QueryBinding {
    .blob([UInt8](self))
  }

  public init(decoder: inout some QueryDecoder) throws {
    try self.init([UInt8](decoder: &decoder))
  }
}

extension URL: QueryBindable {
  public var queryBinding: QueryBinding {
    .text(absoluteString)
  }

  public init(decoder: inout some QueryDecoder) throws {
    guard let url = Self(string: try String(decoder: &decoder)) else {
      throw InvalidURL()
    }
    self = url
  }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *)
extension Duration {
  /// A representation of a Swift `Duration` at the precision of seconds.
  ///
  /// Any sub-second durations will be rounded down to the nearest second. 
  ///
  /// ## Usage
  /// ```swift
  /// @Table
  /// struct Event {
  ///   @Column(as: Duration.SecondsRepresentation.self)
  ///   var duration: Duration
  /// }
  /// ```
  public struct SecondsRepresentation: QueryRepresentable {
    public var queryOutput: Duration
    
    public var seconds: Int64 {
      queryOutput.components.seconds
    }
    
    public init(queryOutput: Duration) {
      self.queryOutput = queryOutput
    }
    
    public init(seconds: Int64) throws {
      self.queryOutput = Duration(secondsComponent: seconds, attosecondsComponent: 0)
    }
  }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *)
extension Duration.SecondsRepresentation: QueryBindable {
  public var queryBinding: QueryBinding {
    .int(queryOutput.components.seconds)
  }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *)
extension Duration.SecondsRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(queryOutput: Duration(
      secondsComponent: Int64(decoder: &decoder),
      attosecondsComponent: 0
    ))
  }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *)
extension Duration.SecondsRepresentation: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    Int64.typeAffinity
  }
}

private struct InvalidURL: Error {}
