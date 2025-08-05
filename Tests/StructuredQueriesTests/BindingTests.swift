import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing

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
        ('\u{07AD}��ޭ��ޭ��ޭ��', '', <invalid: The operation couldn’t be completed. (StructuredQueriesCore.OverflowError error 1.)>)
        RETURNING "id", "name", "duration"
        """#
      } results: {
        """
        The operation couldn’t be completed. (StructuredQueriesCore.OverflowError error 1.)
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
        SELECT ('00000000-0000-0000-0000-000000000000' IN ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002'))
        """
      } results: {
        """
        ┌───────┐
        │ false │
        └───────┘
        """
      }
    }

    @Test func decimals() throws {
      assertQuery(
        SimpleSelect {
          Decimal(123.45).in([Decimal(100), Decimal(200)])
        }
      ) {
        """
        SELECT ('123.45' IN ('100', '200'))
        """
      } results: {
        """
        ┌───────┐
        │ false │
        └───────┘
        """
      }
    }

    @Test func decimalPrecision() throws {
      assertQuery(
        SimpleSelect {
          Decimal(string: "123.456789")!
        }
      ) {
        """
        SELECT '123.456789'
        """
      } results: {
        """
        ┌─────────────┐
        │ 123.456789  │
        └─────────────┘
        """
      }
    }

    @Test func decimalZero() throws {
      assertQuery(
        SimpleSelect {
          Decimal.zero
        }
      ) {
        """
        SELECT '0'
        """
      } results: {
        """
        ┌───┐
        │ 0 │
        └───┘
        """
      }
    }

    @Test func decimalNegative() throws {
      assertQuery(
        SimpleSelect {
          Decimal(string: "-999.123")!
        }
      ) {
        """
        SELECT '-999.123'
        """
      } results: {
        """
        ┌──────────┐
        │ -999.123 │
        └──────────┘
        """
      }
    }

    @Test func decimalHighPrecision() throws {
      assertQuery(
        SimpleSelect {
          Decimal(string: "123456789012345678901234567890.123456789")!
        }
      ) {
        """
        SELECT '123456789012345678901234567890.123456789'
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ 123456789012345678901234567890.123456789    │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @Test func decimalRepeatingFraction() throws {
      assertQuery(
        SimpleSelect {
          Decimal(string: "0.333333333333333333333333333333333333")!
        }
      ) {
        """
        SELECT '0.333333333333333333333333333333333333'
        """
      } results: {
        """
        ┌────────────────────────────────────────┐
        │ 0.333333333333333333333333333333333333 │
        └────────────────────────────────────────┘
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
