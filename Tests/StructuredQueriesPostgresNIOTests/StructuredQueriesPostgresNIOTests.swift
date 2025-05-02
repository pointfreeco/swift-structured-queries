import Foundation
import PostgresNIO
import StructuredQueries
import StructuredQueriesPostgresNIO
import Testing

@Suite struct StructuredQueriesPostgresNIOTests {
  @MainActor
  @available(macOS 15.0, *)
  @Test func basics() async throws {
    let client = PostgresClient(
      configuration: PostgresClient.Configuration(
        host: "localhost",
        username: "pointfreeco",
        password: nil,
        database: "pointfreeco_development",
        tls: .disable
      )
    )
    Task {
      await client.run()
    }
    do {
      let query = TeamInvite
        .join(User.all) { $0.inviterUserID.eq($1.id) }
      for try await row in try client.query(query) {
        print(row)
      }
      for try await row in try client.query(User.all) {
        print(row)
      }
      let tmp = try client.query(User.select { ($0.id, $0.name) })
      for try await (id, name) in tmp {
        print(id, name)
      }
    } catch {
      print(String(reflecting: error))
    }
  }
}

@Table
struct User: Identifiable {
  @Column(as: UUID.LowercasedRepresentation.self)
  var id: UUID
  @Column("created_at", as: Date.DateRepresentation.self)
  var createdAt: Date
  @Column("github_user_id")
  var gitHubUserID: Int
  var name = ""
}

@Table("team_invites")
struct TeamInvite {
  @Column(as: UUID.LowercasedRepresentation.self)
  var id: UUID
  @Column("created_at", as: Date.DateRepresentation.self)
  var createdAt: Date
  var email: String
  @Column("inviter_user_id", as: UUID.LowercasedRepresentation.self)
  var inviterUserID: User.ID
}

extension Date {
  public struct DateRepresentation: QueryRepresentable, QueryBindable, QueryDecodable {
    public var queryOutput: Date

    public init(queryOutput: Date) {
      self.queryOutput = queryOutput
    }
    public var queryBinding: QueryBinding {
      //.text(queryOutput.iso8601String)
      fatalError()
    }
    public init(decoder: inout some QueryDecoder) throws {
      guard let value = try decoder.decode(Date.self)
      else {
        throw DecodingError()
      }
      self.init(queryOutput: value)
    }
  }
}

struct DecodingError: Error {}
