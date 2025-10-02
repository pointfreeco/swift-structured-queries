@usableFromInline
struct UInt64OverflowError: Error {
  let signedInteger: Int64

  @usableFromInline
  init(signedInteger: Int64) {
    self.signedInteger = signedInteger
  }
}
