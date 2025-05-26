import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @Suite struct SelectionMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @Selection
        struct PlayerAndTeam {
          let player: Player
          let team: Team
        }
        """
      } expansion: {
        #"""
        struct PlayerAndTeam {
          let player: Player
          let team: Team
        }

        extension PlayerAndTeam: StructuredQueriesCore.QueryRepresentable {
          public struct Columns: StructuredQueriesCore.QueryExpression {
            public typealias QueryValue = PlayerAndTeam
            public let queryFragment: StructuredQueriesCore.QueryFragment
            public init(
              player: some StructuredQueriesCore.QueryExpression<Player>,
              team: some StructuredQueriesCore.QueryExpression<Team>
            ) {
              self.queryFragment = """
              \(player.queryFragment) AS "player", \(team.queryFragment) AS "team"
              """
            }
          }
          public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let player = try decoder.decode(Player.self)
            let team = try decoder.decode(Team.self)
            guard let player else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let team else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.player = player
            self.team = team
          }
        }
        """#
      }
    }

    @Test func `enum`() {
      assertMacro {
        """
        @Selection
        public enum S {}
        """
      } diagnostics: {
        """
        @Selection
        public enum S {}
               ┬───
               ╰─ 🛑 '@Selection' can only be applied to struct types
        """
      }
    }

    @Test func optionalField() {
      assertMacro {
        """
        @Selection 
        struct ReminderTitleAndListTitle {
          var reminderTitle: String 
          var listTitle: String?
        }
        """
      } expansion: {
        #"""
        struct ReminderTitleAndListTitle {
          var reminderTitle: String 
          var listTitle: String?
        }

        extension ReminderTitleAndListTitle: StructuredQueriesCore.QueryRepresentable {
          public struct Columns: StructuredQueriesCore.QueryExpression {
            public typealias QueryValue = ReminderTitleAndListTitle
            public let queryFragment: StructuredQueriesCore.QueryFragment
            public init(
              reminderTitle: some StructuredQueriesCore.QueryExpression<String>,
              listTitle: some StructuredQueriesCore.QueryExpression<String?>
            ) {
              self.queryFragment = """
              \(reminderTitle.queryFragment) AS "reminderTitle", \(listTitle.queryFragment) AS "listTitle"
              """
            }
          }
          public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let reminderTitle = try decoder.decode(String.self)
            let listTitle = try decoder.decode(String.self)
            guard let reminderTitle else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.reminderTitle = reminderTitle
            self.listTitle = listTitle
          }
        }
        """#
      }
    }

    @Test func date() {
      assertMacro {
        """
        @Selection struct ReminderDate {
          @Column(as: Date.UnixTimeRepresentation.self)
          var date: Date
        }
        """
      } expansion: {
        #"""
        struct ReminderDate {
          var date: Date
        }

        extension ReminderDate: StructuredQueriesCore.QueryRepresentable {
          public struct Columns: StructuredQueriesCore.QueryExpression {
            public typealias QueryValue = ReminderDate
            public let queryFragment: StructuredQueriesCore.QueryFragment
            public init(
              date: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation>
            ) {
              self.queryFragment = """
              \(date.queryFragment) AS "date"
              """
            }
          }
          public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let date = try decoder.decode(Date.UnixTimeRepresentation.self)
            guard let date else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.date = date
          }
        }
        """#
      }
    }
  }
}
