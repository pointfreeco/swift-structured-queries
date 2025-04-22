#if StructuredQueriesTagged
  import Tagged

  extension Tagged: _OptionalPromotable where RawValue: _OptionalPromotable {}

  extension Tagged: QueryBindable where RawValue: QueryBindable {}

  extension Tagged: QueryDecodable where RawValue: QueryDecodable {}

  extension Tagged: QueryExpression where RawValue: QueryExpression {
    public var queryFragment: QueryFragment {
      rawValue.queryFragment
    }
  }

  extension Tagged: QueryRepresentable where RawValue: QueryRepresentable {
    public typealias QueryOutput = Tagged<Tag, RawValue.QueryOutput>

    public var queryOutput: QueryOutput {
      QueryOutput(rawValue: self.rawValue.queryOutput)
    }

    public init(queryOutput: QueryOutput) {
      self.init(rawValue: RawValue(queryOutput: queryOutput.rawValue))
    }
  }

  extension Tagged: SQLiteType where RawValue: SQLiteType {
    public static var typeAffinity: SQLiteTypeAffinity {
      RawValue.typeAffinity
    }
  }
#endif
