import CompilationTesting
import SnapshotTesting
import Testing

@Suite(
  .compilation(
    mode: .main,
    imports: ["StructuredQueriesSQLite"],
    record: .failed
  )
)
struct BaseSuite {}
