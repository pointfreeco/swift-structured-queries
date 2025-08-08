import Foundation
import StructuredQueries

@Table
struct SyncUp {
  let id: Int
  var seconds: Int = 60 * 5
}

@concurrent func foo() async {
  SyncUp.all
  SyncUp.Draft.all
}
