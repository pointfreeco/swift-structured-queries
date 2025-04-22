#if TaggedStructuredQueries
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
    public init(queryOutput: RawValue.QueryOutput) {
      self.init(RawValue(queryOutput: queryOutput))
    }

    public var queryOutput: RawValue.QueryOutput {
      rawValue.queryOutput
    }
  }

  extension Tagged: SQLiteType where RawValue: SQLiteType {
    public static var typeAffinity: SQLiteTypeAffinity {
      RawValue.typeAffinity
    }
  }
#endif
