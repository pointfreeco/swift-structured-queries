import Foundation
import StructuredQueries
import StructuredQueriesSQLite

@Table
private struct MTrip: Codable {
  let id: Int
  var title = ""
  @Column(as: [MCoordinate].JSONRepresentation.self)
  var geofence: [MCoordinate] = []
  @Column(as: [String].JSONRepresentation.self)
  var tags: [String] = []
  @Column(as: [String: MStock].JSONRepresentation.self)
  var inventory: [String: MStock] = [:]
  @Column(as: [String: Int].JSONRepresentation.self)
  var reactions: [String: Int] = [:]
}

@Selection
private struct MCoordinate: Codable {
  var latitude = 0.0
  var label = ""
}

@Selection
private struct MStock: Codable {
  var onHand = 0
}

private enum ArrayOfObjects {
  private func arrayObjectWhere() {
    _ = MTrip.where {
      $0.geofence.jsonEach().where { $0.value.jsonExtract(\.latitude) < 0 }.exists()
    }
  }

  private func arrayObjectSelect() {
    _ = MTrip.select { $0.geofence.jsonEach().select { $0.value.jsonExtract(\.label) } }
  }

  private func arrayObjectAggregate() {
    _ = MTrip.select { $0.geofence.jsonEach().select { $0.value.jsonExtract(\.latitude).max() } }
  }

  private func arrayObjectKey() {
    _ = MTrip.where { $0.geofence.jsonEach().where { $0.key.eq(0) }.exists() }
  }

  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  private func jsonbEachArrayOfObjects() {
    _ = MTrip.where {
      $0.geofence.jsonbEach().where { $0.value.jsonExtract(\.latitude) < 0 }.exists()
    }
  }
}

private enum ArrayOfScalars {
  private func arrayScalarWhere() {
    _ = MTrip.where { $0.tags.jsonEach().where { $0.value.eq("urgent") }.exists() }
  }

  private func arrayScalarJoinTuple() {
    _ =
      MTrip
      .join(MTrip.columns.tags.jsonEach()) { _, _ in true }
      .select { ($0.title, $1.value) }
  }

  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  private func jsonbEachArrayOfScalars() {
    _ = MTrip.where { $0.tags.jsonbEach().where { $0.value.eq("urgent") }.exists() }
  }
}

private enum DictionaryOfObjects {
  private func dictionaryObjectWhere() {
    _ = MTrip.where {
      $0.inventory.jsonEach().where { $0.key.eq("SFO") }.exists()
    }
  }

  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  private func jsonbEachDictionaryOfObjects() {
    _ = MTrip.where { $0.inventory.jsonbEach().where { $0.key.eq("SFO") }.exists() }
  }
}

private enum DictionaryOfScalars {
  private func dictionaryScalarWhere() {
    _ = MTrip.where { $0.reactions.jsonEach().where { $0.value > 10 }.exists() }
  }

  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  private func jsonbEachDictionaryOfScalars() {
    _ = MTrip.where { $0.reactions.jsonbEach().where { $0.value > 10 }.exists() }
  }
}

private enum JoinsAndOptionality {
  private func dictionaryScalarJoinTuple() {
    _ =
      MTrip
      .join(MTrip.columns.reactions.jsonEach()) { _, _ in true }
      .select { ($0.title, $1.key, $1.value) }
  }

  private func arrayObjectJoinTuple() {
    _ =
      MTrip
      .join(MTrip.columns.geofence.jsonEach()) { _, _ in true }
      .select { $1.value.jsonExtract(\.label) }
  }

  private func dictionaryObjectCompoundWhere() {
    _ = MTrip.where {
      $0.inventory.jsonEach()
        .where { $0.key.eq("SFO") && $0.value.jsonExtract(\.onHand).eq(0) }
        .exists()
    }
  }

  private func dictionaryObjectJoinTuple() {
    _ =
      MTrip
      .join(MTrip.columns.inventory.jsonEach()) { _, _ in true }
      .select { ($1.key, $1.value.jsonExtract(\.onHand)) }
  }

  private func arrayObjectOrderAndSelect() {
    _ = MTrip.select {
      $0.geofence.jsonEach()
        .select { $0.value.jsonExtract(\.label) }
        .order { $0.value.jsonExtract(\.latitude).desc() }
        .limit(1)
    }
  }

  private func arrayObjectLeftJoinTuple() {
    _ =
      MTrip
      .leftJoin(MTrip.columns.geofence.jsonEach()) { _, _ in true }
      .select { ($0.title, $1.value.jsonExtract(\.label)) }
  }

  private func arrayObjectLeftJoinSingle() {
    _ =
      MTrip
      .leftJoin(MTrip.columns.geofence.jsonEach()) { _, _ in true }
      .select { $1.value.jsonExtract(\.label) }
  }

  private func dictionaryObjectLeftJoin() {
    _ =
      MTrip
      .leftJoin(MTrip.columns.inventory.jsonEach()) { _, _ in true }
      .select { ($1.key, $1.value.jsonExtract(\.onHand)) }
  }

  private func scalarLeftJoin() {
    _ =
      MTrip
      .leftJoin(MTrip.columns.tags.jsonEach()) { _, _ in true }
      .select { ($0.title, $1.value) }
  }

  private func optionalJSONExtractIsOptional() {
    var required: SQLQueryExpression<_CodableJSONRepresentation<MCoordinate>> { fatalError() }
    var optional: SQLQueryExpression<_CodableJSONRepresentation<MCoordinate>?> { fatalError() }
    let a: any QueryExpression<String> = required.jsonExtract(\.label)
    let b: any QueryExpression<String?> = optional.jsonExtract(\.label)
    _ = (a, b)
  }

  @available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *)
  private func jsonbEachAtPath() {
    _ = MTrip
      .join(MTrip.columns.geofence.jsonbEach()) { _, _ in true }
      .select { ($0.title, $1.value.jsonExtract(\.label)) }
  }
}
