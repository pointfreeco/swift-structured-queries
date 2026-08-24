import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueries
import StructuredQueriesSQLite
import StructuredQueriesTestSupport
import Testing
import _StructuredQueriesSQLite

@Table private struct Event {
  let id: Int
  @Column(as: Date.UnixTimeRepresentation.self)
  var startsAt: Date
}

@Table private struct Log {
  let id: Int
  var createdAt: Date
}

@Table private struct Deadline {
  let id: Int
  var dueAt: Date
}

@Table private struct Observation {
  let id: Int
  @Column(as: Date.JulianDayRepresentation.self)
  var observedAt: Date
  @Column(as: Date.UnixTimeRepresentation?.self)
  var confirmedAt: Date?
}

extension DateTimeModifier {
  fileprivate static let endOfMonth = Self.startOfMonth.months(1).days(-1)
}

extension SnapshotTests {
  @Suite struct DateFunctionsTests {
    @Dependency(\.defaultDatabase) var db
    init() throws {
      try db.execute(
        """
        CREATE TABLE "events" ("id" INTEGER PRIMARY KEY, "startsAt" INTEGER);
        CREATE TABLE "logs" ("id" INTEGER PRIMARY KEY, "createdAt" TEXT);
        CREATE TABLE "observations" ("id" INTEGER PRIMARY KEY, "observedAt" REAL, "confirmedAt" INTEGER);
        INSERT INTO "events" VALUES (1, 1786579200);
        INSERT INTO "logs" VALUES (1, '2026-08-14 06:59:37.123');
        INSERT INTO "observations" VALUES (1, 2461266.5, NULL);
        CREATE TABLE "deadlines" ("id" INTEGER PRIMARY KEY, "dueAt" TEXT);
        INSERT INTO "deadlines" VALUES (1, '2026-01-31 00:00:00.000');
        """
      )
    }

    @Test func componentsOnUnixColumn() {
      assertQuery(
        Event.select { ($0.startsAt.year, $0.startsAt.month, $0.startsAt.day) }
      ) {
        """
        SELECT CAST(strftime('%Y', "events"."startsAt", 'unixepoch') AS INTEGER), CAST(strftime('%m', "events"."startsAt", 'unixepoch') AS INTEGER), CAST(strftime('%d', "events"."startsAt", 'unixepoch') AS INTEGER)
        FROM "events"
        """
      } results: {
        """
        ┌──────┬───┬────┐
        │ 2026 │ 8 │ 13 │
        └──────┴───┴────┘
        """
      }
    }

    @Test func daysFromNow() {
      assertQuery(
        Event.where { $0.startsAt < .now(.days(7)) }
      ) {
        """
        SELECT "events"."id", "events"."startsAt"
        FROM "events"
        WHERE (("events"."startsAt") < (unixepoch('now', '7 days')))
        """
      } results: {
        """
        ┌────────────────────────────────────────────┐
        │ Event(                                     │
        │   id: 1,                                   │
        │   startsAt: Date(2026-08-13T00:00:00.000Z) │
        │ )                                          │
        └────────────────────────────────────────────┘
        """
      }
    }

    @Test func subsecPreserved() {
      assertQuery(
        Log.select { $0.createdAt(.days(1)) }
      ) {
        """
        SELECT datetime("logs"."createdAt", '1 days', 'subsec')
        FROM "logs"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2026-08-15T06:59:37.123Z) │
        └────────────────────────────────┘
        """
      }
    }

    @Test func startOfMonthOnEveryRepresentation() {
      assertQuery(
        Event.select { $0.startsAt(.startOfMonth) }
      ) {
        """
        SELECT unixepoch("events"."startsAt", 'unixepoch', 'start of month')
        FROM "events"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2026-08-01T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
      assertQuery(
        Log.select { $0.createdAt(.startOfMonth) }
      ) {
        """
        SELECT datetime("logs"."createdAt", 'start of month', 'subsec')
        FROM "logs"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2026-08-01T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
      assertQuery(
        Observation.select { $0.observedAt(.startOfMonth) }
      ) {
        """
        SELECT julianday("observations"."observedAt", 'start of month')
        FROM "observations"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2026-08-01T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
    }

    @Test func optionalColumn() {
      assertQuery(
        Observation.select { ($0.observedAt.year, $0.confirmedAt.map(\.year)) }
      ) {
        """
        SELECT CAST(strftime('%Y', "observations"."observedAt") AS INTEGER), CASE ("observations"."confirmedAt") IS (NULL) WHEN 1 THEN NULL ELSE CAST(strftime('%Y', "observations"."confirmedAt", 'unixepoch') AS INTEGER) END
        FROM "observations"
        """
      } results: {
        """
        ┌──────┬─────┐
        │ 2026 │ nil │
        └──────┴─────┘
        """
      }
      assertQuery(
        Observation.where { $0.confirmedAt.map { $0 > .now(.days(-7)) } }
      ) {
        """
        SELECT "observations"."id", "observations"."observedAt", "observations"."confirmedAt"
        FROM "observations"
        WHERE (CASE ("observations"."confirmedAt") IS (NULL) WHEN 1 THEN NULL ELSE ("observations"."confirmedAt") > (unixepoch('now', '-7 days')) END)
        """
      }
    }

    @Test func customFormat() {
      assertQuery(
        Event.select { $0.startsAt.strftime("%Y-%m-%d %H:%M") }
      ) {
        """
        SELECT strftime('%Y-%m-%d %H:%M', "events"."startsAt", 'unixepoch')
        FROM "events"
        """
      } results: {
        """
        ┌────────────────────┐
        │ "2026-08-13 00:00" │
        └────────────────────┘
        """
      }
    }

    @Test func chainedModifiers() {
      assertQuery(
        Event.select { $0.startsAt(.startOfMonth.months(1).days(-1)) }
      ) {
        """
        SELECT unixepoch("events"."startsAt", 'unixepoch', 'start of month', '1 months', '-1 days')
        FROM "events"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2026-08-31T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
      assertQuery(
        Log.where { $0.createdAt < .now(.endOfMonth) }
      ) {
        """
        SELECT "logs"."id", "logs"."createdAt"
        FROM "logs"
        WHERE (("logs"."createdAt") < (datetime('now', 'start of month', '1 months', '-1 days', 'subsec')))
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Log(                                        │
        │   id: 1,                                    │
        │   createdAt: Date(2026-08-14T06:59:37.123Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Log.where { $0.createdAt < .now(.months(1).endOfMonth) }
      ) {
        """
        SELECT "logs"."id", "logs"."createdAt"
        FROM "logs"
        WHERE (("logs"."createdAt") < (datetime('now', '1 months', 'start of month', '1 months', '-1 days', 'subsec')))
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Log(                                        │
        │   id: 1,                                    │
        │   createdAt: Date(2026-08-14T06:59:37.123Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
    @Test func monthOverflow() {
      assertQuery(
        Deadline.select { ($0.dueAt(.months(1)), $0.dueAt(.months(1, .floor))) }
      ) {
        """
        SELECT datetime("deadlines"."dueAt", '1 months', 'subsec'), datetime("deadlines"."dueAt", '1 months', 'floor', 'subsec')
        FROM "deadlines"
        """
      } results: {
        """
        ┌────────────────────────────────┬────────────────────────────────┐
        │ Date(2026-03-03T00:00:00.000Z) │ Date(2026-02-28T00:00:00.000Z) │
        └────────────────────────────────┴────────────────────────────────┘
        """
      }
    }

    @Test func bareNow() {
      assertQuery(
        Event.where { $0.startsAt < .now }
      ) {
        """
        SELECT "events"."id", "events"."startsAt"
        FROM "events"
        WHERE (("events"."startsAt") < (unixepoch('now')))
        """
      } results: {
        """
        ┌────────────────────────────────────────────┐
        │ Event(                                     │
        │   id: 1,                                   │
        │   startsAt: Date(2026-08-13T00:00:00.000Z) │
        │ )                                          │
        └────────────────────────────────────────────┘
        """
      }
      assertQuery(
        Log.where { $0.createdAt < .now }
      ) {
        """
        SELECT "logs"."id", "logs"."createdAt"
        FROM "logs"
        WHERE (("logs"."createdAt") < (datetime('now', 'subsec')))
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Log(                                        │
        │   id: 1,                                    │
        │   createdAt: Date(2026-08-14T06:59:37.123Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @Test func fusion() {
      assertQuery(
        Event.select { $0.startsAt(.startOfMonth)(.days(1)) }
      ) {
        """
        SELECT unixepoch("events"."startsAt", 'unixepoch', 'start of month', '1 days')
        FROM "events"
        """
      } results: {
        """
        ┌────────────────────────────────┐
        │ Date(2026-08-02T00:00:00.000Z) │
        └────────────────────────────────┘
        """
      }
      assertQuery(
        Event.select { $0.startsAt(.months(-3)).year }
      ) {
        """
        SELECT CAST(strftime('%Y', "events"."startsAt", 'unixepoch', '-3 months') AS INTEGER)
        FROM "events"
        """
      } results: {
        """
        ┌──────┐
        │ 2026 │
        └──────┘
        """
      }
      assertQuery(
        Log.where { $0.createdAt < .now(.days(1))(.startOfDay) }
      ) {
        """
        SELECT "logs"."id", "logs"."createdAt"
        FROM "logs"
        WHERE (("logs"."createdAt") < (datetime('now', '1 days', 'start of day', 'subsec')))
        """
      } results: {
        """
        ┌─────────────────────────────────────────────┐
        │ Log(                                        │
        │   id: 1,                                    │
        │   createdAt: Date(2026-08-14T06:59:37.123Z) │
        │ )                                           │
        └─────────────────────────────────────────────┘
        """
      }
    }

    @Test func milliseconds() {
      assertQuery(
        Log.select { ($0.createdAt(.milliseconds(877)), $0.createdAt(.milliseconds(-1_500))) }
      ) {
        """
        SELECT datetime("logs"."createdAt", '0.877 seconds', 'subsec'), datetime("logs"."createdAt", '-1.500 seconds', 'subsec')
        FROM "logs"
        """
      } results: {
        """
        ┌────────────────────────────────┬────────────────────────────────┐
        │ Date(2026-08-14T06:59:38.000Z) │ Date(2026-08-14T06:59:35.623Z) │
        └────────────────────────────────┴────────────────────────────────┘
        """
      }
    }

    @Test func dayOfYear() {
      assertQuery(
        Event.select(\.startsAt.dayOfYear)
      ) {
        """
        SELECT CAST(strftime('%j', "events"."startsAt", 'unixepoch') AS INTEGER)
        FROM "events"
        """
      } results: {
        """
        ┌─────┐
        │ 225 │
        └─────┘
        """
      }
    }

    @Test func groupByYearMonth() {
      assertQuery(
        Event
          .group(by: { ($0.startsAt.year, $0.startsAt.month) })
          .select { ($0.startsAt.year, $0.startsAt.month, $0.count()) }
      ) {
        """
        SELECT CAST(strftime('%Y', "events"."startsAt", 'unixepoch') AS INTEGER), CAST(strftime('%m', "events"."startsAt", 'unixepoch') AS INTEGER), count("events"."id")
        FROM "events"
        GROUP BY CAST(strftime('%Y', "events"."startsAt", 'unixepoch') AS INTEGER), CAST(strftime('%m', "events"."startsAt", 'unixepoch') AS INTEGER)
        """
      } results: {
        """
        ┌──────┬───┬───┐
        │ 2026 │ 8 │ 1 │
        └──────┴───┴───┘
        """
      }
    }
  }
}
