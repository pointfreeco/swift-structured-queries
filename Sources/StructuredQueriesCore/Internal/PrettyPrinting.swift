import Foundation
import IssueReporting

extension QueryFragment {
  @inlinable
  @inline(__always)
  package static var newlineOrSpace: Self {
    #if DEBUG
      return isTesting ? "\n" : " "
    #else
      return " "
    #endif
  }

  @inlinable
  @inline(__always)
  package static var newline: Self {
    #if DEBUG
      return isTesting ? "\n" : ""
    #else
      return ""
    #endif
  }

  #if !DEBUG
    @inlinable
    @inline(__always)
  #endif
  package func indented() -> Self {
    #if DEBUG
      guard isTesting else { return self }
      var query = self
      query.segments.insert(.sql("  "), at: 0)
      for index in query.segments.indices {
        switch query.segments[index] {
        case .sql(let sql):
          query.segments[index] = .sql(sql.replacingOccurrences(of: "\n", with: "\n  "))
        case .binding:
          continue
        }
      }
      return query
    #else
      return self
    #endif
  }
}
