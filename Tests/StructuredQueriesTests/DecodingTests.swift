import Foundation
import StructuredQueries
import StructuredQueriesSQLite
import Testing

extension SnapshotTests {
  struct DecodingTests {
    let db: Database

    init() throws {
      db = try Database()
    }

    @Test func basics() throws {
      #expect(try db.execute(SimpleSelect { #sql("0", as: Bool.self) }).first == false)
      #expect(try db.execute(SimpleSelect { #sql("1", as: Bool.self) }).first == true)
      #expect(try db.execute(SimpleSelect { #sql("2", as: Int.self) }).first == 2)
      #expect(try db.execute(SimpleSelect { #sql("3", as: Int8.self) }).first == Int8(3))
      #expect(try db.execute(SimpleSelect { #sql("4", as: Int16.self) }).first == Int16(4))
      #expect(try db.execute(SimpleSelect { #sql("5", as: Int32.self) }).first == Int32(5))
      #expect(try db.execute(SimpleSelect { #sql("6", as: Int64.self) }).first == Int64(6))
      #expect(try db.execute(SimpleSelect { #sql("7", as: UInt8.self) }).first == UInt8(7))
      #expect(try db.execute(SimpleSelect { #sql("8", as: UInt16.self) }).first == UInt16(8))
      #expect(try db.execute(SimpleSelect { #sql("9", as: UInt32.self) }).first == UInt32(9))
      #expect(try db.execute(SimpleSelect { #sql("10", as: UInt64.self) }).first == UInt64(10))
      #expect(try db.execute(SimpleSelect { #sql("11.12", as: Float.self) }).first == Float(11.12))
      #expect(try db.execute(SimpleSelect { #sql("13.14", as: Double.self) }).first == 13.14)
      #expect(try db.execute(SimpleSelect { #sql("'Blob'", as: String.self) }).first == "Blob")
    }

    @Test func blob() throws {
      let bytes = try #require(
        try db.execute(
          SimpleSelect { "deadbeef".unhex() }
        )
        .first
      )

      #expect(bytes == [0xDE, 0xAD, 0xBE, 0xEF])
    }

    @Test func losslessStringConvertible() throws {
      struct Email: Equatable, LosslessStringConvertible, QueryBindable {
        var description: String

        init?(_ description: String) {
          self.description = description
        }
      }
      #expect(
        try db.execute(
          SimpleSelect { #sql("'support@pointfree.co'", as: Email.self) }
        )
        .first == Email("support@pointfree.co")
      )
    }

    @Test func rawRepresentable() throws {
      enum Priority: Int, QueryBindable {
        case low = 1
        case medium
        case high
      }
      #expect(
        try db.execute(
          SimpleSelect { #sql("3", as: Priority.self) }
        )
        .first == .high
      )
      #expect(
        try db.execute(
          SimpleSelect { #sql("\(Priority.high)", as: Priority.self) }
        )
        .first == .high
      )
    }

    @Test func queryRepresentable() throws {
      #expect(
        try db.execute(
          SimpleSelect { #sql("'2001-01-01 00:00:00'", as: Date.self) }
        )
        .first == Date(timeIntervalSinceReferenceDate: 0)
      )
      #expect(
        try db.execute(
          SimpleSelect { #sql("1234567890", as: Date.UnixTimeRepresentation.self) }
        )
        .first == Date(timeIntervalSince1970: 1_234_567_890)
      )
      #expect(
        try db.execute(
          SimpleSelect { #sql("2451910.5", as: Date.JulianDayRepresentation.self) }
        )
        .first == Date(timeIntervalSinceReferenceDate: 0)
      )
      #expect(
        try db.execute(
          SimpleSelect {
            #sql("'deadbeef-dead-beef-dead-beefdeadbeef'", as: UUID.self)
          }
        )
        .first == UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")
      )
      #expect(
        try db.execute(
          SimpleSelect {
            #sql("'DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF'", as: UUID.UppercasedRepresentation.self)
          }
        )
        .first == UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")
      )
      #expect(
        try db.execute(
          SimpleSelect {
            "deadbeef-dead-beef-dead-beefdeadbeef".unhex("-").cast(
              as: UUID.BytesRepresentation?.self
            )
          }
        )
        .first
          == UUID(
            uuid: (
              0xDE, 0xAD, 0xBE, 0xEF,
              0xDE, 0xAD,
              0xBE, 0xEF,
              0xDE, 0xAD,
              0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF
            )
          )
      )
    }

    @Test func optionalDate() throws {
      #expect(
        try db.execute(
          SimpleSelect { #sql("NULL", as: Date?.self) }
        )
        .first == .some(.none)
      )
      #expect(
        try db.execute(
          SimpleSelect { #sql("NULL", as: Date.UnixTimeRepresentation?.self) }
        )
        .first == .some(.none)
      )
    }

    @Test func recordWithOptionalDate() throws {
      struct Record: Equatable, QueryDecodable, QueryRepresentable {
        var date: Date?
        init(date: Date?) { self.date = date }
        init(decoder: inout some QueryDecoder) throws {
          date = try decoder.decode(Date.ISO8601Representation.self)
        }
      }

      #expect(
        try db.execute(SimpleSelect { #sql("NULL", as: Record.self) })
          .first == .some(Record(date: nil))
      )
      #expect(
        try db.execute(SimpleSelect { #sql("'2001-01-01 00:00:00'", as: Record.self) })
          .first == .some(Record(date: Date(timeIntervalSinceReferenceDate: 0)))
      )
    }

    @Test func jsonCodable() throws {
      struct User: Codable {
        let id: Int
        var name: String
      }
      assertQuery(
        SimpleSelect {
          #sql(
            """
            '{"id":1,"name":"Blob"}'
            """,
            as: User.JSONRepresentation.self
          )
        }
      ) {
        """
        SELECT '{"id":1,"name":"Blob"}'
        """
      } results: {
        """
        ┌───────────────────────────────────┐
        │ SnapshotTests.DecodingTests.User( │
        │   id: 1,                          │
        │   name: "Blob"                    │
        │ )                                 │
        └───────────────────────────────────┘
        """
      }
    }

    @Test func jsonCodableCustomKeys() throws {
      struct User: Codable {
        let id: Int
        var name: String

        enum CodingKeys: String, CodingKey {
          case id = "user_id"
          case name = "user_name"
        }
      }
      assertQuery(
        SimpleSelect {
          #sql(
            """
            '{"user_id":1,"user_name":"Blob"}'
            """,
            as: User.JSONRepresentation.self
          )
        }
      ) {
        """
        SELECT '{"user_id":1,"user_name":"Blob"}'
        """
      } results: {
        """
        ┌───────────────────────────────────┐
        │ SnapshotTests.DecodingTests.User( │
        │   id: 1,                          │
        │   name: "Blob"                    │
        │ )                                 │
        └───────────────────────────────────┘
        """
      }
    }

    func compileTime() throws {
      _ = try #require(
        try db.execute(
          SimpleSelect {
            #bind(Date(timeIntervalSince1970: 0), as: Date.UnixTimeRepresentation.self)
          }
        )
        .first
      )
    }
  }
}

// NB: This is a compile time test for decoding with `decode()` method.
@Table
private struct Row {
  var data = Int(42)
}
