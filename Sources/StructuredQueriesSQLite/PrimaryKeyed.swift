//
//  File.swift
//  swift-structured-queries
//
//  Created by Coen ten Thije Boonkkamp on 27/08/2025.
//

import Foundation
import StructuredQueries

extension PrimaryKeyedTableDefinition {
  /// A query expression representing the number of rows in this table.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: An expression representing the number of rows in this table.
  public func count(
    distinct isDistinct: Bool = false,
    filter: (some QueryExpression<Bool>)? = nil
  ) -> some QueryExpression<Int> {
    primaryKey.count(distinct: isDistinct, filter: filter)
  }
    
    public func count(
      distinct isDistinct: Bool = false
    ) -> some QueryExpression<Int> {
      primaryKey.count(distinct: isDistinct)
    }
}
