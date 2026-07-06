import SnapshotTesting
import Testing

@MainActor @Suite(.serialized, .snapshots(record: .missing)) struct SnapshotTests {}
