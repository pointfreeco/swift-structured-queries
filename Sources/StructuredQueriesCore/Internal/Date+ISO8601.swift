public import Foundation

extension Date {
  package var iso8601String: String {
    formatted(.iso8601.currentTimestamp(includingFractionalSeconds: true))
  }
}

extension Date {
  @usableFromInline
  package init(iso8601String: String) throws {
    do {
      try self.init(
        iso8601String.queryOutput,
        strategy: .iso8601.currentTimestamp(includingFractionalSeconds: true)
      )
    } catch {
      try self.init(
        iso8601String.queryOutput,
        strategy: .iso8601.currentTimestamp(includingFractionalSeconds: false)
      )
    }
  }
}

extension Date.ISO8601FormatStyle {
  fileprivate func currentTimestamp(includingFractionalSeconds: Bool) -> Self {
    year().month().day()
      .dateTimeSeparator(.space)
      .time(includingFractionalSeconds: includingFractionalSeconds)
  }
}
