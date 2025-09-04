extension Collation {
  /// The `BINARY` collating sequence that compares text based off its underlying bytes.
  public static let binary = Self(rawValue: "BINARY")

  /// The `NOCASE` collating sequence that compares text after first folding uppercase ASCII
  /// characters into their lowercase equivalent.
  public static let nocase = Self(rawValue: "NOCASE")

  /// THE `RTRIM` collating sequence that compares text by ignoring trailing whitespace.
  public static let rtrim = Self(rawValue: "RTRIM")
}
