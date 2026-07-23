import StructuredQueries

private struct Scalar: QueryBindable {
  var queryBinding: QueryBinding { .null }
  init() {}
  init(decoder: inout some QueryDecoder) throws { self.init() }
}

private enum IntEnum: Int, QueryBindable { case a, b }
private enum StringEnum: String, QueryBindable { case a, b }

private enum CodableEnum: Int, Codable, QueryBindable { case a, b }

@Table private struct Group {
  var x: Int
  var y: Int
}

@Table private struct CodableGroup: Codable {
  var x: Int
  var y: Int
}

@Table private struct ResolutionMatrix {
  // QB
  var scalar: Scalar

  // QB & C
  var int: Int
  var string: String

  // QB & R
  var intEnum: IntEnum
  var stringEnum: StringEnum

  // QB & R & C
  var codableEnum: CodableEnum

  // QB?
  var optScalar: Scalar?

  // (QB & C)?
  var optInt: Int?
  var optString: String?

  // (QB & R)?
  var optIntEnum: IntEnum?
  var optStringEnum: StringEnum?

  // (QB & R & C)?
  var optCodableEnum: CodableEnum?

  // QR
  var group: Group

  // (QR & C)
  var codableGroup: CodableGroup

  // QR?
  var optGroup: Group?
}

#if Tagged
  import Tagged

  private enum UserIDTag {}

  @Table private struct TaggedMatrix {
    // Q & R & C
    var id: Tagged<UserIDTag, Int>

    // (Q & R & C)?
    var optID: Tagged<UserIDTag, Int>?
  }
#endif
