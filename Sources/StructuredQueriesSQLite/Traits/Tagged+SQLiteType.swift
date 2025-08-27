#if StructuredQueriesTagged
  import StructuredQueriesCore
  import Tagged

  extension Tagged: SQLiteType where RawValue: SQLiteType {
    public static var typeAffinity: SQLiteTypeAffinity {
      RawValue.typeAffinity
    }
  }
#endif