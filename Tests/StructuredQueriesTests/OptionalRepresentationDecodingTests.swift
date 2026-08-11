import Dependencies
import Foundation
import StructuredQueries
import Testing
import _StructuredQueriesSQLite

@Table
private struct Item {
  let id: Int
  @Column(as: [UInt8]?.JSONRepresentation.self)
  let data: [UInt8]?
}

@Table("sqlitedata_icloud_metadata")
private struct SyncMetadata {
  @Selection
  struct ID: Hashable {
    let recordPrimaryKey: String
    let recordType: String
  }

  let id: ID
  let zoneName: String
  let ownerName: String

  @Column(generated: .virtual)
  let recordName: String

  @Selection
  struct ParentID: Hashable {
    let parentRecordPrimaryKey: String
    let parentRecordType: String
  }

  let parentRecordID: ParentID?

  @Column(generated: .virtual)
  let parentRecordName: String?

  @Column(as: [UInt8]?.JSONRepresentation.self)
  let lastKnownServerRecord: [UInt8]?

  @Column(as: [UInt8]?.JSONRepresentation.self)
  let _lastKnownServerRecordAllFields: [UInt8]?

  @Column(as: [UInt8]?.JSONRepresentation.self)
  let share: [UInt8]?

  let _isDeleted: Bool

  @Column("hasLastKnownServerRecord", generated: .virtual)
  let _hasLastKnownServerRecord: Bool

  @Column("isShared", generated: .virtual)
  let _isShared: Bool

  let userModificationTime: Int64
}

extension SnapshotTests {
  @MainActor
  @Suite(.bug("https://github.com/pointfreeco/sqlite-data/issues/493"))
  struct OptionalRepresentationDecodingTests {
    @Dependency(\.defaultDatabase) var db

    @Test func nullOptionalRepresentationColumn() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "items" (
            "id" INTEGER PRIMARY KEY,
            "data" BLOB
          )
          """
        )
      )
      try db.execute(
        #sql(
          """
          INSERT INTO "items" ("id", "data") VALUES (1, NULL), (2, '[42]')
          """
        )
      )
      let items = try db.execute(Item.all)
      #expect(items.count == 2)
      #expect(items.first?.data == nil)
      #expect(items.last?.data == [42])
    }

    @Test func syncMetadata() throws {
      try db.execute(
        #sql(
          """
          CREATE TABLE "sqlitedata_icloud_metadata" (
            "recordPrimaryKey" TEXT NOT NULL,
            "recordType" TEXT NOT NULL,
            "recordName" TEXT NOT NULL AS ("recordPrimaryKey" || ':' || "recordType"),
            "zoneName" TEXT NOT NULL,
            "ownerName" TEXT NOT NULL,
            "parentRecordPrimaryKey" TEXT,
            "parentRecordType" TEXT,
            "parentRecordName" TEXT AS ("parentRecordPrimaryKey" || ':' || "parentRecordType"),
            "lastKnownServerRecord" BLOB,
            "_lastKnownServerRecordAllFields" BLOB,
            "share" BLOB,
            "hasLastKnownServerRecord" INTEGER NOT NULL AS ("lastKnownServerRecord" IS NOT NULL),
            "isShared" INTEGER NOT NULL AS ("share" IS NOT NULL),
            "userModificationTime" INTEGER NOT NULL DEFAULT 0,
            "_isDeleted" INTEGER NOT NULL DEFAULT 0,

            PRIMARY KEY ("recordPrimaryKey", "recordType"),
            UNIQUE ("recordName")
          ) STRICT
          """
        )
      )
      try db.execute(
        #sql(
          """
          INSERT INTO "sqlitedata_icloud_metadata"
          ("recordPrimaryKey", "recordType", "zoneName", "ownerName", "userModificationTime")
          VALUES
          ('deadbeef', 'reminders', 'zone', 'owner', 42)
          """
        )
      )

      let rows = try db.execute(SyncMetadata.all)
      #expect(rows.count == 1)
      let row = try #require(rows.first)
      #expect(row.id == SyncMetadata.ID(recordPrimaryKey: "deadbeef", recordType: "reminders"))
      #expect(row.zoneName == "zone")
      #expect(row.ownerName == "owner")
      #expect(row.recordName == "deadbeef:reminders")
      #expect(row.parentRecordID == nil)
      #expect(row.parentRecordName == nil)
      #expect(row.lastKnownServerRecord == nil)
      #expect(row._lastKnownServerRecordAllFields == nil)
      #expect(row.share == nil)
      #expect(row._isDeleted == false)
      #expect(row._hasLastKnownServerRecord == false)
      #expect(row._isShared == false)
      #expect(row.userModificationTime == 42)

      let tupleRows = try db.execute(
        SyncMetadata.all.select { ($0, $0._lastKnownServerRecordAllFields) }
      )
      #expect(tupleRows.count == 1)
      let (tupleRow, allFields) = try #require(tupleRows.first)
      #expect(tupleRow.userModificationTime == 42)
      #expect(allFields == nil)
    }
  }
}
