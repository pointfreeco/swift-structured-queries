public protocol DatabaseFunction {
  var name: String { get }
  var argumentCount: Int? { get }
  var isDeterministic: Bool { get }
  func invoke(_ arguments: [QueryBinding]) -> QueryBinding
}
