import Foundation
import StructuredQueriesCore
public import StructuredQueriesSQLiteCore

#if canImport(Darwin)
  import SQLite3
#else
  import _StructuredQueriesSQLite3
#endif

extension ScalarDatabaseFunction {
  public func install(_ db: OpaquePointer) {
    let body = Unmanaged.passRetained(ScalarDatabaseFunctionDefinition(self)).toOpaque()
    sqlite3_create_function_v2(
      db,
      name,
      Int32(argumentCount ?? -1),
      SQLITE_UTF8 | (isDeterministic ? SQLITE_DETERMINISTIC : 0),
      body,
      { context, argumentCount, arguments in
        do {
          var decoder = SQLiteFunctionDecoder(argumentCount: argumentCount, arguments: arguments)
          try Unmanaged<ScalarDatabaseFunctionDefinition>
            .fromOpaque(sqlite3_user_data(context))
            .takeUnretainedValue()
            .function
            .invoke(&decoder)
            .result(db: context)
        } catch {
          sqlite3_result_error(context, error.localizedDescription, -1)
        }
      },
      nil,
      nil,
      { context in
        guard let context else { return }
        Unmanaged<ScalarDatabaseFunctionDefinition>.fromOpaque(context).release()
      }
    )
  }
}

private final class ScalarDatabaseFunctionDefinition {
  let function: any ScalarDatabaseFunction
  init(_ function: some ScalarDatabaseFunction) {
    self.function = function
  }
}

extension AggregateDatabaseFunction {
  public func install(_ db: OpaquePointer) {
    let body = Unmanaged.passRetained(AggregateDatabaseFunctionDefinition(self)).toOpaque()
    sqlite3_create_function_v2(
      db,
      name,
      Int32(argumentCount ?? -1),
      SQLITE_UTF8 | (isDeterministic ? SQLITE_DETERMINISTIC : 0),
      body,
      nil,
      { context, argumentCount, arguments in
        var decoder = SQLiteFunctionDecoder(argumentCount: argumentCount, arguments: arguments)
        let function = AggregateDatabaseFunctionContext[context].takeUnretainedValue()
        do {
          try function.iterator.step(&decoder)
        } catch {
          sqlite3_result_error(context, error.localizedDescription, -1)
        }
      },
      { context in
        let unmanagedFunction = AggregateDatabaseFunctionContext[context]
        let function = unmanagedFunction.takeUnretainedValue()
        unmanagedFunction.release()
        function.iterator.finish()
        do {
          try function.iterator.result.result(db: context)
        } catch {
          sqlite3_result_error(context, error.localizedDescription, -1)
        }
      },
      { context in
        guard let context else { return }
        Unmanaged<AggregateDatabaseFunctionContext>.fromOpaque(context).release()
      }
    )
  }
}

private final class AggregateDatabaseFunctionDefinition {
  let function: any AggregateDatabaseFunction
  init(_ function: some AggregateDatabaseFunction) {
    self.function = function
  }
}

private final class AggregateDatabaseFunctionContext {
  static subscript(context: OpaquePointer?) -> Unmanaged<AggregateDatabaseFunctionContext> {
    let size = MemoryLayout<Unmanaged<AggregateDatabaseFunctionContext>>.size
    let pointer = sqlite3_aggregate_context(context, Int32(size))!
    if pointer.load(as: Int.self) == 0 {
      let definition = Unmanaged<AggregateDatabaseFunctionDefinition>
        .fromOpaque(sqlite3_user_data(context))
        .takeUnretainedValue()
      let context = AggregateDatabaseFunctionContext(definition.function)
      let unmanagedContext = Unmanaged.passRetained(context)
      pointer
        .assumingMemoryBound(to: Unmanaged<AggregateDatabaseFunctionContext>.self)
        .pointee = unmanagedContext
      return unmanagedContext
    } else {
      return
        pointer
        .assumingMemoryBound(to: Unmanaged<AggregateDatabaseFunctionContext>.self)
        .pointee
    }
  }
  let iterator: any AggregateDatabaseFunctionIteratorProtocol
  init(_ body: some AggregateDatabaseFunction) {
    self.iterator = AggregateDatabaseFunctionIterator(body)
  }
}

private protocol AggregateDatabaseFunctionIteratorProtocol<Body> {
  associatedtype Body: AggregateDatabaseFunction

  var body: Body { get }
  var stream: Stream<Body.Element> { get }
  func start()
  func step(_ decoder: inout some QueryDecoder) throws
  func finish()
  var result: SQLiteValue { get throws }
}

private final class AggregateDatabaseFunctionIterator<
  Body: AggregateDatabaseFunction
>: AggregateDatabaseFunctionIteratorProtocol {
  let body: Body
  let stream = Stream<Body.Element>()
  let queue: DispatchQueue
  var _result: Result<SQLiteValue, any Error>?
  init(_ body: Body) {
    self.body = body
    self.queue = DispatchQueue(
      label: "co.pointfree.StructuredQueriesSQLite.AggregateDatabaseFunction.\(body.name)"
    )
    nonisolated(unsafe) let iterator: any AggregateDatabaseFunctionIteratorProtocol = self
    queue.async {
      iterator.start()
    }
  }
  func start() {
    do {
      _result = .success(try body.invoke(stream))
    } catch {
      _result = .failure(error)
    }
    stream.stopBuffering()
  }
  func step(_ decoder: inout some QueryDecoder) throws {
    try stream.send(body.step(&decoder))
  }
  func finish() {
    stream.finish()
  }
  var result: SQLiteValue {
    get throws {
      try queue.sync { _result! }.get()
    }
  }
}

private final class Stream<Element>: Sequence {
  private static var capacity: Int { 64 }

  let condition = NSCondition()
  private var buffer: [Element] = []
  private var head = 0
  private var isFinished = false
  private var isBuffering = true

  private var count: Int { buffer.count - head }

  func send(_ element: Element) {
    condition.withLock {
      while isBuffering && count >= Self.capacity {
        condition.wait()
      }
      guard isBuffering else { return }
      buffer.append(element)
      condition.broadcast()
    }
  }

  func finish() {
    condition.withLock {
      isFinished = true
      condition.broadcast()
    }
  }

  func stopBuffering() {
    condition.withLock {
      isBuffering = false
      buffer.removeAll()
      head = 0
      condition.broadcast()
    }
  }

  func makeIterator() -> Iterator { Iterator(base: self) }

  struct Iterator: IteratorProtocol {
    fileprivate let base: Stream
    mutating func next() -> Element? {
      base.condition.withLock {
        while base.count == 0 && !base.isFinished {
          base.condition.wait()
        }
        guard base.count > 0 else { return nil }
        let element = base.buffer[base.head]
        base.head += 1
        if base.head >= Stream.capacity {
          base.buffer.removeFirst(base.head)
          base.head = 0
        }
        base.condition.broadcast()
        return element
      }
    }
  }
}

extension SQLiteValue {
  fileprivate func result(db: OpaquePointer?) {
    switch self {
    case .blob(let blob):
      sqlite3_result_blob(db, Array(blob), Int32(blob.count), SQLITE_TRANSIENT)
    case .double(let double):
      sqlite3_result_double(db, double)
    case .int(let int):
      sqlite3_result_int64(db, int)
    case .null:
      sqlite3_result_null(db)
    case .text(let text):
      sqlite3_result_text(db, text, -1, SQLITE_TRANSIENT)
    }
  }
}
