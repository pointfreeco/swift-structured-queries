import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

extension SnapshotTests {
  @Suite struct BindingTests {
    @Dependency(\.defaultDatabase) var db
    init() throws {
      try db.execute(
        """
        CREATE TABLE records (id BLOB PRIMARY KEY, name TEXT, duration INTEGER);
        """
      )
    }

    @Test func bytes() throws {
      assertQuery(
        Record.insert {
          Record.Draft(
            id: UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef"),
            name: "Blob"
          )
        }
        .returning(\.self)
      ) {
        #"""
        INSERT INTO "records"
        ("id", "name", "duration")
        VALUES
        ('\u{07AD}��ޭ��ޭ��ޭ��', 'Blob', 0)
        RETURNING "id", "name", "duration"
        """#
      } results: {
        """
        ┌───────────────────────────────────────────────────┐
        │ Record(                                           │
        │   id: UUID(DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF), │
        │   name: "Blob",                                   │
        │   duration: 0                                     │
        │ )                                                 │
        └───────────────────────────────────────────────────┘
        """
      }
    }

    @Test func overflow() throws {
      assertQuery(
        Record.insert {
          Record.Draft(
            id: UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef"),
            duration: UInt64.max
          )
        }
        .returning(\.self)
      ) {
        #"""
        INSERT INTO "records"
        ("id", "name", "duration")
        VALUES
        ('\u{07AD}��ޭ��ޭ��ޭ��', '', 18446744073709551615)
        RETURNING "id", "name", "duration"
        """#
      } results: {
        """
        The operation couldn’t be completed. (_StructuredQueriesSQLite.Int64OverflowError error 1.)
        """
      }
    }

    @Test func uuids() throws {
      assertQuery(
        SimpleSelect {
          UUID(0).in([UUID(1), UUID(2)])
        }
      ) {
        """
        SELECT ('00000000-0000-0000-0000-000000000000') IN (('00000000-0000-0000-0000-000000000001'), ('00000000-0000-0000-0000-000000000002'))
        """
      } results: {
        """
        ┌───────┐
        │ false │
        └───────┘
        """
      }
    }
  }
}

@Table
private struct Record: Equatable {
  @Column(as: UUID.BytesRepresentation.self)
  var id: UUID
  var name = ""
  var duration: UInt64 = 0
}
