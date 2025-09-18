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
        """
        struct PlayerAndTeam {
          let player: Player
          let team: Team

          public struct Columns: StructuredQueriesCore._SelectedColumns {
            public typealias QueryValue = PlayerAndTeam
            public let selection: [(aliasName: String, expression: StructuredQueriesCore.QueryFragment)]
            public init(
              player: some StructuredQueriesCore.QueryExpression<Player>,
              team: some StructuredQueriesCore.QueryExpression<Team>
            ) {
              self.selection = [("player", player.queryFragment), ("team", team.queryFragment)]
            }
          }
        }

        extension PlayerAndTeam: StructuredQueriesCore._Selection {
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
        """
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
        """
        struct ReminderTitleAndListTitle {
          var reminderTitle: String 
          var listTitle: String?

          public struct Columns: StructuredQueriesCore._SelectedColumns {
            public typealias QueryValue = ReminderTitleAndListTitle
            public let selection: [(aliasName: String, expression: StructuredQueriesCore.QueryFragment)]
            public init(
              reminderTitle: some StructuredQueriesCore.QueryExpression<String>,
              listTitle: some StructuredQueriesCore.QueryExpression<String?>
            ) {
              self.selection = [("reminderTitle", reminderTitle.queryFragment), ("listTitle", listTitle.queryFragment)]
            }
          }
        }

        extension ReminderTitleAndListTitle: StructuredQueriesCore._Selection {
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
        """
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
        """
        struct ReminderDate {
          var date: Date

          public struct Columns: StructuredQueriesCore._SelectedColumns {
            public typealias QueryValue = ReminderDate
            public let selection: [(aliasName: String, expression: StructuredQueriesCore.QueryFragment)]
            public init(
              date: some StructuredQueriesCore.QueryExpression<Date.UnixTimeRepresentation>
            ) {
              self.selection = [("date", date.queryFragment)]
            }
          }
        }

        extension ReminderDate: StructuredQueriesCore._Selection {
          public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let date = try decoder.decode(Date.UnixTimeRepresentation.self)
            guard let date else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.date = date
          }
        }
        """
      }
    }

    @Test func defaults() {
      assertMacro {
        """
        @Selection struct Row {
          var title = ""
          @Column(as: [String].JSONRepresentation.self)
          var notes: [String] = []
        }
        """
      } expansion: {
        """
        struct Row {
          var title = ""
          var notes: [String] = []

          public struct Columns: StructuredQueriesCore._SelectedColumns {
            public typealias QueryValue = Row
            public let selection: [(aliasName: String, expression: StructuredQueriesCore.QueryFragment)]
            public init(
              title: some StructuredQueriesCore.QueryExpression<Swift.String> = StructuredQueriesCore.BindQueryExpression(""),
              notes: some StructuredQueriesCore.QueryExpression<[String].JSONRepresentation> = StructuredQueriesCore.BindQueryExpression([])
            ) {
              self.selection = [("title", title.queryFragment), ("notes", notes.queryFragment)]
            }
          }
        }

        extension Row: StructuredQueriesCore._Selection {
          public init(decoder: inout some StructuredQueriesCore.QueryDecoder) throws {
            let title = try decoder.decode(Swift.String.self)
            let notes = try decoder.decode([String].JSONRepresentation.self)
            guard let title else {
              throw QueryDecodingError.missingRequiredColumn
            }
            guard let notes else {
              throw QueryDecodingError.missingRequiredColumn
            }
            self.title = title
            self.notes = notes
          }
        }
        """
      }
    }
  }
}
