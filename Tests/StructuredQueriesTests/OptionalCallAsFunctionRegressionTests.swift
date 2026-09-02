#if CasePaths
  import CasePaths
  import StructuredQueriesSQLite
  import Testing

  @Suite struct OptionalCallAsFunctionRegressionTests {
    @Test func trailingClosureOnOverloadedFirstTypeChecksAlongsideCasePaths() {
      let a = ["a", "b"]
      let b = ["a", "c"]
      #expect((0..<min(a.count, b.count)).first { a[$0] != b[$0] } == 1)
      #expect([1].first { _ in true } == 1)
    }
  }
#endif
