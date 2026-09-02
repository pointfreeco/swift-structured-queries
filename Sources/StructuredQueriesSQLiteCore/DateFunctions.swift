public import Foundation
public import StructuredQueriesCore

public protocol _DateTimeModifiable<QueryValue>: QueryExpression
where QueryValue: _SQLiteDateRepresentation {}

extension TableColumn: _DateTimeModifiable where Value: _SQLiteDateRepresentation {}
extension GeneratedColumn: _DateTimeModifiable where Value: _SQLiteDateRepresentation {}
extension SQLQueryExpression: _DateTimeModifiable where QueryValue: _SQLiteDateRepresentation {}
extension AggregateFunctionExpression: _DateTimeModifiable
where QueryValue: _SQLiteDateRepresentation {}
extension CoalesceFunction: _DateTimeModifiable where QueryValue: _SQLiteDateRepresentation {}
extension _ModifiedDate: _DateTimeModifiable {}

extension _DateTimeModifiable {
  /// Modifies this date with a given modifier.
  ///
  /// Don't call this method directly. Swift calls it for you when you call the date expression:
  ///
  /// ```swift
  /// Reminder.where { $0.createdAt > .now(.days(-7)) }
  /// // SELECT … FROM "reminders"
  /// // WHERE (("reminders"."createdAt") > (datetime('now', '-7 days', 'subsec')))
  /// ```
  ///
  /// - Parameter modifier: A modifier to apply.
  /// - Returns: A modified date.
  public func callAsFunction(_ modifier: DateTimeModifier) -> _ModifiedDate<QueryValue> {
    _ModifiedDate(base: timeValueArguments, modifier: modifier)
  }
}

extension QueryExpression where QueryValue: _SQLiteDateRepresentation {
  /// This date formatted according to a format string.
  ///
  /// ```swift
  /// Reminder.select { $0.createdAt.strftime("%Y-%m") }
  /// // SELECT strftime('%Y-%m', "reminders"."createdAt")
  /// // FROM "reminders"
  /// ```
  ///
  /// See [SQLite's documentation](https://sqlite.org/lang_datefunc.html) for the available
  /// substitutions.
  ///
  /// - Parameter format: A format string.
  /// - Returns: An expression of the formatted date.
  public func strftime(_ format: String) -> some QueryExpression<String?> {
    SQLQueryExpression("strftime(\(bind: format), \(timeValueArguments.joined(separator: ", ")))")
  }

  /// The date's year (`%Y`).
  public var year: some QueryExpression<Int> { component("%Y") }

  /// The date's month (`%m`).
  public var month: some QueryExpression<Int> { component("%m") }

  /// The date's day (`%d`).
  public var day: some QueryExpression<Int> { component("%d") }

  /// The date's hour in 24-hour format (`%H`).
  public var hour: some QueryExpression<Int> { component("%H") }

  /// The date's minute (`%M`).
  public var minute: some QueryExpression<Int> { component("%M") }

  /// The date's second (`%S`).
  public var second: some QueryExpression<Int> { component("%S") }

  /// The date's fractional second (`%f`).
  public var fractionalSecond: some QueryExpression<Double> { component("%f") }

  /// The date's day of the week offset (`%w`).
  public var weekday: some QueryExpression<Int> { component("%w") }

  /// The date's day of the year offset (`%j`).
  public var dayOfYear: some QueryExpression<Int> { component("%j") }

  fileprivate var timeValueArguments: [QueryFragment] {
    (self as? any TimeValue)?.timeValueArguments
      ?? [queryFragment] + QueryValue._timeValueModifiers
  }
  private func component<T: Numeric & SQLiteType>(
    _ format: QueryFragment
  ) -> SQLQueryExpression<T> {
    SQLQueryExpression(
      """
      CAST(strftime('\(format)', \(timeValueArguments.joined(separator: ", "))) \
      AS \(T.typeAffinity.rawValue))
      """
    )
  }
}

extension QueryExpression where Self == _ModifiedDate<Date> {
  /// The current date.
  public static var now: Self { Self() }
}

extension QueryExpression where Self == _ModifiedDate<Date.UnixTimeRepresentation> {
  /// The current date.
  public static var now: Self { Self() }
}

extension QueryExpression where Self == _ModifiedDate<Date.JulianDayRepresentation> {
  /// The current date.
  public static var now: Self { Self() }
}

/// A list of modifiers that transform a date in a query expression.
///
/// Modifiers are applied by calling a date expression as a function, and can be chained together
/// using dot syntax:
///
/// ```swift
/// Reminder.select { $0.createdAt(.startOfDay.days(-7)) }
/// // SELECT datetime("reminders"."createdAt", 'start of day', '-7 days', 'subsec')
/// // FROM "reminders"
/// ```
///
/// See [SQLite's documentation](https://sqlite.org/lang_datefunc.html#modifiers) for more
/// information on each modifier.
@dynamicMemberLookup
public struct DateTimeModifier: Sendable {
  var fragments: [QueryFragment] = []

  /// The overflow rule for date time modification.
  public enum Overflow: Sendable {
    /// Choose the later date.
    case ceiling

    /// Choose the last date of the previous cutoff.
    case floor

    fileprivate var fragment: QueryFragment {
      switch self {
      case .ceiling: "'ceiling'"
      case .floor: "'floor'"
      }
    }
  }

  /// Move the time-value by the number of years.
  ///
  /// - Parameter count: The number of years.
  /// - Returns: A modifier that moves the time-value by the given number of years.
  public static func years(_ count: Int) -> Self { Self().years(count) }

  /// Move the time-value by the number of years.
  ///
  /// - Parameters:
  ///   - count: The number of years.
  ///   - overflow: The overflow rule.
  /// - Returns: A modifier that moves the time-value by the given number of years.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public static func years(_ count: Int, _ overflow: Overflow) -> Self {
    Self().years(count, overflow)
  }

  /// Move the time-value by the number of months.
  ///
  /// - Parameter count: The number of months.
  /// - Returns: A modifier that moves the time-value by the given number of months.
  public static func months(_ count: Int) -> Self { Self().months(count) }

  /// Move the time-value by the number of months.
  ///
  /// - Parameters:
  ///   - count: The number of months.
  ///   - overflow: The overflow rule.
  /// - Returns: A modifier that moves the time-value by the given number of months.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public static func months(_ count: Int, _ overflow: Overflow) -> Self {
    Self().months(count, overflow)
  }

  /// Move the time-value by the number of days.
  ///
  /// - Parameter count: The number of days.
  /// - Returns: A modifier that moves the time-value by the given number of days.
  public static func days(_ count: Int) -> Self { Self().days(count) }

  /// Move the time-value by the number of hours.
  ///
  /// - Parameter count: The number of hours.
  /// - Returns: A modifier that moves the time-value by the given number of hours.
  public static func hours(_ count: Int) -> Self { Self().hours(count) }

  /// Move the time-value by the number of minutes.
  ///
  /// - Parameter count: The number of minutes.
  /// - Returns: A modifier that moves the time-value by the given number of minutes.
  public static func minutes(_ count: Int) -> Self { Self().minutes(count) }

  /// Move the time-value by the number of seconds.
  ///
  /// - Parameter count: The number of seconds.
  /// - Returns: A modifier that moves the time-value by the given number of seconds.
  public static func seconds(_ count: Double) -> Self { Self().seconds(count) }

  /// Move the time-value by the number of milliseconds.
  ///
  /// - Parameter count: The number of milliseconds.
  /// - Returns: A modifier that moves the time-value by the given number of milliseconds.
  public static func milliseconds(_ count: Int) -> Self { Self().milliseconds(count) }

  /// Shift the date backwards to the beginning of the day.
  public static var startOfDay: Self { Self().startOfDay }

  /// Shift the date backwards to the beginning of the month.
  public static var startOfMonth: Self { Self().startOfMonth }

  /// Shift the date backwards to the beginning of the year.
  public static var startOfYear: Self { Self().startOfYear }

  /// Advances the time-value to the given day of week offset.
  ///
  /// - Parameter day: The day of week offset.
  /// - Returns: A modifier that advances the time-value to the given day of week offset.
  public static func weekday(_ day: Int) -> Self { Self().weekday(day) }

  /// Move the time-value by the number of years.
  ///
  /// - Parameter count: The number of years.
  /// - Returns: A modifier that moves the time-value by the given number of years.
  public func years(_ count: Int) -> Self { appending("'\(raw: count) years'") }

  /// Move the time-value by the number of years.
  ///
  /// - Parameters:
  ///   - count: The number of years.
  ///   - overflow: The overflow rule.
  /// - Returns: A modifier that moves the time-value by the given number of years.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public func years(_ count: Int, _ overflow: Overflow) -> Self {
    years(count).appending(overflow.fragment)
  }

  /// Move the time-value by the number of months.
  ///
  /// - Parameter count: The number of months.
  /// - Returns: A modifier that moves the time-value by the given number of months.
  public func months(_ count: Int) -> Self { appending("'\(raw: count) months'") }

  /// Move the time-value by the number of months.
  ///
  /// - Parameters:
  ///   - count: The number of months.
  ///   - overflow: The overflow rule.
  /// - Returns: A modifier that moves the time-value by the given number of months.
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public func months(_ count: Int, _ overflow: Overflow) -> Self {
    months(count).appending(overflow.fragment)
  }

  /// Move the time-value by the number of days.
  ///
  /// - Parameter count: The number of days.
  /// - Returns: A modifier that moves the time-value by the given number of days.
  public func days(_ count: Int) -> Self { appending("'\(raw: count) days'") }

  /// Move the time-value by the number of hours.
  ///
  /// - Parameter count: The number of hours.
  /// - Returns: A modifier that moves the time-value by the given number of hours.
  public func hours(_ count: Int) -> Self { appending("'\(raw: count) hours'") }

  /// Move the time-value by the number of minutes.
  ///
  /// - Parameter count: The number of minutes.
  /// - Returns: A modifier that moves the time-value by the given number of minutes.
  public func minutes(_ count: Int) -> Self { appending("'\(raw: count) minutes'") }

  /// Move the time-value by the number of seconds.
  ///
  /// - Parameter count: The number of seconds. Must be finite.
  /// - Returns: A modifier that moves the time-value by the given number of seconds.
  public func seconds(_ count: Double) -> Self {
    precondition(count.isFinite, "Cannot convert a non-finite number of seconds to a modifier")
    return appending("'\(raw: count) seconds'")
  }

  /// Move the time-value by the number of milliseconds.
  ///
  /// - Parameter count: The number of milliseconds.
  /// - Returns: A modifier that moves the time-value by the given number of milliseconds.
  public func milliseconds(_ count: Int) -> Self {
    let sign = count < 0 ? "-" : ""
    let fraction = String(count.magnitude % 1000 + 1000).dropFirst()
    return appending("'\(raw: sign)\(raw: count.magnitude / 1000).\(raw: fraction) seconds'")
  }

  /// Shift the date backwards to the beginning of the day.
  public var startOfDay: Self { appending("'start of day'") }

  /// Shift the date backwards to the beginning of the month.
  public var startOfMonth: Self { appending("'start of month'") }

  /// Shift the date backwards to the beginning of the year.
  public var startOfYear: Self { appending("'start of year'") }

  /// Advances the time-value to the given day of week offset.
  ///
  /// - Parameter day: The day of week offset.
  /// - Returns: A modifier that advances the time-value to the given day of week offset.
  public func weekday(_ day: Int) -> Self { appending("'weekday \(raw: day)'") }

  /// Chains another modifier to this one.
  ///
  /// Don't access this subscript directly. Swift uses it when you chain modifiers together using
  /// dot syntax, _e.g._ `.startOfDay.days(-7)`.
  public subscript(dynamicMember keyPath: KeyPath<Self.Type, Self>) -> Self {
    Self(fragments: fragments + Self.self[keyPath: keyPath].fragments)
  }

  private func appending(_ fragment: QueryFragment) -> Self {
    Self(fragments: fragments + [fragment])
  }
}

public protocol _SQLiteDateRepresentation: QueryRepresentable where QueryOutput == Date {
  static var _timeValueModifiers: [QueryFragment] { get }
  static func _dateStorage(_ arguments: [QueryFragment]) -> QueryFragment
}

private protocol TimeValue {
  var timeValueArguments: [QueryFragment] { get }
}

public struct _ModifiedDate<QueryValue: _SQLiteDateRepresentation>: QueryExpression, TimeValue {
  fileprivate var base: [QueryFragment] = ["'now'"]
  fileprivate var modifier = DateTimeModifier()

  fileprivate var timeValueArguments: [QueryFragment] {
    base + modifier.fragments
  }

  public var queryFragment: QueryFragment {
    QueryValue._dateStorage(timeValueArguments)
  }
}

extension Date: _SQLiteDateRepresentation {
  public static var _timeValueModifiers: [QueryFragment] { [] }
  public static func _dateStorage(_ arguments: [QueryFragment]) -> QueryFragment {
    subsecDateTime(arguments)
  }
}

func subsecDateTime(_ arguments: [QueryFragment] = []) -> QueryFragment {
  #if !SuppressPlatformSQLiteAvailability
    guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else {
      return "strftime(\((["'%Y-%m-%d %H:%M:%f'"] + arguments).joined(separator: ", ")))"
    }
  #endif
  return "datetime(\((arguments + ["'subsec'"]).joined(separator: ", ")))"
}

extension Date.UnixTimeRepresentation: _SQLiteDateRepresentation {
  public static var _timeValueModifiers: [QueryFragment] { ["'unixepoch'"] }
  public static func _dateStorage(_ arguments: [QueryFragment]) -> QueryFragment {
    "unixepoch(\(arguments.joined(separator: ", ")))"
  }
}

extension Date.JulianDayRepresentation: _SQLiteDateRepresentation {
  public static var _timeValueModifiers: [QueryFragment] { [] }
  public static func _dateStorage(_ arguments: [QueryFragment]) -> QueryFragment {
    "julianday(\(arguments.joined(separator: ", ")))"
  }
}
