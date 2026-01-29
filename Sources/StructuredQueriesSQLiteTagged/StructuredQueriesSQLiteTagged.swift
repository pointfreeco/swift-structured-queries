import StructuredQueriesSQLiteCore
import StructuredQueriesTagged
import Tagged

extension Tagged: SQLiteType where RawValue: SQLiteType {
  public static var typeAffinity: SQLiteTypeAffinity {
    RawValue.typeAffinity
  }
}
