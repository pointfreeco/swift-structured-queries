import CompilationTesting
import SnapshotTesting
import Testing

@Suite(
  .compilation(
    mode: .main,
    imports: ["StructuredQueriesSQLite"]
  ),
  .snapshots(record: .failed)
)
struct BaseSuite {}
