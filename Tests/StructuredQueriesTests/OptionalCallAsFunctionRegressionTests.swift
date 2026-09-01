import StructuredQueriesSQLite
import Testing

// A stand-in for the part of CasePaths that participates in the crash: `Optional` conforms to a
// protocol whose extension vends `subscript(dynamicMember:)`, and its nested cases type is itself
// `@dynamicMemberLookup`. (StructuredQueries can't import CasePaths here without the trait.)
private protocol StandInCasePathable { associatedtype StandInCases }
private struct StandInCasePath<Root, Value> {}
extension StandInCasePathable {
  fileprivate subscript<V>(
    dynamicMember keyPath: KeyPath<StandInCases, StandInCasePath<Self, V>>
  ) -> V? { nil }
}
extension Optional: StandInCasePathable {
  @dynamicMemberLookup
  fileprivate struct StandInCases {
    subscript<M>(
      dynamicMember keyPath: KeyPath<Wrapped.StandInCases, StandInCasePath<Wrapped, M>>
    ) -> StandInCasePath<Optional, M?>
    where Wrapped: StandInCasePathable { .init() }
  }
}

@Suite struct OptionalCallAsFunctionRegressionTests {
  // When `Optional` picked up `callAsFunction(_:)` from `QueryExpression` (0.37.0–0.39.1), this
  // ordinary expression crashed the Swift 6.3 type checker with
  // "Assertion failed: (inserted), function recordAppliedDisjunction" in any module that also
  // imported CasePaths. Compiling this file is the test.
  @Test func trailingClosureOnFirstOfOverloadedReceiverCompiles() {
    func commonPrefixLength(_ a: [String], _ b: [String]) -> Int {
      let common = min(a.count, b.count)
      return (0..<common).first { a[$0] != b[$0] } ?? common
    }
    #expect(commonPrefixLength(["a", "b"], ["a", "c"]) == 1)
    #expect([1].first { _ in true } == 1)
  }
}
