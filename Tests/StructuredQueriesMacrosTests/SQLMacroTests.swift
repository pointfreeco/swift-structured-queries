import MacroTesting
import StructuredQueriesMacros
import Testing

extension SnapshotTests {
  @MainActor
  @Suite struct SQLMacroTests {
    @Test func basics() {
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP")
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression("CURRENT_TIMESTAMP")
        """
      }
    }

    @Test func unmatchedDelimiters() {
      assertMacro {
        """
        #sql("date('now)")
        """
      } diagnostics: {
        """
        #sql("date('now)")
             ──────┬─────
                   ╰─ ⚠️ Cannot find "'" to match opening "'" in SQL string, producing incomplete fragment; did you mean to make this explicit?
                      ✏️ Use 'SQLQueryExpression.init(_:)' to silence this warning
        """
      } fixes: {
        """
        SQLQueryExpression("date('now)")
        """
      } expansion: {
        """
        SQLQueryExpression("date('now)")
        """
      }
      assertMacro {
        #"""
        #sql("(\($0.id) = \($1.id)")
        """#
      } diagnostics: {
        #"""
        #sql("(\($0.id) = \($1.id)")
             ─┬────────────────────
              ╰─ ⚠️ Cannot find ')' to match opening '(' in SQL string, producing incomplete fragment; did you mean to make this explicit?
                 ✏️ Use 'SQLQueryExpression.init(_:)' to silence this warning
        """#
      } fixes: {
        #"""
        SQLQueryExpression("(\($0.id) = \($1.id)")
        """#
      } expansion: {
        #"""
        SQLQueryExpression("(\($0.id) = \($1.id)")
        """#
      }
    }

    @Test func unmatchedOpenDelimiters() {
      assertMacro {
        """
        #sql("(1 + 2))")
        """
      } diagnostics: {
        """
        #sql("(1 + 2))")
             ────────┬─
                     ╰─ ⚠️ Cannot find '(' to match closing ')' in SQL string, producing incomplete fragment; did you mean to make this explicit?
                        ✏️ Use 'SQLQueryExpression.init(_:)' to silence this warning
        """
      } fixes: {
        """
        SQLQueryExpression("(1 + 2))")
        """
      } expansion: {
        """
        SQLQueryExpression("(1 + 2))")
        """
      }
    }

    @Test func escapedDelimiters() {
      assertMacro {
        """
        #sql("'('")
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression("'('")
        """
      }
      assertMacro {
        """
        #sql("[it's fine]")
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression("[it's fine]")
        """
      }
    }

    @Test func unexpectedBind() {
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = ?")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = ?")
             ─────────────────────┬─
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = ?1")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = ?1")
             ─────────────────────┬──
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = :timestamp")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = :timestamp")
             ─────────────────────┬──────────
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = @timestamp")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = @timestamp")
             ─────────────────────┬──────────
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
      assertMacro {
        """
        #sql("CURRENT_TIMESTAMP = $timestamp")
        """
      } diagnostics: {
        """
        #sql("CURRENT_TIMESTAMP = $timestamp")
             ─────────────────────┬──────────
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
    }

    @Test func escapedBind() {
      assertMacro {
        """
        #sql(#""text" = 'hello?'"#)
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression(#""text" = 'hello?'"#)
        """
      }
      assertMacro {
        """
        #sql(#""text" = 'hello?1'"#)
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression(#""text" = 'hello?1'"#)
        """
      }
      assertMacro {
        """
        #sql(#""text" = 'hello:hi'"#)
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression(#""text" = 'hello:hi'"#)
        """
      }
      assertMacro {
        """
        #sql(#""text" = 'hello@hi'"#)
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression(#""text" = 'hello@hi'"#)
        """
      }
      assertMacro {
        """
        #sql(#""text" = 'hello$hi'"#)
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression(#""text" = 'hello$hi'"#)
        """
      }
    }

    @Test func invalidBind() {
      assertMacro {
        #"""
        #sql("'\(42)'")
        """#
      } diagnostics: {
        #"""
        #sql("'\(42)'")
               ┬────
               ╰─ 🛑 Bind after opening "'" in SQL string, producing invalid fragment; did you mean to make this explicit? To interpolate raw SQL, use '\(raw:)'.
                  ✏️ Insert 'raw: '
        """#
      } fixes: {
        #"""
        #sql("'\(raw: 42)'")
        """#
      } expansion: {
        #"""
        StructuredQueriesCore.SQLQueryExpression("'\(raw: 42)'")
        """#
      }
    }

    @Test func validRawBind() {
      assertMacro {
        #"""
        #sql("'\(raw: 42)'")
        """#
      } expansion: {
        #"""
        StructuredQueriesCore.SQLQueryExpression("'\(raw: 42)'")
        """#
      }
    }

    @Test func complexValidRawBind() {
      assertMacro {
        #"""
        #sql("\($0.dueDate) < date('now', '-\(raw: monthsAgo) months')")
        """#
      } expansion: {
        #"""
        StructuredQueriesCore.SQLQueryExpression("\($0.dueDate) < date('now', '-\(raw: monthsAgo) months')")
        """#
      }
    }

    @Test func emptyDelimiters() {
      assertMacro {
        #"""
        #sql("''")
        """#
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression("''")
        """
      }
      assertMacro {
        #"""
        #sql(
          """
          ""
          """
        )
        """#
      } expansion: {
        #"""
        StructuredQueriesCore.SQLQueryExpression(
          """
          ""
          """)
        """#
      }
      assertMacro {
        #"""
        #sql("[]")
        """#
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression("[]")
        """
      }
    }

    @Test func quotedDelimiters() {
      assertMacro {
        #"""
        #sql(
          """
          SELECT 1 AS "a ""real"" one"
          """
        )
        """#
      } expansion: {
        #"""
        StructuredQueriesCore.SQLQueryExpression(
          """
          SELECT 1 AS "a ""real"" one"
          """)
        """#
      }
    }

    @Test func unclosedQuotedDelimiters() {
      assertMacro {
        #"""
        #sql(
          """
          SELECT 1 AS "a ""real"" one
          """
        )
        """#
      } diagnostics: {
        #"""
        #sql(
          """
          SELECT 1 AS "a ""real"" one
                      ╰─ ⚠️ Cannot find '"' to match opening '"' in SQL string, producing incomplete fragment; did you mean to make this explicit?
                         ✏️ Use 'SQLQueryExpression.init(_:)' to silence this warning
          """
        )
        """#
      } fixes: {
        #"""
        SQLQueryExpression(
          """
          SELECT 1 AS "a ""real"" one
          """)
        """#
      } expansion: {
        #"""
        SQLQueryExpression(
          """
          SELECT 1 AS "a ""real"" one
          """)
        """#
      }
    }

    @Test func dollarSign() {
      assertMacro {
        """
        #sql("json_extract(notes, '$.body')")
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression("json_extract(notes, '$.body')")
        """
      }
    }

    @Test func badDollarSign() {
      assertMacro {
        """
        #sql("json_extract(notes, $.body)")
        """
      } diagnostics: {
        """
        #sql("json_extract(notes, $.body)")
             ─────────────────────┬───────
                                  ╰─ 🛑 Invalid bind parameter in literal; use interpolation to bind values into SQL
        """
      }
    }

    @Test func sqlComments() {
      assertMacro {
        """
        #sql("SELECT 1 -- TODO: Implement logic")
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression("SELECT 1 -- TODO: Implement logic")
        """
      }
      assertMacro {
        """
        #sql("SELECT '1 -- TODO: Implement logic'")
        """
      } expansion: {
        """
        StructuredQueriesCore.SQLQueryExpression("SELECT '1 -- TODO: Implement logic'")
        """
      }
      assertMacro {
        #"""
        #sql(
          """
          SELECT * FROM reminders  -- TODO: We should write columns out by hand
          WHERE isCompleted        -- TODO: Double-check this logic
          """
        )
        """#
      } expansion: {
        #"""
        StructuredQueriesCore.SQLQueryExpression(
          """
          SELECT * FROM reminders  -- TODO: We should write columns out by hand
          WHERE isCompleted        -- TODO: Double-check this logic
          """)
        """#
      }
      assertMacro {
        #"""
        #sql(
          """
          SELECT (  -- TODO: ;-)
            1 = 1
          )
          """
        )
        """#
      } expansion: {
        #"""
        StructuredQueriesCore.SQLQueryExpression(
          """
          SELECT (  -- TODO: ;-)
            1 = 1
          )
          """)
        """#
      }
    }
  }
}
