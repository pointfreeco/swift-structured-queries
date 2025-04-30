import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing

extension SnapshotTests {
  @Suite struct CaseTests {
    @Test func dynamicCase() {
      let ids = Array([2, 3, 5, 1, 4].enumerated())
      let (first, rest) = (ids.first!, ids.dropFirst())
      assertQuery(
        Values(
          rest
            .reduce(Case(5).when(first.element, then: first.offset)) { cases, id in
              cases.when(id.element, then: id.offset)
            }
            .else(0)
        )
      ) {
        """
        SELECT CASE 5 WHEN 2 THEN 0 WHEN 3 THEN 1 WHEN 5 THEN 2 WHEN 1 THEN 3 WHEN 4 THEN 4 ELSE 0 END
        """
      } results: {
        """
        ┌───┐
        │ 2 │
        └───┘
        """
      }
    }
  }
}
