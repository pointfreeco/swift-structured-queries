public import Foundation
public import StructuredQueriesCore

extension QueryExpression where QueryValue: _SQLiteDateRepresentation {
  public func callAsFunction(_ modifier: DateTimeModifier) -> some QueryExpression<QueryValue> {
    _ModifiedDate(base: timeValueArguments, modifier: modifier)
  }

  public func strftime(_ format: String) -> some QueryExpression<String?> {
    SQLQueryExpression("strftime(\(bind: format), \(timeValueArguments.joined(separator: ", ")))")
  }

  public var year: some QueryExpression<Int> { component("%Y") }
  public var month: some QueryExpression<Int> { component("%m") }
  public var day: some QueryExpression<Int> { component("%d") }
  public var hour: some QueryExpression<Int> { component("%H") }
  public var minute: some QueryExpression<Int> { component("%M") }
  public var second: some QueryExpression<Int> { component("%S") }
  public var weekday: some QueryExpression<Int> { component("%w") }
  public var dayOfYear: some QueryExpression<Int> { component("%j") }

  private var timeValueArguments: [QueryFragment] {
    (self as? any TimeValue)?.timeValueArguments
      ?? [queryFragment] + QueryValue._timeValueModifiers
  }
  private func component(_ format: QueryFragment) -> SQLQueryExpression<Int> {
    SQLQueryExpression(
      "CAST(strftime('\(format)', \(timeValueArguments.joined(separator: ", "))) AS INTEGER)"
    )
  }
}

extension QueryExpression where Self == _ModifiedDate<Date> {
  public static var now: Self { Self() }
}

extension QueryExpression where Self == _ModifiedDate<Date.UnixTimeRepresentation> {
  public static var now: Self { Self() }
}

extension QueryExpression where Self == _ModifiedDate<Date.JulianDayRepresentation> {
  public static var now: Self { Self() }
}

@dynamicMemberLookup
public struct DateTimeModifier: Sendable {
  var fragments: [QueryFragment] = []

  public enum Overflow: Sendable {
    case ceiling
    case floor

    fileprivate var fragment: QueryFragment {
      switch self {
      case .ceiling: "'ceiling'"
      case .floor: "'floor'"
      }
    }
  }

  public static func years(_ count: Int) -> Self { Self().years(count) }
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public static func years(_ count: Int, _ overflow: Overflow) -> Self {
    Self().years(count, overflow)
  }
  public static func months(_ count: Int) -> Self { Self().months(count) }
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public static func months(_ count: Int, _ overflow: Overflow) -> Self {
    Self().months(count, overflow)
  }
  public static func days(_ count: Int) -> Self { Self().days(count) }
  public static func hours(_ count: Int) -> Self { Self().hours(count) }
  public static func minutes(_ count: Int) -> Self { Self().minutes(count) }
  public static func seconds(_ count: Double) -> Self { Self().seconds(count) }
  public static func milliseconds(_ count: Int) -> Self { Self().milliseconds(count) }
  public static var startOfDay: Self { Self().startOfDay }
  public static var startOfMonth: Self { Self().startOfMonth }
  public static var startOfYear: Self { Self().startOfYear }
  public static func weekday(_ day: Int) -> Self { Self().weekday(day) }

  public func years(_ count: Int) -> Self { appending("'\(raw: count) years'") }
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public func years(_ count: Int, _ overflow: Overflow) -> Self {
    years(count).appending(overflow.fragment)
  }
  public func months(_ count: Int) -> Self { appending("'\(raw: count) months'") }
  #if !SuppressPlatformSQLiteAvailability
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
  #endif
  public func months(_ count: Int, _ overflow: Overflow) -> Self {
    months(count).appending(overflow.fragment)
  }
  public func days(_ count: Int) -> Self { appending("'\(raw: count) days'") }
  public func hours(_ count: Int) -> Self { appending("'\(raw: count) hours'") }
  public func minutes(_ count: Int) -> Self { appending("'\(raw: count) minutes'") }
  public func seconds(_ count: Double) -> Self {
    precondition(count.isFinite, "Cannot convert a non-finite number of seconds to a modifier")
    return appending("'\(raw: count) seconds'")
  }
  public func milliseconds(_ count: Int) -> Self {
    let sign = count < 0 ? "-" : ""
    let fraction = String(count.magnitude % 1000 + 1000).dropFirst()
    return appending("'\(raw: sign)\(raw: count.magnitude / 1000).\(raw: fraction) seconds'")
  }
  public var startOfDay: Self { appending("'start of day'") }
  public var startOfMonth: Self { appending("'start of month'") }
  public var startOfYear: Self { appending("'start of year'") }
  public func weekday(_ day: Int) -> Self { appending("'weekday \(raw: day)'") }

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
