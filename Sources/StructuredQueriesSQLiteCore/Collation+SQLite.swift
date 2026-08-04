public import StructuredQueriesCore

extension Collation where Self == NamedCollation {
  /// The `BINARY` collating sequence that compares text based off its underlying bytes.
  public static var binary: Self { NamedCollation("BINARY") }

  /// The `NOCASE` collating sequence that compares text after first folding uppercase ASCII
  /// characters into their lowercase equivalent.
  public static var nocase: Self { NamedCollation("NOCASE") }

  /// THE `RTRIM` collating sequence that compares text by ignoring trailing whitespace.
  public static var rtrim: Self { NamedCollation("RTRIM") }
}
