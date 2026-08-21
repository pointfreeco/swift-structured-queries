public import StructuredQueriesCore

extension Collation where Self == NamedCollation {
  /// The `BINARY` collating sequence that compares text based off its underlying bytes.
  public static var binary: Self { Self("BINARY") }

  /// The `NOCASE` collating sequence that compares text after first folding uppercase ASCII
  /// characters into their lowercase equivalent.
  public static var nocase: Self { Self("NOCASE") }

  /// THE `RTRIM` collating sequence that compares text by ignoring trailing whitespace.
  public static var rtrim: Self { Self("RTRIM") }
}
