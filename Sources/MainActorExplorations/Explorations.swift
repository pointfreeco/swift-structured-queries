import Foundation
import StructuredQueries

@Table
public struct Reminder {
  public let id: UUID
  public var title = ""
  public func foo() {}
}

@concurrent func foo() async {
  let r = Reminder(id: UUID())
  r.foo()
}

@MainActor
class Foo {
  func foo() {}
}

func bar(foo: Foo) {
  foo.foo()
}
